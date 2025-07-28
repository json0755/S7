// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定Solidity编译器版本

// 导入本地的 Permit2 合约和相关接口
import "./Permit2.sol";

// 定义 BaseERC20 的接口，便于与 TokenBank 交互
interface IBaseERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool); // 代理转账函数声明
    function transfer(address to, uint256 amount) external returns (bool); // 普通转账函数声明
    function balanceOf(address account) external view returns (uint256); // 查询余额函数声明
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external; // EIP2612 permit 函数声明
}

// TokenBank 合约，允许用户存入和取出 BaseERC20 Token
contract TokenBank {
    IBaseERC20 public token; // 存储 BaseERC20 Token 的合约地址
    Permit2 public permit2; // Permit2 合约地址
    mapping(address => uint256) public balances; // 记录每个用户在银行中存入的 Token 数量

    // 事件声明
    event Deposit(address indexed user, uint256 amount, string method);
    event Withdrawal(address indexed user, uint256 amount);

    constructor(address tokenAddress, address permit2Address) { // 构造函数，初始化时指定 BaseERC20 Token 和 Permit2 合约地址
        token = IBaseERC20(tokenAddress); // 保存 Token 合约地址
        permit2 = Permit2(permit2Address); // 保存 Permit2 合约地址
    }

    function deposit(uint256 amount) public { // 存入 Token 的函数
        require(amount > 0, unicode"存入数量必须大于0"); // 检查存入数量
        require(token.transferFrom(msg.sender, address(this), amount), unicode"transferFrom 失败"); // 从用户账户转移 Token 到银行合约
        balances[msg.sender] += amount; // 增加用户在银行的存款记录
        emit Deposit(msg.sender, amount, "normal");
    }

    function withdraw(uint256 amount) public { // 提取 Token 的函数
        require(amount > 0, unicode"提取数量必须大于0"); // 检查提取数量
        require(balances[msg.sender] >= amount, unicode"余额不足"); // 检查用户余额
        balances[msg.sender] -= amount; // 扣减用户在银行的存款记录
        require(token.transfer(msg.sender, amount), unicode"transfer 失败"); // 从银行合约转移 Token 回用户账户
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev 使用 permit 签名进行存款，无需事先调用 approve
     * @param amount 存款金额
     * @param deadline permit 签名的截止时间
     * @param v 签名的 v 值
     * @param r 签名的 r 值
     * @param s 签名的 s 值
     */
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(amount > 0, unicode"存入数量必须大于0"); // 检查存入数量
        
        // 使用 permit 进行授权，允许本合约从用户账户转移 token
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        
        // 执行转账并更新余额
        require(token.transferFrom(msg.sender, address(this), amount), unicode"transferFrom 失败");
        balances[msg.sender] += amount; // 增加用户在银行的存款记录
        emit Deposit(msg.sender, amount, "permit");
    }

    /**
     * @dev 使用 Permit2 签名进行存款，提供更强大的签名授权机制
     * @param amount 存款金额
     * @param nonce 防重放攻击的随机数
     * @param deadline 签名过期时间
     * @param signature Permit2 签名数据
     */
    function depositWithPermit2(
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) public {
        require(amount > 0, unicode"存入数量必须大于0"); // 检查存入数量
        
        // 构造 Permit2 转账结构体
        Permit2.PermitTransferFrom memory permitData = Permit2.PermitTransferFrom({
            permitted: Permit2.TokenPermissions({
                token: address(token),
                amount: amount
            }),
            nonce: nonce,
            deadline: deadline
        });

        // 构造转账详情
        Permit2.SignatureTransferDetails memory transferDetails = Permit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: amount
        });
        
        // 使用 Permit2 进行签名验证和转账
        permit2.permitTransferFrom(
            permitData,
            transferDetails,
            msg.sender,
            signature
        );
        
        // 更新用户余额
        balances[msg.sender] += amount;
        emit Deposit(msg.sender, amount, "permit2");
    }

    /**
     * @dev 获取用户余额
     * @param user 用户地址
     * @return 用户在银行的存款余额
     */
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev 获取合约中的总 Token 余额
     * @return 合约持有的 Token 总量
     */
    function getTotalBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}