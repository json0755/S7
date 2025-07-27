// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTMarket.sol";
import "../src/BaseERC721.sol";
import "../src/BaseERC20.sol";

contract NFTMarketWhitelistTest is Test {
    NFTMarket public market;
    BaseERC721 public nft;
    BaseERC20 public token;
    
    address public owner = address(1);
    address public seller = address(3);
    address public buyer = address(4);
    address public nonWhitelistBuyer = address(5);
    
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant PRICE = 100 * 10**18; // 100 tokens
    uint256 public constant INITIAL_BALANCE = 1000 * 10**18;
    
    // 签名者私钥（仅用于测试）
    uint256 public constant SIGNER_PRIVATE_KEY = 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef;
    address public signer; // 从私钥派生的签名者地址
    
    function setUp() public {
        // 从私钥派生签名者地址
        signer = vm.addr(SIGNER_PRIVATE_KEY);
        
        vm.startPrank(owner);
        
        // 部署 ERC20 Token
        token = new BaseERC20(INITIAL_BALANCE * 10);
        
        // 部署 NFT 合约
        nft = new BaseERC721("Test NFT", "TNFT", "https://test.com/");
        
        // 部署 NFTMarket 合约
        market = new NFTMarket(address(token), signer);
        
        vm.stopPrank();
        
        // 给卖家铸造 NFT
        vm.prank(owner);
        nft.mint(seller, TOKEN_ID);
        
        // 给买家分发代币
        vm.prank(owner);
        token.transfer(buyer, INITIAL_BALANCE);
        
        vm.prank(owner);
        token.transfer(nonWhitelistBuyer, INITIAL_BALANCE);
        
        // 卖家上架 NFT
        vm.startPrank(seller);
        nft.approve(address(market), TOKEN_ID);
        market.list(address(nft), TOKEN_ID, PRICE);
        vm.stopPrank();
    }
    
    function testPermitBuyWithValidSignature() public {
        uint256 nonce = 12345;
        
        // 生成签名
        bytes32 messageHash = market.getMessageHash(buyer, address(nft), TOKEN_ID, nonce);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 买家授权市场合约
        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        
        // 记录初始余额
        uint256 buyerInitialBalance = token.balanceOf(buyer);
        uint256 sellerInitialBalance = token.balanceOf(seller);
        
        // 执行白名单购买
        market.permitBuy(address(nft), TOKEN_ID, nonce, signature);
        
        // 验证结果
        assertEq(nft.ownerOf(TOKEN_ID), buyer, "NFT should be transferred to buyer");
        assertEq(token.balanceOf(buyer), buyerInitialBalance - PRICE, "Buyer should pay the price");
        assertEq(token.balanceOf(seller), sellerInitialBalance + PRICE, "Seller should receive payment");
        
        // 验证 NFT 已下架
        (,,,,bool active) = market.listings(address(nft), TOKEN_ID);
        assertFalse(active, "NFT should be delisted");
        
        vm.stopPrank();
    }
    
    function testPermitBuyWithInvalidSignature() public {
        uint256 nonce = 12345;
        uint256 wrongPrivateKey = 0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba;
        
        // 使用错误的私钥生成签名
        bytes32 messageHash = market.getMessageHash(buyer, address(nft), TOKEN_ID, nonce);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        vm.startPrank(buyer);
        token.approve(address(market), PRICE);
        
        // 应该失败
        vm.expectRevert("Invalid signature or not whitelisted");
        market.permitBuy(address(nft), TOKEN_ID, nonce, signature);
        
        vm.stopPrank();
    }
    
    function testPermitBuySignatureReplay() public {
        uint256 nonce = 12345;
        
        // 生成签名
        bytes32 messageHash = market.getMessageHash(buyer, address(nft), TOKEN_ID, nonce);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        vm.startPrank(buyer);
        token.approve(address(market), PRICE * 2); // 授权两次购买的金额
        
        // 第一次购买应该成功
        market.permitBuy(address(nft), TOKEN_ID, nonce, signature);
        
        vm.stopPrank();
        
        // 铸造新的 NFT 并由买家重新上架（因为原来的 NFT 已经属于买家了）
        uint256 newTokenId = TOKEN_ID + 1;
        vm.prank(owner);
        nft.mint(buyer, newTokenId);
        
        vm.startPrank(buyer);
        nft.approve(address(market), newTokenId);
        market.list(address(nft), newTokenId, PRICE);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        
        // 第二次使用相同签名应该失败（即使是不同的 NFT）
        vm.expectRevert("Signature already used");
        market.permitBuy(address(nft), TOKEN_ID, nonce, signature);
        
        vm.stopPrank();
    }
    
    function testPermitBuyWrongBuyer() public {
        uint256 nonce = 12345;
        
        // 为 buyer 生成签名
        bytes32 messageHash = market.getMessageHash(buyer, address(nft), TOKEN_ID, nonce);
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNER_PRIVATE_KEY, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 但是 nonWhitelistBuyer 来使用这个签名
        vm.startPrank(nonWhitelistBuyer);
        token.approve(address(market), PRICE);
        
        vm.expectRevert("Invalid signature or not whitelisted");
        market.permitBuy(address(nft), TOKEN_ID, nonce, signature);
        
        vm.stopPrank();
    }
    
    function testUpdateSigner() public {
        address newSigner = address(6);
        
        // 只有合约拥有者可以更新签名者
        vm.prank(owner);
        market.updateSigner(newSigner);
        
        assertEq(market.signer(), newSigner, "Signer should be updated");
        
        // 非拥有者不能更新
        vm.prank(buyer);
        vm.expectRevert();
        market.updateSigner(address(7));
    }
    
    function testGetMessageHash() public {
        uint256 nonce = 12345;
        bytes32 expectedHash = keccak256(abi.encodePacked(buyer, address(nft), TOKEN_ID, nonce));
        bytes32 actualHash = market.getMessageHash(buyer, address(nft), TOKEN_ID, nonce);
        
        assertEq(actualHash, expectedHash, "Message hash should match expected value");
    }
} 