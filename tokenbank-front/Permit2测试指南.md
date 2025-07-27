# TokenBank Permit2 签名存款测试指南

## 概述

TokenBank 前端现已支持三种存款方式：
1. **传统存款**: 需要先 `approve` 再 `deposit`，消耗两次 gas
2. **EIP-2612 签名存款**: 使用 `permit` 签名，一次交易完成，节省 gas
3. **Permit2 签名存款**: 使用 Permit2 协议，提供更强大的签名授权机制

## 前置条件

### 1. 合约部署要求
确保以下合约已正确部署：

```bash
# 1. 部署支持 EIP-2612 的 Token (BaseERC20)
forge script script/DeployMyToken.s.sol --rpc-url sepolia --broadcast --verify

# 2. 部署 TokenBank (需要包含 permit2Address)
forge script script/TokenBank.s.sol --rpc-url sepolia --broadcast --verify
```

### 2. 前端配置
更新 `tokenbank-front/src/app/page.tsx` 中的合约地址：

```typescript
const TOKENBANK_ADDRESS = "0x你的TokenBank合约地址" as `0x${string}`;
const TOKEN_ADDRESS = "0x你的BaseERC20合约地址" as `0x${string}`;
```

### 3. 用户准备
- 钱包连接到 Sepolia 测试网
- 持有足够的测试 ETH 用于 gas 费用
- 持有一定数量的测试 Token (BAPE)

## 测试步骤

### 步骤 1: 启动前端应用

```bash
cd tokenbank-front
npm install
npm run dev
```

访问 `http://localhost:3000`

### 步骤 2: 连接钱包

1. 点击"连接钱包"按钮
2. 选择 MetaMask 或其他钱包
3. 确认连接到 Sepolia 测试网
4. 确认显示正确的钱包地址和余额

### 步骤 3: 测试传统存款

1. 在"存款到TokenBank"区域选择"传统存款"
2. 输入存款金额（例如：10）
3. 点击"存款"按钮
4. 确认两次交易：
   - 第一次：`approve` 授权
   - 第二次：`deposit` 存款
5. 验证余额变化

### 步骤 4: 测试 EIP-2612 签名存款

1. 选择"EIP-2612"选项
2. 输入存款金额（例如：5）
3. 点击"EIP-2612签名存款"按钮
4. 在钱包中签名（**注意**: 这是签名，不是交易）
5. 确认一次交易：`permitDeposit`
6. 验证余额变化

### 步骤 5: 测试 Permit2 签名存款

1. 选择"Permit2"选项
2. 输入存款金额（例如：8）
3. 点击"Permit2签名存款"按钮
4. 在钱包中签名 Permit2 消息（**注意**: 这是 EIP-712 签名）
5. 确认一次交易：`depositWithPermit2`
6. 验证余额变化

## 预期结果

### 成功指标
- ✅ 所有三种存款方式都能正常工作
- ✅ 余额正确更新（钱包余额减少，银行存款增加）
- ✅ 控制台显示详细的调试信息
- ✅ 签名存款只需要一次交易
- ✅ 不同存款方式显示对应的按钮文本和提示信息

### 性能对比
- **传统存款**: 2 次交易，较高 gas 费用
- **EIP-2612**: 1 次交易 + 1 次签名，节省约 50% gas
- **Permit2**: 1 次交易 + 1 次签名，支持更复杂的授权逻辑

## 调试信息

### 浏览器控制台日志
打开浏览器开发者工具，查看控制台输出：

```
🔧 前端配置信息:
- TOKEN_ADDRESS: 0x4e7C8e2c43aC1d69811D2d00d5AD385dB43899fa
- TOKENBANK_ADDRESS: 0x3B8C8BAEf7f3885159A347B8515AEB8123A76aD5

🚀 开始Permit2签名存款流程
- address: 0x...
- amount: 8000000000000000000
- nonce: 1753627542635123456
- deadline: 1703927542
```

### 常见问题排查

#### 1. "Permit2签名失败"
**可能原因**: 
- Permit2 官方合约未部署到当前网络
- 签名格式不正确
- nonce 冲突

**解决方案**:
```typescript
// 检查 PERMIT2_ADDRESS 是否正确
const PERMIT2_ADDRESS = "0x000000000022D473030F116dDEE9F6B43aC78BA3";
```

#### 2. "无法获取 DOMAIN_SEPARATOR"
**可能原因**: Token 合约不支持 EIP-2612

**解决方案**: 确保使用的是 BaseERC20 合约，不是普通的 ERC20

#### 3. "合约调用失败"
**可能原因**: 
- TokenBank 合约地址不正确
- 合约未包含 `depositWithPermit2` 函数
- 用户余额不足

**解决方案**: 
- 重新部署 TokenBank 合约
- 检查合约地址配置
- 确认用户有足够的 Token 余额

## 技术细节

### Permit2 签名结构
```typescript
domain: {
  name: "Permit2",
  version: "1", 
  chainId: 11155111,
  verifyingContract: "0x000000000022D473030F116dDEE9F6B43aC78BA3"
}

types: {
  PermitTransferFrom: [
    { name: "permitted", type: "TokenPermissions" },
    { name: "nonce", type: "uint256" },
    { name: "deadline", type: "uint256" }
  ],
  TokenPermissions: [
    { name: "token", type: "address" },
    { name: "amount", type: "uint256" }
  ]
}
```

### 合约调用参数
```solidity
function depositWithPermit2(
    uint256 amount,
    uint256 nonce, 
    uint256 deadline,
    SignatureTransferDetails calldata transferDetails,
    bytes calldata signature
) public
```

## 下一步

测试完成后，你可以：
1. 部署到主网（记得更新配置）
2. 添加更多 Token 支持
3. 实现批量存款功能
4. 集成到 DeFi 协议中

---

**注意**: Permit2 是一个强大的工具，但需要用户理解签名的含义。建议在生产环境中添加详细的用户教育和安全提示。 