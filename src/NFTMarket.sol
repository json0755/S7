// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BaseERC721.sol"; // 导入NFT合约接口

// NFTMarket 合约，支持用自定义ERC20扩展Token买卖NFT
contract NFTMarket is IERC1363Receiver, IERC721Receiver, Ownable {
    // 事件声明
    // 监听 NFTListed：表示有 NFT 被上架（卖家行为）
    event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    // 监听 NFTBought：表示有 NFT 被买走（买家行为）
    event NFTBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    // 监听白名单购买事件
    event WhitelistBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    // 监听签名者变更事件
    event SignerUpdated(address indexed oldSigner, address indexed newSigner);

    // 记录NFT的上架信息
    struct Listing {
        address seller; // 卖家地址
        address nftAddress; // NFT合约地址
        uint256 tokenId; // NFT的ID
        uint256 price; // 售价（多少个Token）
        bool active; // 是否仍在售卖
    }

    // NFT唯一标识（nft合约+tokenId）到上架信息的映射
    mapping(address => mapping(uint256 => Listing)) public listings;

    address public paymentToken; // 支付用的ERC20扩展Token
    address public signer; // 白名单签名者地址（项目方）
    mapping(bytes32 => bool) public usedSignatures; // 防止签名重放攻击

    /**
     * @dev 构造函数，初始化支付Token和签名者
     * @param tokenAddress 支付Token合约地址
     * @param signerAddress 白名单签名者地址（项目方）
     */
    constructor(address tokenAddress, address signerAddress) Ownable(msg.sender) {
        paymentToken = tokenAddress; // 设置支付Token
        signer = signerAddress; // 设置白名单签名者
    }

    /**
     * @dev 上架NFT，设置价格
     * @param nftAddress NFT合约地址
     * @param tokenId NFT的ID
     * @param price 售价（多少个Token）
     */
    function list(address nftAddress, uint256 tokenId, uint256 price) public {
        require(price > 0, "The price must be greater than 0"); // 价格校验
        BaseERC721 nft = BaseERC721(nftAddress); // 实例化NFT合约
        require(nft.ownerOf(tokenId) == msg.sender, "You are not an NFT holder"); // 必须是持有者
        require(
            nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)),
            "The contract is not authorized to transfer the NFT"
        ); // 合约必须有转移权限
        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            active: true
        }); // 记录上架信息
        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    /**
     * @dev 购买NFT，支付Token获得NFT
     * @param nftAddress NFT合约地址
     * @param tokenId NFT的ID
     */
    function buyNFT(address nftAddress, uint256 tokenId) public {
        Listing storage item = listings[nftAddress][tokenId]; // 获取上架信息
        require(item.active, "NFT not available"); // 必须已上架
        require(item.seller != address(0), "Invalid seller");
        
        // 使用 IERC20 接口进行 Token 操作
        IERC20 token = IERC20(paymentToken);
        require(token.allowance(msg.sender, address(this)) >= item.price, "Token authorization is insufficient"); // 检查授权
        require(token.balanceOf(msg.sender) >= item.price, "Token balance is insufficient"); // 检查余额
        // 转账Token给卖家
        require(token.transferFrom(msg.sender, item.seller, item.price), "Token transfer failed");
        // 转移NFT给买家
        BaseERC721 nft = BaseERC721(nftAddress);
        nft.transferFrom(item.seller, msg.sender, tokenId);
        item.active = false; // 标记为已售出
        emit NFTBought(msg.sender, nftAddress, tokenId, item.price);
    }

    /**
     * @dev ERC1363Receiver 接口实现，支持带data的转账购买NFT
     * @param operator 操作者地址
     * @param from 付款人
     * @param value 支付的Token数量
     * @param data 附加数据，需包含NFT合约地址和tokenId
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == paymentToken, "Only callbacks for specified tokens are accepted"); // 只允许指定Token回调
        
        // 使用 ABI 解码 data 参数，更安全且易于理解
        (address nftAddress, uint256 tokenId) = abi.decode(data, (address, uint256));
        
        Listing storage item = listings[nftAddress][tokenId]; // 获取上架信息
        require(item.active, "NFT not available");
        require(item.price == value, "Payment amount does not match");
        
        // 转账Token给卖家
        IERC20 token = IERC20(paymentToken);
        require(token.transfer(item.seller, value), "Token transfer failed");
        
        // 转移NFT给买家
        BaseERC721 nft = BaseERC721(nftAddress);
        nft.transferFrom(item.seller, from, tokenId);
        item.active = false; // 标记为已售出

        return this.onTransferReceived.selector; // 返回接口选择器
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
    * @dev 下架NFT（只能由卖家本人操作）
    * @param nftAddress NFT合约地址
    * @param tokenId NFT的ID
    */
    function unlist(address nftAddress, uint256 tokenId) public {
        Listing storage item = listings[nftAddress][tokenId];
        require(item.active, "NFT is not listed");
        require(item.seller == msg.sender, "Only seller can unlist");
        item.active = false;
    }

    /**
     * @dev 白名单购买NFT，需要项目方的签名授权
     * @param nftAddress NFT合约地址
     * @param tokenId NFT的ID
     * @param nonce 防重放随机数
     * @param signature 项目方的签名
     */
    function permitBuy(
        address nftAddress, 
        uint256 tokenId, 
        uint256 nonce,
        bytes calldata signature
    ) public {
        // 构造消息哈希
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,      // 购买者地址
            nftAddress,      // NFT合约地址
            tokenId,         // NFT ID
            nonce            // 防重放随机数
        ));
        
        // 防止签名重放攻击
        require(!usedSignatures[messageHash], "Signature already used");
        usedSignatures[messageHash] = true;
        
        // 验证签名
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        address recoveredSigner = ECDSA.recover(ethSignedMessageHash, signature);
        require(recoveredSigner == signer, "Invalid signature or not whitelisted");
        
        // 执行购买逻辑（复用buyNFT的逻辑）
        Listing storage item = listings[nftAddress][tokenId];
        require(item.active, "NFT not available");
        require(item.seller != address(0), "Invalid seller");
        
        // 使用 IERC20 接口进行 Token 操作
        IERC20 token = IERC20(paymentToken);
        require(token.allowance(msg.sender, address(this)) >= item.price, "Token authorization is insufficient");
        require(token.balanceOf(msg.sender) >= item.price, "Token balance is insufficient");
        
        // 转账Token给卖家
        require(token.transferFrom(msg.sender, item.seller, item.price), "Token transfer failed");
        
        // 转移NFT给买家
        BaseERC721 nft = BaseERC721(nftAddress);
        nft.transferFrom(item.seller, msg.sender, tokenId);
        
        item.active = false; // 标记为已售出
        
        emit WhitelistBought(msg.sender, nftAddress, tokenId, item.price);
    }

    /**
     * @dev 更新签名者地址（只有合约拥有者可以调用）
     * @param newSigner 新的签名者地址
     */
    function updateSigner(address newSigner) public onlyOwner {
        require(newSigner != address(0), "Invalid signer address");
        address oldSigner = signer;
        signer = newSigner;
        emit SignerUpdated(oldSigner, newSigner);
    }

    /**
     * @dev 获取签名消息哈希（用于前端生成签名）
     * @param buyer 购买者地址
     * @param nftAddress NFT合约地址
     * @param tokenId NFT ID
     * @param nonce 防重放随机数
     * @return 消息哈希
     */
    function getMessageHash(
        address buyer,
        address nftAddress,
        uint256 tokenId,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(buyer, nftAddress, tokenId, nonce));
    }

} 