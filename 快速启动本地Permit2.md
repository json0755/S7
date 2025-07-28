# 🚀 快速启动本地Permit2

## ✅ **合约已就绪**
- ✅ Permit2合约 - 完全实现
- ✅ TokenBank合约 - 支持Permit2存款
- ✅ BaseERC20合约 - 包含mint功能
- ✅ 所有测试通过

## 🏃‍♂️ **3分钟快速启动**

### **第1步：启动本地链**
```bash
# 在终端1中启动Anvil
anvil
```
**重要**：保留这个终端窗口开启！

### **第2步：部署合约**
```bash
# 在终端2中运行部署脚本
./scripts/deploy-local.sh
```

### **第3步：获取部署地址**
脚本会自动生成 `tokenbank-front-config.js`，包含：
```javascript
const TOKEN_ADDRESS = "0x...";
const PERMIT2_ADDRESS = "0x...";  
const TOKENBANK_ADDRESS = "0x...";
```

### **第4步：更新前端**
将这些地址复制到：`tokenbank-front/src/app/page.tsx`

### **第5步：配置MetaMask**
- 网络名: `Local Anvil`
- RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`

导入测试账户：
```
私钥: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### **第6步：启动前端测试**
```bash
cd tokenbank-front
npm run dev
```

## 🧪 **测试验证**

### **合约测试**
```bash
# 运行Permit2测试
forge test --match-contract LocalPermit2Test -vv

# 应该显示：5 tests passed
```

### **前端测试**
1. 访问 `http://localhost:3000`
2. 连接MetaMask到本地网络
3. 测试三种存款方式：
   - ✅ 传统存款
   - ✅ EIP-2612存款
   - ✅ **Permit2存款** ← 重点测试

## 🔍 **如果遇到问题**

### **编译错误**
```bash
forge build
# 应该显示：Compiler run successful
```

### **网络连接**
- 确保Anvil正在运行
- 检查MetaMask网络设置
- 重启浏览器

### **重新开始**
```bash
# 停止Anvil (Ctrl+C)
# 重新启动
anvil

# 重新部署
./scripts/deploy-local.sh
```

## 🎯 **成功标志**

当你看到：
- ✅ 所有合约测试通过
- ✅ 前端显示正确余额
- ✅ Permit2存款成功完成
- ✅ 控制台无错误信息

**恭喜！你已经成功运行本地Permit2系统！**

---

**💡 提示**：本地环境是调试的完美场所，你可以：
- 快速测试修改
- 查看详细错误信息
- 零费用测试交易
- 完全控制所有参数

现在你可以安全地调试和完善Permit2功能了！🎉 