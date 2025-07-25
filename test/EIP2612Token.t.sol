// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/07-25/EIP2612Token.sol";

contract EIP2612TokenTest is Test {
    EIP2612Token public token;
    
    address public owner;
    address public user1;
    address public user2;
    address public spender;
    
    string constant TOKEN_NAME = "EIP2612 Test Token";
    string constant TOKEN_SYMBOL = "E2612";
    uint256 constant INITIAL_SUPPLY = 1000000; // 1M tokens
    uint8 constant DECIMALS = 18;
    uint256 constant SUPPLY_CAP = 10000000 * 10**18; // 10M tokens cap in wei
    
    // Permit test variables
    uint256 private ownerPrivateKey = 0xA11CE;
    uint256 private spenderPrivateKey = 0xB0B;
    
    function setUp() public {
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.prank(owner);
        token = new EIP2612Token(
            TOKEN_NAME,
            TOKEN_SYMBOL,
            INITIAL_SUPPLY,
            DECIMALS,
            SUPPLY_CAP
        );
    }
    
    // Basic ERC20 functionality tests
    function testInitialSetup() public view {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10**DECIMALS);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10**DECIMALS);
        assertEq(token.cap(), SUPPLY_CAP);
        assertEq(token.owner(), owner);
    }
    
    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**DECIMALS;
        
        vm.prank(owner);
        bool success = token.transfer(user1, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), (INITIAL_SUPPLY * 10**DECIMALS) - transferAmount);
    }
    
    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 5000 * 10**DECIMALS;
        uint256 transferAmount = 2000 * 10**DECIMALS;
        
        // Owner approves spender
        vm.prank(owner);
        token.approve(spender, approveAmount);
        
        assertEq(token.allowance(owner, spender), approveAmount);
        
        // Spender transfers from owner to user1
        vm.prank(spender);
        bool success = token.transferFrom(owner, user1, transferAmount);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.allowance(owner, spender), approveAmount - transferAmount);
    }
    
    // Minting tests
    function testMintByOwner() public {
        uint256 mintAmount = 1000;
        uint256 expectedBalance = mintAmount * 10**DECIMALS;
        
        vm.prank(owner);
        token.mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), expectedBalance);
        assertEq(token.totalSupply(), (INITIAL_SUPPLY * 10**DECIMALS) + expectedBalance);
    }
    
    function testMintFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1000);
    }
    
    function testMintFailsIfExceedsCap() public {
        uint256 exceedingAmount = SUPPLY_CAP + 1;
        
        vm.prank(owner);
        vm.expectRevert("EIP2612Token: cap exceeded");
        token.mint(user1, exceedingAmount);
    }
    
    // Burning tests
    function testBurnByOwner() public {
        uint256 burnAmount = 1000;
        uint256 burnAmountWei = burnAmount * 10**DECIMALS;
        uint256 initialOwnerBalance = token.balanceOf(owner);
        
        vm.prank(owner);
        token.burn(owner, burnAmount);
        
        assertEq(token.balanceOf(owner), initialOwnerBalance - burnAmountWei);
        assertEq(token.totalSupply(), (INITIAL_SUPPLY * 10**DECIMALS) - burnAmountWei);
    }
    
    function testBurnSelfTokens() public {
        // First transfer some tokens to user1
        uint256 transferAmount = 5000 * 10**DECIMALS;
        vm.prank(owner);
        token.transfer(user1, transferAmount);
        
        // User1 burns their own tokens
        uint256 burnAmount = 1000;
        uint256 burnAmountWei = burnAmount * 10**DECIMALS;
        
        vm.prank(user1);
        token.burn(burnAmount);
        
        assertEq(token.balanceOf(user1), transferAmount - burnAmountWei);
    }
    
    function testBurnFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.burn(owner, 1000);
    }
    
    // Batch transfer tests
    function testBatchTransfer() public {
        address[] memory recipients = new address[](3);
        uint256[] memory amounts = new uint256[](3);
        
        recipients[0] = user1;
        recipients[1] = user2;
        recipients[2] = spender;
        
        amounts[0] = 1000;
        amounts[1] = 2000;
        amounts[2] = 3000;
        
        vm.prank(owner);
        token.batchTransfer(recipients, amounts);
        
        assertEq(token.balanceOf(user1), 1000 * 10**DECIMALS);
        assertEq(token.balanceOf(user2), 2000 * 10**DECIMALS);
        assertEq(token.balanceOf(spender), 3000 * 10**DECIMALS);
    }
    
    function testBatchTransferFailsOnArrayMismatch() public {
        address[] memory recipients = new address[](2);
        uint256[] memory amounts = new uint256[](3);
        
        recipients[0] = user1;
        recipients[1] = user2;
        amounts[0] = 1000;
        amounts[1] = 2000;
        amounts[2] = 3000;
        
        vm.prank(owner);
        vm.expectRevert("EIP2612Token: arrays length mismatch");
        token.batchTransfer(recipients, amounts);
    }
    
    // EIP2612 Permit functionality tests
    function testPermit() public {
        uint256 value = 1000 * 10**DECIMALS;
        uint256 nonce = token.nonces(owner);
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create permit signature
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);
        
        // Execute permit
        token.permit(owner, spender, value, deadline, v, r, s);
        
        assertEq(token.allowance(owner, spender), value);
        assertEq(token.nonces(owner), nonce + 1);
    }
    
    function testPermitExpiredDeadline() public {
        uint256 value = 1000 * 10**DECIMALS;
        uint256 nonce = token.nonces(owner);
        uint256 deadline = block.timestamp - 1; // Past deadline
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);
        
        vm.expectRevert(); // ERC2612ExpiredSignature
        token.permit(owner, spender, value, deadline, v, r, s);
    }
    
    function testPermitInvalidSignature() public {
        uint256 value = 1000 * 10**DECIMALS;
        uint256 nonce = token.nonces(owner);
        uint256 deadline = block.timestamp + 1 hours;
        
        // Create wrong signature (sign with wrong private key)
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash
            )
        );
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(spenderPrivateKey, hash); // Wrong key
        
        vm.expectRevert(); // ERC2612InvalidSigner
        token.permit(owner, spender, value, deadline, v, r, s);
    }
    
    // Ownership tests
    function testTransferOwnership() public {
        vm.prank(owner);
        token.transferOwnership(user1);
        
        assertEq(token.owner(), user1);
    }
    
    function testTransferOwnershipFailsIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transferOwnership(user2);
    }
    
    function testTransferOwnershipFailsZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("EIP2612Token: new owner is the zero address");
        token.transferOwnership(address(0));
    }
    
    // Emergency pause test
    function testEmergencyPauseNotImplemented() public {
        vm.prank(owner);
        vm.expectRevert("EIP2612Token: Emergency pause not implemented");
        token.emergencyPause();
    }
    
    // Edge cases and fuzz tests
    function testFuzzTransfer(uint256 amount) public {
        amount = bound(amount, 1, token.balanceOf(owner));
        
        vm.prank(owner);
        bool success = token.transfer(user1, amount);
        
        assertTrue(success);
        assertEq(token.balanceOf(user1), amount);
    }
    
    function testFuzzMint(uint256 amount) public {
        uint256 currentSupply = token.totalSupply();
        uint256 availableToMint = (SUPPLY_CAP - currentSupply) / 10**DECIMALS;
        
        amount = bound(amount, 1, availableToMint);
        
        vm.prank(owner);
        token.mint(user1, amount);
        
        assertEq(token.balanceOf(user1), amount * 10**DECIMALS);
    }
} 