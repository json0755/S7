// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定Solidity编译器版本

// 定义 BaseERC20 的接口，便于与 TokenBank 交互
interface IBaseERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 代理转账函数声明
    function transfer(address to, uint256 amount) external returns (bool); // 普通转账函数声明
}

// TokenBank 合约，允许用户存入和取出 BaseERC20 Token
contract TokenBank {
    IBaseERC20 public token; // 存储 BaseERC20 Token 的合约地址
    mapping(address => uint256) public balances; // 记录每个用户在银行中存入的 Token 数量

    constructor(address tokenAddress) { // 构造函数，初始化时指定 BaseERC20 Token 的合约地址
        token = IBaseERC20(tokenAddress); // 保存 Token 合约地址
    }

    function deposit(uint256 amount) public { // 存入 Token 的函数
        require(amount > 0, unicode"存入数量必须大于0"); // 检查存入数量
        require(token.transferFrom(msg.sender, address(this), amount), unicode"transferFrom 失败"); // 从用户账户转移 Token 到银行合约
        balances[msg.sender] += amount; // 增加用户在银行的存款记录
    }

    function withdraw(uint256 amount) public { // 提取 Token 的函数
        require(amount > 0, unicode"提取数量必须大于0"); // 检查提取数量
        require(balances[msg.sender] >= amount, unicode"余额不足"); // 检查用户余额
        balances[msg.sender] -= amount; // 扣减用户在银行的存款记录
        require(token.transfer(msg.sender, amount), unicode"transfer 失败"); // 从银行合约转移 Token 回用户账户
    }
}