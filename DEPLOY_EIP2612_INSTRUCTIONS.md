# TokenBank前端配置EIP2612Token指南

## 问题背景

原先的TokenBank前端使用MyToken（基于ERC1363），该token不支持EIP-2612 permit功能，导致签名存款功能无法正常工作。

## 解决方案

已将前端切换为使用支持EIP-2612 permit功能的EIP2612Token。

## 部署步骤

### 1. 部署EIP2612Token合约

```bash
# 方式1: 使用Foundry部署
forge script script/DeployEIP2612Token.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# 方式2: 使用Remix部署
# 将src/07-25/EIP2612Token.sol拷贝到Remix
# 构造函数参数：
# - name: "BapeToken"
# - symbol: "BAPE"  
# - initialSupply: 10000
# - tokenDecimals: 18
# - supplyCap: 0
```

### 2. 更新前端配置

部署完成后，需要更新前端配置中的TOKEN_ADDRESS：

**文件: tokenbank-front/src/app/page.tsx**

```typescript
// 将此行的地址替换为新部署的EIP2612Token地址
const TOKEN_ADDRESS = "0x新部署的EIP2612Token地址" as `0x${string}`;
```

### 3. 重新部署TokenBank（可选）

如果需要重新部署TokenBank合约以使用新的token：

```bash
forge script script/TokenBank.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

然后更新前端的TOKENBANK_ADDRESS。

## 文件变更说明

### 已完成的更改：

1. **script/DeployEIP2612Token.s.sol** - 新增EIP2612Token部署脚本
2. **tokenbank-front/abi/MyToken.ts** - 更新为EIP2612Token的完整ABI
3. **tokenbank-front/abi/TokenBank.ts** - 添加permitDeposit方法
4. **tokenbank-front/src/app/page.tsx** - 完整的签名存款功能实现

### 功能特性：

- ✅ 传统存款（approve + deposit）
- ✅ 签名存款（一键permit存款）
- ✅ 取款功能
- ✅ 余额显示
- ✅ 错误处理和调试信息

## 测试步骤

1. 部署EIP2612Token合约
2. 更新TOKEN_ADDRESS
3. 启动前端：`npm run dev`
4. 连接钱包
5. 测试签名存款功能

## 调试信息

前端已添加详细的控制台日志输出，在浏览器开发者工具中可以查看：
- 签名参数
- nonce值
- domain信息
- 错误详情

这有助于排查签名存款过程中的问题。

## 注意事项

1. 确保钱包中有足够的ETH支付gas费用
2. 确保钱包连接到Sepolia测试网
3. EIP2612Token支持mint功能，可以为测试账户铸造token
4. 签名存款需要用户在钱包中确认签名操作 