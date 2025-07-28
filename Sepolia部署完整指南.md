# 🚀 Sepolia完整部署指南

## ✅ **当前状态**

### **已完成**
- ✅ **Permit2部署成功** - `0x769DA7B0919FF7ADe64bc556B2f52b434E11E82c`
- ✅ **配置文件更新** - 前端和脚本已更新地址
- ✅ **脚本权限修复** - 文件写入问题已解决

### **待完成**
- 🔄 **TokenBank部署** - 使用新Permit2地址
- 🔄 **前端地址更新** - 更新TokenBank地址
- 🔄 **端到端测试** - 验证Permit2功能

## 🎯 **第一步：部署TokenBank**

### **设置环境变量**
```bash
export RPC_URL="https://sepolia.infura.io/v3/YOUR_API_KEY"  # 或其他RPC
export PRIVATE_KEY="YOUR_PRIVATE_KEY"
```

### **执行TokenBank部署**
```bash
forge script script/TokenBank.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify --broadcast -vvv
```

**预期输出**：
```
✅ TokenBank address: 0x...
✅ Token address: 0xE265E00480d1d97DAdc98a1DA688e9B016308987
✅ Permit2 address: 0x769DA7B0919FF7ADe64bc556B2f52b434E11E82c
```

## 🎯 **第二步：更新前端配置**

### **更新TokenBank地址**
在 `tokenbank-front/src/app/page.tsx` 中更新：
```javascript
// 第14行左右，更新为新部署的TokenBank地址
const TOKENBANK_ADDRESS = "0x新部署的TokenBank地址" as const;
```

### **验证配置正确性**
前端会自动验证：
- ✅ TokenBank的token地址匹配
- ✅ TokenBank的permit2地址匹配  
- ✅ ChainId正确(11155111)

## 🎯 **第三步：测试Permit2功能**

### **启动前端**
```bash
cd tokenbank-front
npm run dev
```

### **连接MetaMask**
- 网络：Sepolia Testnet
- 账户：有Sepolia ETH和Token的账户

### **测试流程**
1. **传统存款** - 验证基础功能 ✅
2. **EIP-2612存款** - 验证Permit功能 ✅  
3. **Permit2存款** - 重点测试！🎯

## 🧪 **Permit2测试检查项**

### **授权阶段**
- ✅ 显示"需要Permit2授权"
- ✅ 点击授权成功
- ✅ 状态变为"已授权"

### **存款阶段**  
- ✅ 生成正确的nonce (bitmap算法)
- ✅ 签名成功生成
- ✅ 交易提交成功
- ✅ 余额正确更新

### **错误监控**
如果遇到问题，检查控制台日志：
```javascript
// 应该看到详细的调试信息
✅ ChainId验证通过
✅ 合约配置验证通过  
✅ Permit2签名参数正确
✅ 交易hash: 0x...
```

## 🔍 **故障排除**

### **常见问题**

#### **1. TokenBank部署失败**
- 检查RPC URL是否正确
- 确保私钥有足够的Sepolia ETH
- 确认Token地址正确

#### **2. 前端连接问题**
- 确保MetaMask连接到Sepolia
- 刷新页面重新连接
- 检查浏览器控制台错误

#### **3. Permit2签名失败**
- 确认用户有足够的Token余额
- 检查nonce是否正确生成
- 验证签名参数格式

### **调试工具**

#### **Etherscan验证**
- TokenBank: `https://sepolia.etherscan.io/address/0x新地址`
- Permit2: `https://sepolia.etherscan.io/address/0x769DA7B0919FF7ADe64bc556B2f52b434E11E82c`

#### **合约调用测试**
```bash
# 查询TokenBank的permit2地址
cast call 0x新TokenBank地址 "permit2()" --rpc-url $RPC_URL

# 应该返回: 0x769da7b0919ff7ade64bc556b2f52b434e11e82c
```

## 🎉 **成功指标**

当看到以下状态时，表示完全成功：

### **部署成功**
- ✅ TokenBank部署完成
- ✅ 合约验证通过
- ✅ 前端显示正确地址

### **功能成功**
- ✅ 三种存款方式都正常工作
- ✅ Permit2签名存款成功完成
- ✅ 控制台无错误信息
- ✅ 余额正确更新

## 🏆 **最终验证**

### **端到端测试**
1. 打开 `http://localhost:3000`
2. 连接MetaMask (Sepolia网络)
3. 选择"Permit2签名存款"
4. 输入存款金额 (如100)
5. 点击"存款" 
6. **第一次：授权Permit2** ✅
7. **自动进行：签名+存款** ✅
8. **验证余额更新** ✅

**看到余额增加 = 🎉 完全成功！**

---

## 📋 **快速命令总结**

```bash
# 1. 部署TokenBank
export RPC_URL="your_sepolia_rpc"
export PRIVATE_KEY="your_private_key"
forge script script/TokenBank.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --verify --broadcast

# 2. 启动前端
cd tokenbank-front && npm run dev

# 3. 测试Permit2存款
# (在浏览器中操作)
```

现在你有了一个**完全可控的Permit2系统**！

无论是本地调试还是Sepolia测试，都能完美运行！🚀 