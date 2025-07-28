// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/07-25/EIP2612Token.sol";
import "../src/Permit2.sol";
import "../src/TokenBank.sol";

contract TestPermit2Deposit is Test {
    EIP2612Token public token;
    Permit2 public permit2;
    TokenBank public tokenBank;
    
    address public user;
    uint256 public userPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    
    uint256 constant INITIAL_SUPPLY = 10000;
    uint256 constant TEST_AMOUNT = 100e18;
    
    function setUp() public {
        console.log("Setting up test environment...");
        
        // Derive user address from private key
        user = vm.addr(userPrivateKey);
        console.log("Test user address:", user);
        
        token = new EIP2612Token("BapeToken", "BAPE", INITIAL_SUPPLY, 18, 0);
        console.log("EIP2612Token deployed at:", address(token));
        
        permit2 = new Permit2();
        console.log("Permit2 deployed at:", address(permit2));
        
        tokenBank = new TokenBank(address(token), address(permit2));
        console.log("TokenBank deployed at:", address(tokenBank));
        
        token.mint(user, 1000);
        
        console.log("Test environment setup complete");
        console.log("  - Token:", address(token));
        console.log("  - Permit2:", address(permit2));
        console.log("  - TokenBank:", address(tokenBank));
        console.log("  - Test user:", user);
        console.log("  - User token balance:", token.balanceOf(user) / 1e18, "tokens");
    }
    
    function test_FullPermit2DepositFlow() public {
        console.log("Starting full Permit2 deposit flow test");
        
        uint256 initialUserBalance = token.balanceOf(user);
        uint256 initialBankBalance = tokenBank.getBalance(user);
        
        console.log("Initial state:");
        console.log("  - User token balance:", initialUserBalance / 1e18, "tokens");
        console.log("  - User bank balance:", initialBankBalance / 1e18, "tokens");
        
        // Step 1: Approve Permit2
        _approvePermit2();
        
        // Step 2: Generate signature and deposit
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 0;
        uint256 deadline = block.timestamp + 3600;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // Step 3: Execute deposit
        console.log("Step 3: Execute Permit2 deposit");
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        console.log("depositWithPermit2 call successful!");
        
        // Step 4: Verify results
        _verifyDepositResults(initialUserBalance, initialBankBalance, amount, nonce);
        
        console.log("Permit2 deposit flow test completed successfully!");
    }
    
    function test_SignatureValidation() public {
        console.log("Testing Permit2 signature validation");
        
        vm.prank(user);
        token.approve(address(permit2), type(uint256).max);
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 1;
        uint256 deadline = block.timestamp + 3600;
        
        // Test correct signature
        bytes memory correctSignature = _generateSignature(amount, nonce, deadline);
        console.log("Testing correct signature...");
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, correctSignature);
        console.log("Correct signature validation passed");
        
        // Test wrong signature
        console.log("Testing wrong signature...");
        bytes32 wrongHash = keccak256("wrong data");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBAD, wrongHash);
        bytes memory wrongSignature = abi.encodePacked(r, s, v);
        
        vm.expectRevert();
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce + 1, deadline, wrongSignature);
        console.log("Wrong signature correctly rejected");
    }
    
    function test_NonceManagement() public {
        console.log("Testing Permit2 nonce management");
        
        vm.prank(user);
        token.approve(address(permit2), type(uint256).max);
        
        uint256 amount = TEST_AMOUNT / 2;
        uint256 nonce = 10;
        uint256 deadline = block.timestamp + 3600;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // First deposit should succeed
        console.log("First deposit (nonce 10)...");
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        console.log("First deposit successful");
        
        // Second deposit with same nonce should fail
        console.log("Second deposit (duplicate nonce 10)...");
        vm.expectRevert();
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        console.log("Duplicate nonce correctly rejected");
        
        assertTrue(permit2.isNonceUsed(user, nonce), "Nonce should be used");
    }
    
    function _approvePermit2() internal {
        console.log("Step 1: User approves Permit2 contract");
        vm.prank(user);
        token.approve(address(permit2), type(uint256).max);
        
        uint256 allowance = token.allowance(user, address(permit2));
        if (allowance > 1e30) {
            console.log("Approval complete, allowance: unlimited");
        } else {
            console.log("Approval complete, allowance:", allowance / 1e18, "tokens");
        }
    }
    
    function _generateSignature(uint256 amount, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
        console.log("Step 2: Generate Permit2 signature");
        console.log("Signature data:");
        console.log("  - amount:", amount / 1e18, "tokens");
        console.log("  - nonce:", nonce);
        console.log("  - deadline:", deadline);
        
        bytes32 domainSeparator = permit2.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)"),
            keccak256(abi.encode(
                keccak256("TokenPermissions(address token,uint256 amount)"),
                address(token),
                amount
            )),
            nonce,
            deadline
        ));
        
        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);
        
        console.log("Permit2 signature generated successfully");
        return abi.encodePacked(r, s, v);
    }
    
    function _verifyDepositResults(uint256 initialUserBalance, uint256 initialBankBalance, uint256 amount, uint256 nonce) internal {
        console.log("Step 4: Verify deposit results");
        
        uint256 finalUserBalance = token.balanceOf(user);
        uint256 finalBankBalance = tokenBank.getBalance(user);
        uint256 contractTokenBalance = tokenBank.getTotalBalance();
        
        console.log("Final state:");
        console.log("  - User token balance:", finalUserBalance / 1e18, "tokens");
        console.log("  - User bank balance:", finalBankBalance / 1e18, "tokens");
        console.log("  - Contract token balance:", contractTokenBalance / 1e18, "tokens");
        
        assertEq(finalUserBalance, initialUserBalance - amount, "User token balance should decrease");
        assertEq(finalBankBalance, initialBankBalance + amount, "User bank balance should increase");
        assertEq(contractTokenBalance, amount, "Contract should hold deposited tokens");
        
        bool finalNonceUsed = permit2.isNonceUsed(user, nonce);
        assertTrue(finalNonceUsed, "Nonce should now be used");
        console.log("All assertions passed!");
    }
} 