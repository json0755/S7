# 本地Permit2部署使用指南

## 🎯 **概述**

这个指南将帮你在本地环境部署和测试自定义的Permit2合约，解决在Sepolia网络上遇到的`Execution reverted`问题。

## 📋 **准备工作**

### 1. **环境要求**
- ✅ Foundry (forge, anvil)
- ✅ Node.js 和 npm/yarn
- ✅ MetaMask浏览器插件

### 2. **检查工具安装**
```bash
# 检查Foundry
forge --version
anvil --version

# 检查Node.js
node --version
npm --version
```

## 🚀 **快速部署**

### **步骤1：启动本地区块链**
```bash
# 启动Anvil本地节点
anvil

# 输出示例：
# Available Accounts
# (0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
# (1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
# ...
# Private Keys
# (0) 
# ...
```

**保持终端开启，记住账户地址和私钥！**

### **步骤2：运行自动部署脚本**
```bash
# 在新终端中运行部署脚本
./scripts/deploy-local.sh
```

**脚本将自动：**
1. ✅ 检查网络连接
2. ✅ 编译所有合约
3. ✅ 运行Permit2测试
4. ✅ 部署 EIP2612Token、Permit2、TokenBank
5. ✅ Mint测试tokens
6. ✅ 生成前端配置文件

### **步骤3：查看部署结果**
```bash
# 查看详细部署信息
cat deployments/local-deployment.txt

# 查看前端配置
cat tokenbank-front-config.js
```

## 🔧 **手动部署（如果自动脚本失败）**

### **1. 编译合约**
```bash
forge build
```

### **2. 运行测试**
```bash
# 测试本地Permit2功能
forge test --match-contract LocalPermit2Test -vv

# 预期输出：所有测试PASS
```

### **3. 部署合约**
```bash
# 部署所有合约
forge script script/DeployAllLocal.s.sol \
    --rpc-url http://127.0.0.1:8545 \
    --private-key  \
    --broadcast
```

### **4. Mint测试tokens**
```bash
# 使用环境变量mint tokens
TOKEN_ADDRESS=<部署的Token地址> \
RECIPIENT_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
MINT_AMOUNT=10000000000000000000000 \
forge script script/MintTokens.s.sol \
    --rpc-url http://127.0.0.1:8545 \
    --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --broadcast
```

## 🌐 **前端配置**

### **1. 更新合约地址**
打开 `tokenbank-front/src/app/page.tsx`，将地址替换为本地部署的地址：

```typescript
// 从 tokenbank-front-config.js 复制这些地址
const TOKEN_ADDRESS = "0x...";  // 本地EIP2612Token地址
const PERMIT2_ADDRESS = "0x...";  // 本地Permit2地址
const TOKENBANK_ADDRESS = "0x...";  // 本地TokenBank地址
```

### **2. 更新Chain ID**
```typescript
// 在 tokenbank-front/src/app/page.tsx 中
const domain = {
  name: LOCAL_PERMIT2_DOMAIN_NAME,
  version: LOCAL_PERMIT2_DOMAIN_VERSION,
  chainId: 31337, // 本地链ID 
  verifyingContract: PERMIT2_ADDRESS,
};
```

### **3. 可选：使用本地Permit2 ABI**
```typescript
// 引入本地Permit2 ABI（如果需要额外功能）
import { localPermit2Abi, LOCAL_PERMIT2_DOMAIN_NAME, LOCAL_PERMIT2_DOMAIN_VERSION } from "../../abi/LocalPermit2";
```

## 💰 **MetaMask配置**

### **1. 添加本地网络**
- 网络名称: `Local Anvil`
- RPC URL: `http://127.0.0.1:8545`
- 链ID: `31337`
- 货币符号: `ETH`

### **2. 导入测试账户**
使用Anvil提供的私钥导入账户：
```
私钥: 
地址: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### **3. 确认余额**
- ETH余额: 10000 ETH（来自Anvil）
- BAPE余额: 10000 BAPE（来自mint脚本）

## 🧪 **测试流程**

### **1. 启动前端**
```bash
cd tokenbank-front
npm run dev
# 访问 http://localhost:3000
```

### **2. 连接MetaMask**
1. 切换到`Local Anvil`网络
2. 连接钱包
3. 确认显示正确的余额

### **3. 测试三种存款方式**

#### **传统存款**
1. 选择"传统存款"
2. 输入金额(如100)
3. 点击存款
4. 确认MetaMask交易

#### **EIP-2612存款**
1. 选择"EIP-2612"
2. 输入金额(如200)
3. 点击存款
4. 签名permit消息
5. 确认存款交易

#### **Permit2存款**
1. 选择"Permit2签名存款"
2. 输入金额(如300)
3. 点击存款
4. 如果是第一次，先授权Permit2
5. 签名Permit2消息
6. 确认存款交易

### **4. 验证结果**
每次存款后检查：
- ✅ Token余额减少
- ✅ 银行余额增加
- ✅ 总余额保持不变
- ✅ 控制台无错误

## 🔍 **调试工具**

### **1. 查看合约状态**
```bash
# 查看Token余额
cast call <TOKEN_ADDRESS> "balanceOf(address)" <USER_ADDRESS> --rpc-url http://127.0.0.1:8545

# 查看银行余额
cast call <TOKENBANK_ADDRESS> "getBalance(address)" <USER_ADDRESS> --rpc-url http://127.0.0.1:8545

# 查看Permit2授权
cast call <TOKEN_ADDRESS> "allowance(address,address)" <USER_ADDRESS> <PERMIT2_ADDRESS> --rpc-url http://127.0.0.1:8545

# 查看nonce状态
cast call <PERMIT2_ADDRESS> "isNonceUsed(address,uint256)" <USER_ADDRESS> <NONCE> --rpc-url http://127.0.0.1:8545
```

### **2. 前端调试**
- 打开浏览器开发者工具
- 查看Console标签
- 寻找以下调试信息：
  - `🔍 ChainId验证`
  - `🔍 验证合约配置`
  - `🔢 生成Permit2 nonce`
  - `📝 Permit2签名数据`

### **3. 重新部署**
如果遇到问题，重新部署：
```bash
# 重启Anvil（这会清除所有状态）
# Ctrl+C 停止Anvil，然后重新运行
anvil

# 重新部署
./scripts/deploy-local.sh
```

## 🚨 **常见问题解决**

### **问题1：网络连接失败**
```
❌ 无法连接到本地网络
```
**解决方案：**
- 确保Anvil正在运行
- 检查RPC URL: `http://127.0.0.1:8545`
- 尝试重启Anvil

### **问题2：MetaMask无法连接**
```
❌ MetaMask显示网络错误
```
**解决方案：**
- 在MetaMask中手动添加本地网络
- 确认Chain ID是31337
- 重置MetaMask账户（Settings > Advanced > Reset Account）

### **问题3：Token余额为0**
```
❌ 前端显示Token余额为0
```
**解决方案：**
- 检查是否运行了mint脚本
- 确认使用的是正确的账户地址
- 手动mint tokens

### **问题4：签名失败**
```
❌ Permit2签名验证失败
```
**解决方案：**
- 确认Chain ID匹配(31337)
- 检查合约地址是否正确
- 查看控制台的签名数据

## 🎯 **成功标志**

当你看到以下情况时，表示本地Permit2部署成功：

✅ **合约部署**
- 所有合约地址有效
- 测试全部通过

✅ **前端连接**
- MetaMask成功连接本地网络
- 显示正确的Token和ETH余额
- 合约配置状态全部显示绿色✅

✅ **存款功能**
- 三种存款方式都能成功
- 余额正确更新
- 控制台无错误信息

✅ **Permit2特性**
- Nonce正确管理
- 签名验证通过
- 重放攻击被阻止

## 📚 **下一步**

本地测试成功后，你可以：

1. **理解问题原因**：对比本地和Sepolia的差异
2. **修复Sepolia问题**：将本地的修复应用到Sepolia
3. **部署到其他网络**：使用相同方法部署到其他测试网
4. **生产环境准备**：为主网部署做准备

## 🔗 **相关文件**

- `src/Permit2.sol` - 本地Permit2合约
- `script/DeployAllLocal.s.sol` - 完整部署脚本
- `test/LocalPermit2.t.sol` - Permit2测试
- `scripts/deploy-local.sh` - 自动部署脚本
- `tokenbank-front/abi/LocalPermit2.ts` - 本地Permit2 ABI
- `deployments/local-deployment.txt` - 部署信息记录

---

**🎉 恭喜！你现在有了一个完全可控的本地Permit2环境，可以安全地测试和调试所有功能！** 