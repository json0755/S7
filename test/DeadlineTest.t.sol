// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/07-25/EIP2612Token.sol";
import "../src/Permit2.sol";
import "../src/TokenBank.sol";

contract DeadlineTest is Test {
    EIP2612Token public token;
    Permit2 public permit2;
    TokenBank public tokenBank;
    
    address public user;
    uint256 public userPrivateKey = ;
    
    uint256 constant INITIAL_SUPPLY = 10000;
    uint256 constant TEST_AMOUNT = 100e18;
    
    function setUp() public {
        console.log("Setting up deadline test environment...");
        
        user = vm.addr(userPrivateKey);
        
        token = new EIP2612Token("BapeToken", "BAPE", INITIAL_SUPPLY, 18, 0);
        permit2 = new Permit2();
        tokenBank = new TokenBank(address(token), address(permit2));
        
        token.mint(user, 1000);
        
        // 预授权 Permit2
        vm.prank(user);
        token.approve(address(permit2), type(uint256).max);
        
        console.log("Deadline test environment ready");
        console.log("Current block.timestamp:", block.timestamp);
    }
    
    function test_ValidDeadline() public {
        console.log("=== Testing Valid Deadline ===");
        
        uint256 currentTime = block.timestamp;
        uint256 deadline = currentTime + 3600; // 1小时后过期
        
        console.log("Current time:", currentTime);
        console.log("Deadline time:", deadline);
        console.log("Time difference:", deadline - currentTime, "seconds");
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 0;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // 应该成功
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        
        console.log("Valid deadline test passed!");
    }
    
    function test_ExpiredDeadline() public {
        console.log("=== Testing Expired Deadline ===");
        
        uint256 currentTime = block.timestamp;
        uint256 deadline = currentTime - 1; // 已经过期
        
        console.log("Current time:", currentTime);
        console.log("Deadline time:", deadline);
        console.log("Deadline is EXPIRED (past current time)");
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 1;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // 应该失败并抛出 SignatureExpired 错误
        vm.expectRevert();
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        
        console.log("Expired deadline correctly rejected!");
    }
    
    function test_DeadlineAtBoundary() public {
        console.log("=== Testing Deadline at Boundary ===");
        
        uint256 currentTime = block.timestamp;
        uint256 deadline = currentTime; // 恰好当前时间
        
        console.log("Current time:", currentTime);
        console.log("Deadline time:", deadline);
        console.log("Time difference:", 0, "seconds (boundary case)");
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 2;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // 根据Permit2合约实现，当block.timestamp == deadline时不会失败
        // 只有当block.timestamp > deadline时才会失败
        // 所以这个边界情况应该成功
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        
        console.log("Boundary deadline test passed! (deadline == current time is valid)");
    }
    
    function test_FarFutureDeadline() public {
        console.log("=== Testing Far Future Deadline ===");
        
        uint256 currentTime = block.timestamp;
        uint256 deadline = currentTime + 365 days; // 1年后
        
        console.log("Current time:", currentTime);
        console.log("Deadline time:", deadline);
        console.log("Time difference:", deadline - currentTime, "seconds");
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 3;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // 应该成功
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        
        console.log("Far future deadline test passed!");
    }
    
    function test_TimeAdvancement() public {
        console.log("=== Testing Time Advancement ===");
        
        uint256 currentTime = block.timestamp;
        uint256 deadline = currentTime + 1800; // 30分钟后
        
        console.log("Initial time:", currentTime);
        console.log("Deadline time:", deadline);
        
        uint256 amount = TEST_AMOUNT;
        uint256 nonce = 4;
        
        bytes memory signature = _generateSignature(amount, nonce, deadline);
        
        // 现在应该成功
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, signature);
        console.log("First deposit successful");
        
        // 模拟时间推进到deadline之后
        vm.warp(deadline + 1);
        console.log("Time advanced to:", block.timestamp);
        
        uint256 nonce2 = 5;
        bytes memory signature2 = _generateSignature(amount, nonce2, deadline);
        
        // 现在应该失败
        vm.expectRevert();
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce2, deadline, signature2);
        
        console.log("Time advancement test passed!");
    }
    
    function _generateSignature(uint256 amount, uint256 nonce, uint256 deadline) internal view returns (bytes memory) {
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
        
        return abi.encodePacked(r, s, v);
    }
}