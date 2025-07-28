// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {BaseERC20} from "../src/BaseERC20.sol";
import {Permit2} from "../src/Permit2.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract LocalPermit2Test is Test {
    BaseERC20 public token;
    Permit2 public permit2;
    TokenBank public tokenBank;
    
    address public user = address(0x1234);
    uint256 public userPrivateKey = 0x1234567890abcdef;
    
    // EIP-712 related
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TRANSFER_FROM_TYPEHASH = 
        keccak256("PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)");
    bytes32 public constant TOKEN_PERMISSIONS_TYPEHASH = 
        keccak256("TokenPermissions(address token,uint256 amount)");

    function setUp() public {
        console2.log("Setting up local Permit2 test environment...");
        
        // Deploy contracts
        token = new BaseERC20(1000000 ether); // 1 million tokens initial supply
        permit2 = new Permit2();
        tokenBank = new TokenBank(address(token), address(permit2));
        
        // Get domain separator
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
        
        // Setup user
        user = vm.addr(userPrivateKey);
        
        // Mint tokens for user
        token.mint(user, 10000 ether);
        
        console2.log("Test environment setup complete");
        console2.log("Token address:", address(token));
        console2.log("Permit2 address:", address(permit2));
        console2.log("TokenBank address:", address(tokenBank));
        console2.log("User address:", user);
        console2.log("User balance:", token.balanceOf(user));
    }

    function testPermit2BasicInfo() public view {
        console2.log("Testing Permit2 basic info...");
        
        assertEq(permit2.name(), "Permit2");
        assertEq(permit2.version(), "1");
        assertTrue(DOMAIN_SEPARATOR != bytes32(0));
        
        console2.log("Basic info correct");
        console2.log("  Name:", permit2.name());
        console2.log("  Version:", permit2.version());
        console2.log("  Domain Separator:", vm.toString(DOMAIN_SEPARATOR));
    }

    function testNonceBitmap() public {
        console2.log("Testing Nonce management...");
        
        // Test initial state
        assertFalse(permit2.isNonceUsed(user, 0));
        assertFalse(permit2.isNonceUsed(user, 255));
        assertFalse(permit2.isNonceUsed(user, 256));
        
        console2.log("Nonce initial state correct");
    }

    function testPermitTransferFromSuccess() public {
        console2.log("Testing Permit2 transfer success scenario...");
        
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        uint256 deadline = block.timestamp + 3600;
        
        // 1. User approves permit2
        vm.prank(user);
        token.approve(address(permit2), amount);
        
        // 2. Build signature data
        Permit2.PermitTransferFrom memory permit = Permit2.PermitTransferFrom({
            permitted: Permit2.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: nonce,
            deadline: deadline
        });
        
        Permit2.SignatureTransferDetails memory transferDetails = Permit2.SignatureTransferDetails({
            to: address(tokenBank),
            requestedAmount: amount
        });
        
        // 3. Generate signature
        bytes memory signature = _signPermit(permit, userPrivateKey);
        
        // 4. Record initial balances
        uint256 userBalanceBefore = token.balanceOf(user);
        uint256 bankBalanceBefore = token.balanceOf(address(tokenBank));
        
        console2.log("Balances before transfer:");
        console2.log("  User:", userBalanceBefore);
        console2.log("  Bank:", bankBalanceBefore);
        
        // 5. Execute transfer
        permit2.permitTransferFrom(permit, transferDetails, user, signature);
        
        // 6. Verify results
        uint256 userBalanceAfter = token.balanceOf(user);
        uint256 bankBalanceAfter = token.balanceOf(address(tokenBank));
        
        assertEq(userBalanceAfter, userBalanceBefore - amount);
        assertEq(bankBalanceAfter, bankBalanceBefore + amount);
        assertTrue(permit2.isNonceUsed(user, nonce));
        
        console2.log("Balances after transfer:");
        console2.log("  User:", userBalanceAfter);
        console2.log("  Bank:", bankBalanceAfter);
        console2.log("Permit2 transfer successful!");
    }

    function testPermitTransferFromExpired() public {
        console2.log("Testing expired signature...");
        
        uint256 amount = 100 ether;
        uint256 nonce = 2;
        uint256 deadline = block.timestamp - 1; // Already expired
        
        vm.prank(user);
        token.approve(address(permit2), amount);
        
        Permit2.PermitTransferFrom memory permit = Permit2.PermitTransferFrom({
            permitted: Permit2.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: nonce,
            deadline: deadline
        });
        
        Permit2.SignatureTransferDetails memory transferDetails = Permit2.SignatureTransferDetails({
            to: address(tokenBank),
            requestedAmount: amount
        });
        
        bytes memory signature = _signPermit(permit, userPrivateKey);
        
        // Should revert
        vm.expectRevert(Permit2.SignatureExpired.selector);
        permit2.permitTransferFrom(permit, transferDetails, user, signature);
        
        console2.log("Expired signature correctly rejected");
    }

    function testPermitTransferFromNonceReuse() public {
        console2.log("Testing nonce replay attack...");
        
        uint256 amount = 100 ether;
        uint256 nonce = 3;
        uint256 deadline = block.timestamp + 3600;
        
        vm.prank(user);
        token.approve(address(permit2), amount * 2); // Approve enough amount
        
        Permit2.PermitTransferFrom memory permit = Permit2.PermitTransferFrom({
            permitted: Permit2.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: nonce,
            deadline: deadline
        });
        
        Permit2.SignatureTransferDetails memory transferDetails = Permit2.SignatureTransferDetails({
            to: address(tokenBank),
            requestedAmount: amount
        });
        
        bytes memory signature = _signPermit(permit, userPrivateKey);
        
        // First use should succeed
        permit2.permitTransferFrom(permit, transferDetails, user, signature);
        console2.log("First use successful");
        
        // Second use with same nonce should fail
        vm.expectRevert(Permit2.InvalidNonce.selector);
        permit2.permitTransferFrom(permit, transferDetails, user, signature);
        
        console2.log("Nonce replay attack prevented");
    }

    // Helper function: Generate signature for Permit2
    function _signPermit(
        Permit2.PermitTransferFrom memory permit,
        uint256 privateKey
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(
            PERMIT_TRANSFER_FROM_TYPEHASH,
            keccak256(abi.encode(
                TOKEN_PERMISSIONS_TYPEHASH,
                permit.permitted.token,
                permit.permitted.amount
            )),
            permit.nonce,
            permit.deadline
        ));

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        return abi.encodePacked(r, s, v);
    }
} 