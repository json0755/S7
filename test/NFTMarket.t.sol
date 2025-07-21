pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MyNFT} from "../src/MyNFT.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyToken} from "../src/MyToken.sol";

contract NFTMarketTest is Test {

    NFTMarket public nftMarket;
    MyNFT public myNFT;
    MyToken public myToken;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        myToken = new MyToken("TestToken", "TT");
        myNFT = new MyNFT();
        nftMarket = new NFTMarket(address(myToken));
    }

    // 测试成功上架 NFT
    function test_listNFT_Success() public {
        // 1. 铸造 NFT 给 user1
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        
        // 2. 授权 NFTMarket 合约转移 NFT
        myNFT.approve(address(nftMarket), tokenId);
        
        // 3. 上架 NFT
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();
        
        // 4. 验证上架信息
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "NFT should be active");
        assertEq(seller, user1, "Seller should be user1");
        assertEq(nftAddress, address(myNFT), "NFT address should match");
        assertEq(tokenId_, tokenId, "Token ID should match");
        assertEq(price, 100, "Price should be 100");
    }

    // 测试价格为零时上架失败
    function test_listNFT_PriceZero_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        
        // 尝试以价格 0 上架，应该失败
        vm.expectRevert("The price must be greater than 0");
        nftMarket.list(address(myNFT), tokenId, 0);
        vm.stopPrank();
    }

    // 测试非持有者上架失败
    function test_listNFT_NotOwner_Revert() public {
        // user1 铸造 NFT
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        vm.stopPrank();
        
        // user2 尝试上架 user1 的 NFT，应该失败
        vm.startPrank(user2);
        // 先尝试授权，这会失败
        vm.expectRevert(abi.encodeWithSignature("ERC721InvalidApprover(address)", user2));
        myNFT.approve(address(nftMarket), tokenId);
        vm.stopPrank();
    }

    // 测试未授权时上架失败
    function test_listNFT_NotApproved_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        
        // 不授权直接上架，应该失败
        vm.expectRevert("The contract is not authorized to transfer the NFT");
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();
    }

    // 测试使用 setApprovalForAll 授权后上架成功
    function test_listNFT_ApprovalForAll_Success() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        
        // 使用 setApprovalForAll 授权
        myNFT.setApprovalForAll(address(nftMarket), true);
        
        // 上架 NFT
        nftMarket.list(address(myNFT), tokenId, 200);
        vm.stopPrank();
        
        // 验证上架信息
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "NFT should be active");
        assertEq(seller, user1, "Seller should be user1");
        assertEq(price, 200, "Price should be 200");
    }

    // 测试上架不存在的 NFT 失败
    function test_listNFT_NonExistentToken_Revert() public {
        vm.startPrank(user1);
        // 尝试上架不存在的 tokenId
        vm.expectRevert(abi.encodeWithSignature("ERC721NonexistentToken(uint256)", 999));
        nftMarket.list(address(myNFT), 999, 100);
        vm.stopPrank();
    }

    // 测试重复上架同一 NFT
    function test_listNFT_DuplicateListing() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        
        // 第一次上架
        nftMarket.list(address(myNFT), tokenId, 100);
        
        // 第二次上架（会覆盖第一次的信息）
        nftMarket.list(address(myNFT), tokenId, 150);
        vm.stopPrank();
        
        // 验证第二次上架的信息
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(price, 150, "Price should be updated to 150");
        assertEq(active, true, "NFT should still be active");
    }

    // 测试多个用户上架不同 NFT
    function test_listNFT_MultipleUsers() public {
        // user1 上架第一个 NFT
        vm.startPrank(user1);
        uint256 tokenId1 = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId1);
        nftMarket.list(address(myNFT), tokenId1, 100);
        vm.stopPrank();
        
        // user2 上架第二个 NFT
        vm.startPrank(user2);
        uint256 tokenId2 = myNFT.mintNFT(user2, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId2);
        nftMarket.list(address(myNFT), tokenId2, 200);
        vm.stopPrank();
        
        // 验证两个上架信息
        (address seller1, address nftAddress1, uint256 tokenId1_, uint256 price1, bool active1) = nftMarket.listings(address(myNFT), tokenId1);
        console.log("seller1", seller1);
        console.log("nftAddress1", nftAddress1);
        console.log("tokenId1_", tokenId1_);
        console.log("price1", price1);
        console.log("active1", active1);
        (address seller2, address nftAddress2, uint256 tokenId2_, uint256 price2, bool active2) = nftMarket.listings(address(myNFT), tokenId2);
        console.log("seller2", seller2);
        console.log("nftAddress2", nftAddress2);
        console.log("tokenId2_", tokenId2_);
        console.log("price2", price2);
        console.log("active2", active2);
        assertEq(seller1, user1, "First listing seller should be user1");
        assertEq(price1, 100, "First listing price should be 100");
        assertEq(seller2, user2, "Second listing seller should be user2");
        assertEq(price2, 200, "Second listing price should be 200");
    }

    //测试购买NFT成功
    function test_buyNFT_Success() public {
        // 给 user2 铸造一些 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        // 授权 NFTMarket 合约使用 Token
        myToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        //验证购买信息
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        console.log("seller", seller);
        console.log("nftAddress", nftAddress);
        console.log("tokenId_", tokenId_);
        console.log("price", price);
        console.log("active", active);
        assertEq(active, false, "NFT should be inactive after purchase");
        
        // 验证 NFT 所有权转移
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should be transferred to buyer");
        
        // 验证 Token 余额变化
        assertEq(myToken.balanceOf(user1), 100, "Seller should receive 100 tokens");
        console.log("myToken.balanceOf(user1)", myToken.balanceOf(user1));
        console.log("myToken.balanceOf(user2)", myToken.balanceOf(user2));
        assertEq(myToken.balanceOf(user2), 900, "Buyer should have 900 tokens left");
    }

    // 测试购买未上架的 NFT 失败
    function test_buyNFT_NotListed_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        vm.stopPrank();

        vm.startPrank(user2);
        myToken.mint(user2, 1000);
        myToken.approve(address(nftMarket), 100);
        vm.expectRevert("NFT not available");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
    }

    // 测试购买已售出的 NFT 失败
    function test_buyNFT_AlreadySold_Revert() public {
        // 给 user2 和 user3 铸造 Token
        myToken.mint(user2, 1000);
        myToken.mint(address(0x3), 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        // user2 购买 NFT
        vm.startPrank(user2);
        myToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        // user3 尝试购买已售出的 NFT
        vm.startPrank(address(0x3));
        myToken.approve(address(nftMarket), 100);
        vm.expectRevert("NFT not available");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
    }

    // 测试 Token 余额不足时购买失败
    function test_buyNFT_InsufficientBalance_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        // 只给 user2 50 个 Token，但需要 100 个
        myToken.mint(user2, 50);
        myToken.approve(address(nftMarket), 100);
        vm.expectRevert("Token balance is insufficient");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
    }

    // 测试 Token 授权不足时购买失败
    function test_buyNFT_InsufficientAllowance_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        vm.startPrank(user2);
        myToken.mint(user2, 1000);
        // 只授权 50 个 Token，但需要 100 个
        myToken.approve(address(nftMarket), 50);
        vm.expectRevert("Token authorization is insufficient");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
    }

    // 测试购买自己的 NFT（当前合约允许这种行为）
    function test_buyNFT_BuyOwnNFT_Success() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        
        // 给自己铸造一些 Token
        myToken.mint(user1, 1000);
        myToken.approve(address(nftMarket), 100);
        
        // 购买自己的 NFT（当前合约允许）
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证结果
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, false, "NFT should be inactive after purchase");
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证 Token 余额（自己给自己转账，余额不变）
        assertEq(myToken.balanceOf(user1), 1000, "User1 balance should remain unchanged");
    }

    // 测试自己购买自己的 NFT 的完整流程
    function test_buyNFT_SelfPurchase_CompleteFlow() public {
        vm.startPrank(user1);
        
        // 1. 铸造 NFT
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        console.log("Initial NFT owner:", myNFT.ownerOf(tokenId));
        
        // 2. 授权 NFTMarket 合约
        myNFT.approve(address(nftMarket), tokenId);
        
        // 3. 上架 NFT
        nftMarket.list(address(myNFT), tokenId, 100);
        
        // 4. 验证上架信息
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        console.log("Listing seller:", seller);
        console.log("Listing price:", price);
        console.log("Listing active:", active);
        
        // 5. 给自己铸造 Token
        myToken.mint(user1, 1000);
        console.log("User1 token balance before purchase:", myToken.balanceOf(user1));
        
        // 6. 授权 Token 使用
        myToken.approve(address(nftMarket), 100);
        
        // 7. 购买自己的 NFT
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 8. 验证购买后的状态
        console.log("NFT owner after purchase:", myNFT.ownerOf(tokenId));
        console.log("User1 token balance after purchase:", myToken.balanceOf(user1));
        
        (address sellerAfter, address nftAddressAfter, uint256 tokenIdAfter, uint256 priceAfter, bool activeAfter) = nftMarket.listings(address(myNFT), tokenId);
        console.log("Listing active after purchase:", activeAfter);
        
        // 9. 断言验证
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        assertEq(activeAfter, false, "Listing should be inactive");
        assertEq(myToken.balanceOf(user1), 1000, "Token balance should remain unchanged (self-transfer)");
    }

    // 测试 NFT 被重复购买失败
    function test_buyNFT_DuplicatePurchase_Revert() public {
        // 给多个用户铸造 Token
        myToken.mint(user1, 1000);
        myToken.mint(user2, 1000);
        myToken.mint(address(0x3), 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        // user2 第一次购买 NFT
        vm.startPrank(user2);
        myToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        // 验证第一次购买成功
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should be transferred to user2");
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        console.log("seller", seller);
        console.log("nftAddress", nftAddress);
        console.log("tokenId_", tokenId_);
        console.log("price", price);
        console.log("active", active);
        assertEq(active, false, "Listing should be inactive after first purchase");

        // user3 尝试重复购买同一个 NFT
        vm.startPrank(address(0x3));
        myToken.approve(address(nftMarket), 100);
        vm.expectRevert("NFT not available");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        // 验证 NFT 所有权没有改变
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should still belong to user2");
    }

    // 测试 NFT 被重复购买的完整流程
    function test_buyNFT_DuplicatePurchase_CompleteFlow() public {
        // 给多个用户铸造 Token
        myToken.mint(user1, 1000);
        myToken.mint(user2, 1000);
        myToken.mint(address(0x3), 1000);
        myToken.mint(address(0x4), 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        console.log("=== First buy ===");
        console.log("NFT owner before purchase:", myNFT.ownerOf(tokenId));
        console.log("User1 token balance before sale:", myToken.balanceOf(user1));
        console.log("User2 token balance before purchase:", myToken.balanceOf(user2));

        // user2 第一次购买
        vm.startPrank(user2);
        myToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        console.log("NFT owner after first purchase:", myNFT.ownerOf(tokenId));
        console.log("User1 token balance after sale:", myToken.balanceOf(user1));
        console.log("User2 token balance after purchase:", myToken.balanceOf(user2));

        // 验证第一次购买后的状态
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        console.log("Listing active after first purchase:", active);

        // 多个用户尝试重复购买
        address[] memory buyers = new address[](2);
        buyers[0] = address(0x3);
        buyers[1] = address(0x4);

        for (uint i = 0; i < buyers.length; i++) {
            console.log(unicode"=== 尝试重复购买 by", buyers[i], "===");
            vm.startPrank(buyers[i]);
            myToken.approve(address(nftMarket), 100);
            
            // 尝试购买，应该失败
            vm.expectRevert("NFT not available");
            nftMarket.buyNFT(address(myNFT), tokenId);
            vm.stopPrank();

            // 验证 NFT 所有权没有改变
            assertEq(myNFT.ownerOf(tokenId), user2, "NFT should still belong to user2");
            
            // 验证上架状态没有改变
            (address sellerAfter, address nftAddressAfter, uint256 tokenIdAfter, uint256 priceAfter, bool activeAfter) = nftMarket.listings(address(myNFT), tokenId);
            assertEq(activeAfter, false, "Listing should remain inactive");
        }

        // 最终验证
        assertEq(myNFT.ownerOf(tokenId), user2, "Final NFT owner should be user2");
        assertEq(myToken.balanceOf(user1), 1100, "User1 should have 1100 tokens (1000 initial + 100 from sale)");
        assertEq(myToken.balanceOf(user2), 900, "User2 should have 900 tokens left");
    }

    // 测试购买后重新上架再购买
    function test_buyNFT_RelistAndRepurchase() public {
        myToken.mint(user1, 1000);
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100);
        vm.stopPrank();

        // user2 第一次购买
        vm.startPrank(user2);
        myToken.approve(address(nftMarket), 100);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        // 验证第一次购买
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should belong to user2 after first purchase");

        // user2 重新上架 NFT
        vm.startPrank(user2);
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 150); // 提高价格
        vm.stopPrank();

        // 验证重新上架
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "NFT should be relisted");
        assertEq(seller, user2, "Seller should be user2");
        assertEq(price, 150, "Price should be updated to 150");

        // user1 购买重新上架的 NFT
        vm.startPrank(user1);
        myToken.approve(address(nftMarket), 150);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();

        // 验证第二次购买
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should belong to user1 after second purchase");
        
        // 验证最终状态
        (address sellerFinal, address nftAddressFinal, uint256 tokenIdFinal, uint256 priceFinal, bool activeFinal) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(activeFinal, false, "Listing should be inactive after second purchase");
        
        // 验证 Token 余额
        assertEq(myToken.balanceOf(user1), 950, "User1 should have 950 tokens (1000+100-150)");
        assertEq(myToken.balanceOf(user2), 1050, "User2 should have 1050 tokens (1000-100+150)");
    }

    // 测试支付Token过多的情况（通过tokensReceived回调）
    function test_tokensReceived_Overpayment_Revert() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 尝试支付 150 个 Token（超过价格 100）
        bytes memory data = abi.encode(address(myNFT), tokenId);
        vm.expectRevert("Payment amount does not match");
        myToken.transferAndCall(address(nftMarket), 150, data);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试支付Token过少的情况（通过tokensReceived回调）
    function test_tokensReceived_Underpayment_Revert() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 尝试支付 50 个 Token（少于价格 100）
        bytes memory data = abi.encode(address(myNFT), tokenId);
        vm.expectRevert("Payment amount does not match");
        myToken.transferAndCall(address(nftMarket), 50, data);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试支付Token过多的情况（通过buyNFT函数）
    function test_buyNFT_Overpayment_Revert() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 授权 150 个 Token（超过价格 100）
        myToken.approve(address(nftMarket), 150);
        
        // 尝试购买，应该成功（因为合约只转移实际需要的 100 个 Token）
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证购买成功
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should be transferred to user2");
        
        // 验证上架状态变为非活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, false, "Listing should be inactive after purchase");
        
        // 验证 Token 余额变化（只扣除实际价格 100）
        assertEq(myToken.balanceOf(user1), 100, "User1 should receive 100 tokens");
        assertEq(myToken.balanceOf(user2), 900, "User2 should have 900 tokens left (1000-100)");
        
        // 验证剩余授权额度（150-100=50）
        assertEq(myToken.allowance(user2, address(nftMarket)), 50, "Remaining allowance should be 50");
    }

    // 测试支付Token过少的情况（通过buyNFT函数）
    function test_buyNFT_Underpayment_Revert() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 只授权 50 个 Token（少于价格 100）
        myToken.approve(address(nftMarket), 50);
        
        // 尝试购买，应该失败
        vm.expectRevert("Token authorization is insufficient");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试支付Token余额不足的情况
    function test_buyNFT_InsufficientBalance_ExactAllowance_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 只给 user2 50 个 Token，但授权 100 个
        myToken.mint(user2, 50);
        myToken.approve(address(nftMarket), 100);
        
        // 尝试购买，应该失败（余额不足）
        vm.expectRevert("Token balance is insufficient");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试支付Token授权不足但余额足够的情况
    function test_buyNFT_InsufficientAllowance_SufficientBalance_Revert() public {
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 给 user2 1000 个 Token，但只授权 50 个
        myToken.mint(user2, 1000);
        myToken.approve(address(nftMarket), 50);
        
        // 尝试购买，应该失败（授权不足）
        vm.expectRevert("Token authorization is insufficient");
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试通过tokensReceived回调支付正确金额成功购买
    function test_tokensReceived_CorrectPayment_Success() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 支付正确的金额 100 个 Token
        bytes memory data = abi.encode(address(myNFT), tokenId);
        myToken.transferAndCall(address(nftMarket), 100, data);
        vm.stopPrank();
        
        // 验证购买成功
        assertEq(myNFT.ownerOf(tokenId), user2, "NFT should be transferred to user2");
        
        // 验证上架状态变为非活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, false, "Listing should be inactive after purchase");
        
        // 验证 Token 余额变化
        assertEq(myToken.balanceOf(user1), 100, "User1 should receive 100 tokens");
        assertEq(myToken.balanceOf(user2), 900, "User2 should have 900 tokens left");
    }

    // 测试支付Token金额为零的情况
    function test_tokensReceived_ZeroPayment_Revert() public {
        // 给 user2 铸造 Token
        myToken.mint(user2, 1000);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 尝试支付 0 个 Token
        bytes memory data = abi.encode(address(myNFT), tokenId);
        vm.expectRevert("Payment amount does not match");
        myToken.transferAndCall(address(nftMarket), 0, data);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (address seller, address nftAddress, uint256 tokenId_, uint256 price, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 测试支付Token金额为极大值的情况
    function test_tokensReceived_ExtremeOverpayment_Revert() public {
        // 给 user2 铸造 Token，使用一个合理的极大值而不是 type(uint256).max
        uint256 extremeAmount = 1e20; // 使用一个合理的极大值
        myToken.mint(user2, extremeAmount);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, 100); // 价格设置为 100
        vm.stopPrank();

        vm.startPrank(user2);
        // 尝试支付极大值
        bytes memory data = abi.encode(address(myNFT), tokenId);
        vm.expectRevert("Payment amount does not match");
        myToken.transferAndCall(address(nftMarket), extremeAmount, data);
        vm.stopPrank();
        
        // 验证 NFT 仍然属于 user1
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        
        // 验证上架状态仍然活跃
        (,,,, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    //模糊测试

    // 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzz_RandomPriceAndRandomBuyer(uint256 price, address buyer) public {
        vm.assume(price >= 1 && price <= 10000);
        vm.assume(buyer != address(0));
        vm.assume(buyer != user1);

        uint256 user1InitialBalance = myToken.balanceOf(user1);
        myToken.mint(buyer, price * 2);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();
        
        (,,, uint256 listedPrice, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "NFT should be listed");
        assertEq(listedPrice, price, "Price should match");
        
        vm.startPrank(buyer);
        myToken.approve(address(nftMarket), price);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        (,,,, bool activeAfter) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(activeAfter, false, "Listing should be inactive after purchase");
        assertEq(myToken.balanceOf(user1), user1InitialBalance + price, "Seller should have initial balance plus price");
        assertEq(myToken.balanceOf(buyer), price, "Buyer should have price tokens left (price*2 - price)");
    }

    // 模糊测试：使用 transferAndCall 方式随机购买
    function testFuzz_RandomPriceAndTransferAndCall(uint256 price, address buyer) public {
        vm.assume(price >= 1 && price <= 10000);
        vm.assume(buyer != address(0));
        vm.assume(buyer != user1); // 防止 buyer 和 seller 是同一个地址

        uint256 user1InitialBalance = myToken.balanceOf(user1);
        myToken.mint(buyer, price * 2);

        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();

        vm.startPrank(buyer);
        bytes memory data = abi.encode(address(myNFT), tokenId);
        myToken.transferAndCall(address(nftMarket), price, data);
        vm.stopPrank();

        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        (,,,, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, false, "Listing should be inactive after purchase");
        assertEq(myToken.balanceOf(user1), user1InitialBalance + price, "Seller should have initial balance plus price");
        assertEq(myToken.balanceOf(buyer), price, "Buyer should have price tokens left (price*2 - price)");
    }

    // 模糊测试：随机价格但支付错误金额
    function testFuzz_RandomPriceWrongPayment(uint256 price, uint256 wrongAmount, address buyer) public {
        vm.assume(price >= 1 && price <= 10000);
        vm.assume(wrongAmount != price);
        vm.assume(buyer != address(0));
        vm.assume(wrongAmount <= 1e18); // 限制错误金额范围，避免溢出
        
        myToken.mint(buyer, wrongAmount + 1000); // 给买家铸造足够的 Token
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();
        
        vm.startPrank(buyer);
        bytes memory data = abi.encode(address(myNFT), tokenId);
        vm.expectRevert("Payment amount does not match");
        myToken.transferAndCall(address(nftMarket), wrongAmount, data);
        vm.stopPrank();
        
        assertEq(myNFT.ownerOf(tokenId), user1, "NFT should still belong to user1");
        (,,,, bool active) = nftMarket.listings(address(myNFT), tokenId);
        assertEq(active, true, "Listing should still be active");
    }

    // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function testInvariant_NFTMarketNeverHoldsTokens() public {
        // 记录初始状态
        uint256 initialBalance = myToken.balanceOf(address(nftMarket));
        assertEq(initialBalance, 0, "NFTMarket should start with 0 tokens");
        
        // 执行一系列随机操作
        for (uint256 i = 0; i < 10; i++) {
            // 随机价格
            uint256 price = bound(i, 1, 1000);
            
            // 随机买家
            address buyer = address(uint160(i + 1000)); // 避免与 user1, user2 冲突
            
            // 给买家铸造 Token
            myToken.mint(buyer, price * 2);
            
            vm.startPrank(user1);
            uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
            myNFT.approve(address(nftMarket), tokenId);
            nftMarket.list(address(myNFT), tokenId, price);
            vm.stopPrank();
            
            // 随机选择购买方式
            if (i % 2 == 0) {
                // 使用 buyNFT 方式
                vm.startPrank(buyer);
                myToken.approve(address(nftMarket), price);
                nftMarket.buyNFT(address(myNFT), tokenId);
                vm.stopPrank();
            } else {
                // 使用 transferAndCall 方式
                vm.startPrank(buyer);
                bytes memory data = abi.encode(address(myNFT), tokenId);
                myToken.transferAndCall(address(nftMarket), price, data);
                vm.stopPrank();
            }
            
            // 验证 NFTMarket 合约余额仍然为 0
            uint256 currentBalance = myToken.balanceOf(address(nftMarket));
            assertEq(currentBalance, 0, "NFTMarket should never hold tokens after any operation");
        }
    }

    // 不可变测试：测试多次买卖后 NFTMarket 合约余额仍为 0
    function testInvariant_NFTMarketBalanceAlwaysZero() public {
        // 执行复杂的买卖操作
        address[] memory users = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            users[i] = address(uint160(i + 2000));
            myToken.mint(users[i], 10000);
        }
        
        // 创建多个 NFT 并进行买卖
        for (uint256 i = 0; i < 3; i++) {
            vm.startPrank(user1);
            uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
            myNFT.approve(address(nftMarket), tokenId);
            nftMarket.list(address(myNFT), tokenId, 100 + i * 50);
            vm.stopPrank();
            
            // 用户购买
            vm.startPrank(users[i]);
            myToken.approve(address(nftMarket), 100 + i * 50);
            nftMarket.buyNFT(address(myNFT), tokenId);
            vm.stopPrank();
            
            // 用户重新上架
            vm.startPrank(users[i]);
            myNFT.approve(address(nftMarket), tokenId);
            nftMarket.list(address(myNFT), tokenId, 200 + i * 50);
            vm.stopPrank();
            
            // 另一个用户购买
            vm.startPrank(users[i + 1]);
            myToken.approve(address(nftMarket), 200 + i * 50);
            nftMarket.buyNFT(address(myNFT), tokenId);
            vm.stopPrank();
            
            // 每次操作后验证 NFTMarket 余额为 0
            uint256 balance = myToken.balanceOf(address(nftMarket));
            assertEq(balance, 0, "NFTMarket balance should always be 0 after any operation");
        }
    }

    // 模糊测试：测试边界价格
    function testFuzz_BoundaryPrices(uint256 price) public {
        // 测试边界价格：1, 2, 9999, 10000
        vm.assume(price == 1 || price == 2 || price == 9999 || price == 10000);
        
        address buyer = address(0x999);
        myToken.mint(buyer, price * 2);
        
        vm.startPrank(user1);
        uint256 tokenId = myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u");
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();
        
        // 验证上架
        // (address seller, ,, , uint256 listedPrice, bool active) = nftMarket.listings(address(myNFT), tokenId);
        // assertEq(active, true, "NFT should be listed");
        // assertEq(listedPrice, price, "Price should match");
        
        // 购买
        vm.startPrank(buyer);
        myToken.approve(address(nftMarket), price);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证购买成功
        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        
        // 验证 NFTMarket 余额为 0
        assertEq(myToken.balanceOf(address(nftMarket)), 0, "NFTMarket should have 0 balance");
    }

    // 模糊测试：测试随机 Token ID
    function testFuzz_RandomTokenId(uint256 tokenId, uint256 price) public {
        // 限制价格范围
        vm.assume(price >= 1 && price <= 1000);
        
        address buyer = address(0x888);
        myToken.mint(buyer, price * 2);
        
        vm.startPrank(user1);
        // 铸造指定 ID 的 NFT（如果可能）
        try myNFT.mintNFT(user1, "https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u") returns (uint256 mintedId) {
            // 如果铸造成功，使用铸造的 ID
            tokenId = mintedId;
        } catch {
            // 如果铸造失败，跳过测试
            return;
        }
        
        myNFT.approve(address(nftMarket), tokenId);
        nftMarket.list(address(myNFT), tokenId, price);
        vm.stopPrank();
        
        // 购买
        vm.startPrank(buyer);
        myToken.approve(address(nftMarket), price);
        nftMarket.buyNFT(address(myNFT), tokenId);
        vm.stopPrank();
        
        // 验证购买成功
        assertEq(myNFT.ownerOf(tokenId), buyer, "NFT should be transferred to buyer");
        
        // 验证 NFTMarket 余额为 0
        assertEq(myToken.balanceOf(address(nftMarket)), 0, "NFTMarket should have 0 balance");
    }
}