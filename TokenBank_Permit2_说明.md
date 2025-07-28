# TokenBank Permit2 功能说明

## 🎯 功能概述

在原有的 TokenBank 合约基础上，新增了 `depositWithPermit2()` 方法，使用 Permit2 标准进行签名授权转账存款。Permit2 提供了比 EIP-2612 更强大和灵活的签名授权机制。

## 🔧 技术特性

### Permit2 优势
- **批量授权**：支持一次授权多个token
- **灵活过期时间**：可设置任意过期时间
- **防重放攻击**：使用nonce机制
- **更好的安全性**：域分隔符和结构化签名
- **标准化**：由Uniswap团队开发的行业标准

### 合约升级内容
1. 添加了 Permit2 相关接口和结构体
2. 新增 `depositWithPermit2()` 方法
3. 增强了安全验证机制
4. 保持向后兼容性

## 📋 合约接口

### 新增结构体

```solidity
struct TokenPermissions {
    address token;  // ERC20 token 地址
    uint256 amount; // 授权金额
}

struct PermitTransferFrom {
    TokenPermissions permitted; // 授权的 token 和金额
    uint256 nonce;             // 防重放攻击的随机数
    uint256 deadline;          // 签名过期时间
}

struct SignatureTransferDetails {
    address to;                // 接收方地址
    uint256 requestedAmount;   // 请求转移的金额
}
```

### 新增方法

```solidity
function depositWithPermit2(
    uint256 amount,
    uint256 nonce,
    uint256 deadline,
    SignatureTransferDetails calldata transferDetails,
    bytes calldata signature
) public
```

## 🚀 使用步骤

### 1. 部署合约

```bash
# 编译合约
forge build

# 部署TokenBank合约（包含Permit2地址）
forge script script/TokenBank.s.sol --broadcast --rpc-url <YOUR_RPC_URL>
```

**重要合约地址：**
- Permit2官方地址：`0x000000000022D473030F116dDEE9F6B43aC78BA3`（多链通用）

### 2. 生成 Permit2 签名

使用我们提供的JavaScript工具：

```bash
# 进入scripts目录
cd scripts

# 运行签名生成工具
node generatePermit2Signature.js
```

**输出示例：**
```
生成 Permit2 存款签名...
用户地址: 0x1Be31A94361a391bBaFB2a4CCd704F57dc04d4bb
Token地址: 0xBe8446a91ec13Cd2d506D90E515635891B736b54
TokenBank地址: 0x你的TokenBank合约地址
存款金额: 100.0 tokens
Nonce: 1753626377635974742
截止时间: 7/28/2025, 10:26:17 PM
---
✅ Permit2 签名生成成功!
签名: 0xdc35e1c7b42c6dd6f815afff9944ddb4da96b8cd6cf503c9c90d2017a1b33bc3...
---
📋 合约调用参数:
amount: 100000000000000000000
nonce: 1753626377635974742
deadline: 1753712777
transferDetails: {
  to: 0x你的TokenBank合约地址
  requestedAmount: 100000000000000000000
}
signature: 0xdc35e1c7b42c6dd6f815afff9944ddb4da96b8cd6cf503c9c90d2017a1b33bc3...
```

### 3. 调用合约方法

在前端或通过脚本调用：

```javascript
// 使用ethers.js调用
await tokenBank.depositWithPermit2(
    amount,           // 存款金额
    nonce,           // 随机数
    deadline,        // 过期时间
    {                // transferDetails
        to: tokenBankAddress,
        requestedAmount: amount
    },
    signature        // Permit2签名
);
```

## 🔍 方法对比

| 方法 | 授权方式 | Gas成本 | 安全性 | 灵活性 |
|------|----------|---------|--------|--------|
| `deposit()` | 需先调用approve | 高 | 基础 | 低 |
| `permitDeposit()` | EIP-2612签名 | 中 | 好 | 中 |
| `depositWithPermit2()` | Permit2签名 | 低 | 最好 | 最高 |

## 📊 完整的方法清单

TokenBank 现在包含以下方法：

### 存款方法
1. **`deposit(uint256 amount)`** - 传统存款（需先approve）
2. **`permitDeposit(...)`** - EIP-2612签名存款
3. **`depositWithPermit2(...)`** - Permit2签名存款 ⭐**推荐**

### 取款方法
4. **`withdraw(uint256 amount)`** - 取款

### 查询方法
5. **`getBalance(address user)`** - 查询用户余额
6. **`getTotalBalance()`** - 查询合约总余额

## 🛠️ 开发工具

### 签名生成工具
- **`scripts/generatePermit2Signature.js`** - Permit2签名生成工具
- 支持自定义参数
- 内置签名验证
- 输出格式化的合约调用参数

### 工具使用方法

```bash
# 1. 安装依赖
npm install ethers

# 2. 修改脚本中的参数
# - userPrivateKey: 用户私钥
# - tokenAddress: Token合约地址
# - tokenBankAddress: TokenBank合约地址
# - amount: 存款金额

# 3. 运行工具
node generatePermit2Signature.js
```

## 🔐 安全考虑

### 签名安全
- **私钥保护**：永远不要泄露私钥
- **nonce唯一性**：每次签名使用不同的nonce
- **时间限制**：设置合理的deadline
- **地址验证**：确保transferDetails中的地址正确

### 合约安全
- **输入验证**：所有参数都有验证
- **防重放攻击**：使用Permit2的nonce机制
- **授权检查**：验证transferDetails的正确性

## 🧪 测试

### 编译测试
```bash
forge build --contracts src/TokenBank.sol
```

### 签名工具测试
```bash
cd scripts && node generatePermit2Signature.js
```

### 合约测试
```bash
forge test --match-contract TokenBank
```

## 📝 注意事项

1. **Permit2部署**：确保目标链上已部署Permit2合约
2. **Token兼容性**：确保Token合约支持标准的transferFrom
3. **签名格式**：使用正确的域分隔符和类型哈希
4. **Gas优化**：Permit2通常比传统方式更节省gas

## 🚀 未来扩展

可以进一步扩展的功能：
- 批量存款功能
- 自动复投功能
- 流式支付集成
- DeFi协议集成

## 📞 支持

如有问题，请检查：
1. 合约地址是否正确
2. 签名参数是否匹配
3. Permit2合约是否在目标链上
4. Token余额和授权是否充足

**TokenBank Permit2 功能现已完全可用！** 🎉 