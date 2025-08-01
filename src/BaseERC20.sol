// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定Solidity编译器版本

import "@openzeppelin/contracts/interfaces/IERC20.sol";

// 定义接收 Token 回调的接口
interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount) external; // 回调函数，接收Token时调用
}

contract BaseERC20 is IERC20 {
    string public name = "BaseERC20"; // 代币名称
    string public symbol = "BASE"; // 代币符号
    uint8 public decimals = 18; // 小数位数
    uint256 private _totalSupply; // 总供应量
    mapping(address => uint256) private _balances; // 记录每个地址的余额
    mapping(address => mapping(address => uint256)) private _allowances; // 记录授权信息

    constructor(uint256 initialSupply) { // 构造函数，初始化总供应量
        _totalSupply = initialSupply; // 设置总供应量
        _balances[msg.sender] = initialSupply; // 初始代币分配给合约部署者
    }

    function totalSupply() public view override returns (uint256) { // 返回总供应量
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) { // 返回指定账户余额
        return _balances[account];
    }
    function transfer(address to, uint256 amount) public override returns (bool) { // 普通转账
        _transfer(msg.sender, to, amount); // 调用内部转账逻辑
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) { // 查询授权额度
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) { // 授权spender可花费自己多少代币
        _allowances[msg.sender][spender] = amount; // 设置授权额度
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) { // 代理转账
        require(_allowances[from][msg.sender] >= amount, "allowance not enough"); // 检查授权额度
        _allowances[from][msg.sender] -= amount; // 扣减授权额度
        _transfer(from, to, amount); // 调用内部转账逻辑
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal { // 内部转账逻辑
        require(_balances[from] >= amount, "balance not enough"); // 检查余额
        _balances[from] -= amount; // 扣减发送方余额
        _balances[to] += amount; // 增加接收方余额
    }
    // 新增：带回调的转账
    function transferWithCallback(address to, uint256 amount) external returns (bool) { // 带回调的转账函数
        _transfer(msg.sender, to, amount); // 先完成转账
        if (isContract(to)) { // 如果目标地址是合约
            ITokenReceiver(to).tokensReceived(msg.sender, amount); // 调用目标合约的tokensReceived
        }
        return true;
    }
    // 判断地址是否为合约
    function isContract(address account) internal view returns (bool) { // 判断地址是否为合约
        uint256 size; // 存储代码大小
        assembly { size := extcodesize(account) } // 获取地址的代码大小
        return size > 0; // 如果大小0则为合约
    }

    // 新增：mint函数
    function mint(address to, uint256 amount) external {
        _totalSupply += amount; // 增加总供应量
        _balances[to] += amount; // 增加目标地址余额
        emit Transfer(address(0), to, amount); // 发出转账事件
    }
}