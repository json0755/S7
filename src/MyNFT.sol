// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定Solidity编译器版本

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../src/BaseERC721.sol";
import "../src/BaseERC20.sol";
import "../src/NFTMarket.sol";
import "../src/MyNFT.sol";

// MyNFT 合约，继承自ERC721URIStorage，实现NFT的铸造和URI存储
contract MyNFT is ERC721URIStorage {
    uint256 public tokenCounter; // 记录已铸造NFT的数量

    /**
     * @dev 构造函数，初始化NFT名称和符号，并将tokenCounter设为0
     */
    constructor() ERC721("MyNFT", "MNFT") {
        tokenCounter = 0; // 初始化计数器
    }

    /**
     * @dev 铸造新的NFT
     * @param to 接收NFT的地址
     * @param tokenURI NFT的元数据URI
     * @return 新NFT的tokenId
     */
    function mintNFT(address to, string memory tokenURI) public returns (uint256) {
        uint256 newTokenId = tokenCounter; // 新NFT的ID
        _safeMint(to, newTokenId); // 安全铸造NFT
        _setTokenURI(newTokenId, tokenURI); // 设置NFT的元数据URI
        tokenCounter += 1; // 计数器加1
        return newTokenId; // 返回新NFT的ID
    }
}