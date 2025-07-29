# TokenBank 部署脚本说明

## 脚本文件

1. **DeployTokenBank.s.sol** - 部署到测试网（Sepolia）
2. **DeployTokenBankLocal.s.sol** - 本地测试部署（同时部署测试代币）

## 环境变量设置

在部署前，需要设置以下环境变量：

```bash
export PRIVATE_KEY="your_private_key_here"
export RPC_URL="your_rpc_url_here"
```

## 部署命令

### 1. 部署到 Sepolia（使用已部署的EIP2612Token）

```bash
forge script script/DeployTokenBank.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### 2. 本地测试部署（同时部署测试代币）

```bash
forge script script/DeployTokenBankLocal.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## 合约参数

- **TokenBank 构造函数**：
  - `_asset`: ERC20 代币地址
  - `_permit2`: Permit2 合约地址（Sepolia: 0x000000000022D473030F116dDEE9F6B43aC78BA3）

## 功能说明

TokenBank 合约提供以下主要功能：

1. **permitDeposit** - 使用原生 EIP-2612 permit 进行存款
2. **permitDeposit2** - 使用 Permit2 进行存款
3. **getPermit2Address** - 获取 Permit2 合约地址
4. **getPermit2Allowance** - 检查 Permit2 授权状态

## 注意事项

- 确保代币支持 EIP-2612 permit 功能
- Permit2 地址在不同网络上是相同的
- 部署后记得保存合约地址用于前端集成 