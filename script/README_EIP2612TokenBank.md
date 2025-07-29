# EIP2612TokenBank 部署脚本说明

## 概述

本项目包含三个EIP2612TokenBank部署脚本，用于不同场景的部署需求。

## 部署脚本

### 1. DeployEIP2612TokenBank.s.sol
**完整版部署脚本** - 用于Sepolia测试网部署
- 使用已部署的EIP2612Token合约
- 包含详细的验证和配置检查
- 输出完整的配置信息

**使用方法:**
```bash
forge script script/DeployEIP2612TokenBank.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### 2. DeployEIP2612TokenBankSimple.s.sol
**简化版部署脚本** - 快速部署
- 最小化的部署流程
- 适合快速测试和部署

**使用方法:**
```bash
forge script script/DeployEIP2612TokenBankSimple.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast
```

### 3. DeployEIP2612TokenBankLocal.s.sol
**本地测试脚本** - 用于本地开发和测试
- 同时部署EIP2612Token和EIP2612TokenBank
- 完整的本地测试环境

**使用方法:**
```bash
# 本地测试
forge script script/DeployEIP2612TokenBankLocal.s.sol --fork-url $SEPOLIA_RPC_URL

# 或使用本地节点
anvil
forge script script/DeployEIP2612TokenBankLocal.s.sol --rpc-url http://localhost:8545 --broadcast
```

## 合约配置

### EIP2612TokenBank 参数
- **Asset**: EIP2612Token合约地址
- **Name**: "BapeToken Vault"
- **Symbol**: "bBAPE"
- **Decimals**: 18 (继承自ERC4626)

### 支持的Token
- EIP2612Token: `0x05a1ecCcaF01F6898863696832Fdfef90077D1BC`

### Permit2地址
- Sepolia: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

## 部署后验证

部署完成后，脚本会自动验证以下配置：

1. **Asset地址匹配**: `tokenBank.asset() == tokenAddress`
2. **Token支持**: `tokenBank.isTokenSupported(tokenAddress)`
3. **名称匹配**: `tokenBank.name() == "BapeToken Vault"`
4. **符号匹配**: `tokenBank.symbol() == "bBAPE"`

## 前端配置

部署成功后，脚本会输出前端需要的配置信息：

```javascript
const CONTRACTS = {
    EIP2612_TOKEN: "0x05a1ecCcaF01F6898863696832Fdfef90077D1BC",
    EIP2612_TOKEN_BANK: "部署的TokenBank地址",
    PERMIT2: "0x000000000022D473030F116dDEE9F6B43aC78BA3"
};
```

## 注意事项

1. **权限**: 确保部署账户有足够的ETH支付gas费用
2. **网络**: 确保连接到正确的网络（Sepolia测试网）
3. **验证**: 部署后建议在区块浏览器上验证合约
4. **测试**: 部署后建议运行测试脚本验证功能

## 故障排除

### 常见错误
1. **Gas不足**: 确保账户有足够的ETH
2. **网络错误**: 检查RPC URL是否正确
3. **合约验证失败**: 检查合约参数是否正确

### 调试命令
```bash
# 检查合约编译
forge build

# 运行测试
forge test

# 查看合约大小
forge build --sizes
``` 