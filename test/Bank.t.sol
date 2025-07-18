// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);


    function setUp() public {
        vm.deal(address(this), 1000 ether);
        bank = new Bank();
        // vm.deal(address(bank),2000 ether);
        vm.deal(user1,2000 ether);
        vm.deal(user2,200 ether);
        vm.deal(user3,300 ether);
        vm.deal(user4,400 ether);
    }

//1.断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    function test_Deposit() public {
        assertEq(address(bank).balance, 0);
        bank.deposit{value: 100 ether}();
        assertEq(address(bank).balance,100 ether);
    }

//2.检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
    function test_top3() public {
        vm.prank(user1);
        bank.deposit{value: 100 ether}();
        vm.prank(user2);
        bank.deposit{value: 200 ether}();
        vm.prank(user3);
        bank.deposit{value: 300 ether}();
        vm.prank(user4);
        bank.deposit{value: 400 ether}();
        console.log("top3", bank.balances(bank.top3(0)), bank.balances(bank.top3(1)), bank.balances(bank.top3(2)));
    } 

//2.同一个用户多次存款的情况
    function testUser1ManyDeposit() public {
        bank.deposit{value: 100 ether}();
        bank.deposit{value: 200 ether}();
        bank.deposit{value: 300 ether}();
        assertEq(bank.balances(address(this)), 600 ether);
        console.log("top3", bank.top3(0), bank.top3(1), bank.top3(2));

        // vm.startPrank(user1);
        // bank.deposit{value: 100 ether}();
        // bank.deposit{value: 200 ether}();
        // bank.deposit{value: 300 ether}();
        // vm.stopPrank();
    }

//检查只有管理员可取款，其他人不可以取款。
    function testOnlyAdministratorCanWithdraw() public {
        bank.deposit{value: 100 ether}();
        assert(address(bank).balance == 100 ether);
        bank.withdraw(80 ether);
        assert(address(bank).balance == 20 ether);
        // 用user1模拟调用
        vm.prank(user1);
        // 期望revert，且revert reason为"Only admin can withdraw"
        vm.expectRevert(bytes("Only admin can withdraw"));
        bank.withdraw(10 ether);
    } 

    receive() external payable {}
}
