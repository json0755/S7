// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 编写一个 Bank 合约，实现功能：
// 1.可以通过 Metamask 等钱包直接给 Bank 合约地址存款
// 2.在 Bank 合约记录每个地址的存款金额
// 3.编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
// 4.用数组记录存款金额的前 3 名用户
contract Bank {
    // 记录每个地址的存款金额
    mapping(address => uint256) public balances;
    // 记录所有存款过的用户
    address[] private allUsers;
    mapping(address => bool) private isUser;
    // 记录存款金额的前 3 名用户
    address[3] public top3;
    // 管理员
    address public admin;

    // 构造函数，初始化管理员
    constructor() {
        admin = msg.sender;
    }

    // 存款函数，任何人可存钱
    function deposit() public payable {
        if (!isUser[msg.sender]) {
            allUsers.push(msg.sender);
            isUser[msg.sender] = true;
        }
        balances[msg.sender] += msg.value;
        updateTop3();
    }

    // 自动接收ETH并调用deposit
    receive() external payable {
        deposit();
    }

    // 更新top3，保证top3为存款最多的3个用户且无重复
    function updateTop3() internal {
        // 初始化临时数组
        address[3] memory tempTop3;
        uint256[3] memory tempAmounts;
        for (uint256 i = 0; i < allUsers.length; i++) {
            address user = allUsers[i];
            uint256 amount = balances[user];
            // 插入排序
            for (uint256 j = 0; j < 3; j++) {
                if (amount > tempAmounts[j]) {
                    // 后移
                    for (uint256 k = 2; k > j; k--) {
                        tempAmounts[k] = tempAmounts[k-1];
                        tempTop3[k] = tempTop3[k-1];
                    }
                    tempAmounts[j] = amount;
                    tempTop3[j] = user;
                    break;
                }
            }
        }
        top3 = tempTop3;
    }

    // 管理员提取指定金额
    function withdraw(uint256 amount) public {
        require(msg.sender == admin, "Only admin can withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }

    // 获取前 3 名用户
    function getTop3() public view returns (address[3] memory) {
        return top3;
    }

    // 获取指定地址的存款金额
    function getBalance(address addr) public view returns (uint256) {
        return balances[addr];
    }
}