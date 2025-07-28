// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/07-25/EIP2612Token.sol";

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    EIP2612Token public token;
    
    address public owner;
    address public user1;
    address public user2;
    
    uint256 private ownerPrivateKey = 0xA11CE;
    uint256 private user1PrivateKey = 0xB0B;
    
    uint256 constant INITIAL_SUPPLY = 1000000; // 1M tokens
    uint8 constant DECIMALS = 18;
    uint256 constant SUPPLY_CAP = 10000000 * 10**18; // 10M tokens in wei
    
    function setUp() public {
        owner = vm.addr(ownerPrivateKey);
        user1 = vm.addr(user1PrivateKey);
        user2 = makeAddr("user2");
        
        // 部署支持 EIP2612 的代币
        vm.prank(owner);
        token = new EIP2612Token(
            "Test Token",
            "TEST",
            INITIAL_SUPPLY,
            DECIMALS,
            SUPPLY_CAP
        );
        
        // 部署 TokenBank
        address permit2Address = 0x000000000022D473030F116dDEE9F6B43aC78BA3; // Permit2 官方地址
        tokenBank = new TokenBank(address(token), permit2Address);
        
        // 给 user1 一些代币用于测试
        vm.prank(owner);
        token.transfer(user1, 10000 * 10**DECIMALS);
    }
    
    // 测试基本存款功能
    function testBasicDeposit() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        
        vm.startPrank(user1);
        token.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(depositAmount);
        vm.stopPrank();
        
        assertEq(tokenBank.balances(user1), depositAmount);
        assertEq(token.balanceOf(address(tokenBank)), depositAmount);
    }
    
    // 测试基本提款功能
    function testBasicWithdraw() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        uint256 withdrawAmount = 500 * 10**DECIMALS;
        
        // 先存款
        vm.startPrank(user1);
        token.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(depositAmount);
        
        // 再提款
        tokenBank.withdraw(withdrawAmount);
        vm.stopPrank();
        
        assertEq(tokenBank.balances(user1), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(user1), (10000 * 10**DECIMALS) - depositAmount + withdrawAmount);
    }
    
    // 测试 permit 存款功能
    function testPermitDeposit() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 创建 permit 签名
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                depositAmount,
                token.nonces(user1),
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
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);
        
        // 执行 permit 存款
        vm.prank(user1);
        tokenBank.permitDeposit(depositAmount, deadline, v, r, s);
        
        // 验证结果
        assertEq(tokenBank.balances(user1), depositAmount);
        assertEq(token.balanceOf(address(tokenBank)), depositAmount);
        assertEq(token.balanceOf(user1), (10000 * 10**DECIMALS) - depositAmount);
        assertEq(token.nonces(user1), 1); // nonce 应该增加
    }
    
    // 测试 permit 存款失败 - 过期的 deadline
    function testPermitDepositExpiredDeadline() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        uint256 deadline = block.timestamp - 1; // 过期的 deadline
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                depositAmount,
                token.nonces(user1),
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
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);
        
        vm.prank(user1);
        vm.expectRevert(); // 应该抛出过期错误
        tokenBank.permitDeposit(depositAmount, deadline, v, r, s);
    }
    
    // 测试 permit 存款失败 - 无效签名
    function testPermitDepositInvalidSignature() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        uint256 deadline = block.timestamp + 1 hours;
        
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                depositAmount,
                token.nonces(user1),
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
        
        // 使用错误的私钥签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, hash);
        
        vm.prank(user1);
        vm.expectRevert(); // 应该抛出无效签名错误
        tokenBank.permitDeposit(depositAmount, deadline, v, r, s);
    }
    
    // 测试 permit 存款失败 - 金额为0
    function testPermitDepositZeroAmount() public {
        uint256 depositAmount = 0;
        uint256 deadline = block.timestamp + 1 hours;
        
        vm.prank(user1);
        vm.expectRevert(unicode"存入数量必须大于0");
        tokenBank.permitDeposit(depositAmount, deadline, 0, bytes32(0), bytes32(0));
    }
    
    // 测试多次 permit 存款
    function testMultiplePermitDeposits() public {
        uint256 firstDeposit = 500 * 10**DECIMALS;
        uint256 secondDeposit = 300 * 10**DECIMALS;
        uint256 deadline = block.timestamp + 1 hours;
        
        // 第一次 permit 存款
        bytes32 structHash1 = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                firstDeposit,
                token.nonces(user1),
                deadline
            )
        );
        
        bytes32 hash1 = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash1
            )
        );
        
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(user1PrivateKey, hash1);
        
        vm.prank(user1);
        tokenBank.permitDeposit(firstDeposit, deadline, v1, r1, s1);
        
        // 第二次 permit 存款
        bytes32 structHash2 = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                secondDeposit,
                token.nonces(user1), // nonce 已经增加到 1
                deadline
            )
        );
        
        bytes32 hash2 = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                structHash2
            )
        );
        
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(user1PrivateKey, hash2);
        
        vm.prank(user1);
        tokenBank.permitDeposit(secondDeposit, deadline, v2, r2, s2);
        
        // 验证总存款
        assertEq(tokenBank.balances(user1), firstDeposit + secondDeposit);
        assertEq(token.nonces(user1), 2);
    }
    
    // 测试 permit 存款后提款
    function testPermitDepositThenWithdraw() public {
        uint256 depositAmount = 1000 * 10**DECIMALS;
        uint256 withdrawAmount = 600 * 10**DECIMALS;
        uint256 deadline = block.timestamp + 1 hours;
        
        // Permit 存款
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                user1,
                address(tokenBank),
                depositAmount,
                token.nonces(user1),
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
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1PrivateKey, hash);
        
        vm.startPrank(user1);
        tokenBank.permitDeposit(depositAmount, deadline, v, r, s);
        
        // 提款
        tokenBank.withdraw(withdrawAmount);
        vm.stopPrank();
        
        assertEq(tokenBank.balances(user1), depositAmount - withdrawAmount);
        assertEq(token.balanceOf(user1), (10000 * 10**DECIMALS) - depositAmount + withdrawAmount);
    }
} 