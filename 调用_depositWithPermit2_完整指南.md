# 调用 depositWithPermit2() 完整指南

## 🎯 前置准备

### 1. 生成 Permit2 签名

首先，你需要生成签名参数：

```bash
# 进入scripts目录
cd scripts

# 修改 generatePermit2Signature.js 中的参数：
# - userPrivateKey: 你的私钥
# - tokenBankAddress: 部署的TokenBank合约地址
# - tokenAddress: Token合约地址

# 生成签名
node generatePermit2Signature.js
```

**输出示例：**
```
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

**保存这些参数，后续调用时需要使用！**

## 🚀 调用方法

### 方法1: JavaScript/ethers.js 调用

适用于前端应用或Node.js脚本。

```bash
# 修改 scripts/callDepositWithPermit2.js 中的参数：
# - userPrivateKey: 你的私钥
# - tokenBankAddress: TokenBank合约地址
# - rpcUrl: RPC端点

# 执行调用
cd scripts
node callDepositWithPermit2.js
```

**特点：**
- ✅ 完整的交易流程
- ✅ 自动生成签名
- ✅ 交易状态监控
- ✅ 余额对比

### 方法2: Forge Cast 命令行调用

适用于快速测试和命令行操作。

```bash
# 1. 修改 scripts/call_depositWithPermit2.sh 中的参数：
# - TOKEN_BANK_ADDRESS: TokenBank合约地址
# - USER_PRIVATE_KEY: 你的私钥  
# - RPC_URL: RPC端点
# - SIGNATURE: 从步骤1获得的签名

# 2. 执行脚本
./scripts/call_depositWithPermit2.sh
```

**或者直接使用cast命令：**
```bash
# 调用 depositWithPermit2
cast send 0x你的TokenBank合约地址 \
    "depositWithPermit2(uint256,uint256,uint256,(address,uint256),bytes)" \
    100000000000000000000 \
    1753626377635974742 \
    1753712777 \
    "(0x你的TokenBank合约地址,100000000000000000000)" \
    0x你的签名 \
    --private-key 0x你的私钥 \
    --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID
```

### 方法3: Forge Script 调用

适用于复杂的合约交互和批量操作。

```bash
# 1. 修改 script/CallDepositWithPermit2.s.sol 中的参数：
# - TOKEN_BANK_ADDRESS: TokenBank合约地址
# - USER_ADDRESS: 用户地址
# - NONCE, DEADLINE, SIGNATURE: 从步骤1获得

# 2. 执行脚本
forge script script/CallDepositWithPermit2.s.sol --broadcast --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --private-key 0x你的私钥
```

### 方法4: 前端直接调用

在前端应用中使用：

```javascript
// 前端调用示例 (React + ethers.js)
import { ethers } from 'ethers';

async function callDepositWithPermit2() {
    // 从签名工具获得的参数
    const amount = "100000000000000000000";
    const nonce = "1753626377635974742";
    const deadline = "1753712777";
    const signature = "0x...";
    
    const transferDetails = {
        to: "0x你的TokenBank合约地址",
        requestedAmount: amount
    };
    
    // 连接到合约
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const tokenBank = new ethers.Contract(
        "0x你的TokenBank合约地址",
        ["function depositWithPermit2(uint256,uint256,uint256,(address,uint256),bytes)"],
        signer
    );
    
    // 调用方法
    const tx = await tokenBank.depositWithPermit2(
        amount,
        nonce,
        deadline,
        transferDetails,
        signature
    );
    
    console.log("交易哈希:", tx.hash);
    await tx.wait();
    console.log("交易完成!");
}
```

## 📋 参数说明

### 必需参数

| 参数 | 类型 | 描述 | 示例 |
|------|------|------|------|
| `amount` | uint256 | 存款金额(wei) | `100000000000000000000` (100 tokens) |
| `nonce` | uint256 | 防重放随机数 | `1753626377635974742` |
| `deadline` | uint256 | 签名过期时间戳 | `1753712777` |
| `transferDetails` | struct | 转账详情 | `{to: "0x...", requestedAmount: "100..."}` |
| `signature` | bytes | Permit2签名 | `0x1b547caec...` |

### transferDetails 结构体

```solidity
struct SignatureTransferDetails {
    address to;                // 接收方地址 (TokenBank合约地址)
    uint256 requestedAmount;   // 请求转移的金额 (必须等于amount)
}
```

## ⚠️ 重要注意事项

### 1. 参数验证
- `transferDetails.to` 必须是 TokenBank 合约地址
- `transferDetails.requestedAmount` 必须等于 `amount`
- `deadline` 必须是未来时间
- `nonce` 每次使用必须不同

### 2. 签名安全
- **私钥保护**：永远不要公开私钥
- **签名有效期**：及时使用签名，避免过期
- **防重放**：每次使用新的nonce

### 3. 网络配置
确保所有调用使用相同的网络：
- **Sepolia Testnet**: Chain ID 11155111
- **Ethereum Mainnet**: Chain ID 1
- **Permit2地址**: `0x000000000022D473030F116dDEE9F6B43aC78BA3` (所有网络通用)

## 🧪 测试流程

### 完整测试步骤

```bash
# 1. 编译合约
forge build

# 2. 部署TokenBank
forge script script/TokenBank.s.sol --broadcast --rpc-url <RPC_URL>

# 3. 生成签名
cd scripts && node generatePermit2Signature.js

# 4. 调用方法 (选择以下任一方式)
# 方式A: JavaScript
node callDepositWithPermit2.js

# 方式B: Shell脚本  
./call_depositWithPermit2.sh

# 方式C: Forge script
forge script script/CallDepositWithPermit2.s.sol --broadcast --rpc-url <RPC_URL>

# 方式D: Cast命令
cast send <CONTRACT> "depositWithPermit2(...)" <PARAMS> --private-key <KEY> --rpc-url <RPC>
```

## 🔍 故障排除

### 常见错误及解决方案

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| "Invalid signature" | 签名错误或参数不匹配 | 重新生成签名，检查参数 |
| "Signature already used" | nonce重复使用 | 使用新的nonce |
| "接收地址必须是本合约" | transferDetails.to错误 | 使用TokenBank合约地址 |
| "转账金额必须匹配" | amount不等于requestedAmount | 确保两个金额相同 |
| "Permit2 transfer failed" | Token余额不足或Permit2未授权 | 检查Token余额和Permit2状态 |

### 调试技巧

```bash
# 检查TokenBank余额
cast call 0xTokenBank地址 "getBalance(address)(uint256)" 0x用户地址 --rpc-url <RPC>

# 检查Token余额
cast call 0xToken地址 "balanceOf(address)(uint256)" 0x用户地址 --rpc-url <RPC>

# 查看交易详情
cast receipt 0x交易哈希 --rpc-url <RPC>
```

## 🎉 成功示例

**成功调用后的输出：**
```
🚀 开始调用 depositWithPermit2...
用户地址: 0x1Be31A94361a391bBaFB2a4CCd704F57dc04d4bb
存款金额: 100.0 tokens
📝 生成 Permit2 签名...
✅ 签名生成成功!
📊 存款前余额: 0.0 tokens
💰 执行 depositWithPermit2...
交易哈希: 0x1234567890abcdef...
⏳ 等待交易确认...
✅ 交易确认成功!
📊 存款后余额: 100.0 tokens
存款增加: 100.0 tokens
🎉 depositWithPermit2 调用成功!
```

现在你有了完整的调用 `depositWithPermit2()` 方法的指南！🚀 