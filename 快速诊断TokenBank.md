# 🔧 快速诊断TokenBank配置

## 🎯 **检查TokenBank配置**

### **方法1：使用你的RPC**
```bash
export RPC_URL="YOUR_SEPOLIA_RPC_URL"

# 检查TokenBank的token地址
cast call 0x1301D57eF3763fdd2DFd7f7e8684d718A4698fD0 "token()" --rpc-url $RPC_URL

# 检查TokenBank的permit2地址  
cast call 0x1301D57eF3763fdd2DFd7f7e8684d718A4698fD0 "permit2()" --rpc-url $RPC_URL
```

**预期返回：**
```
token(): 0x0000000000000000000000007b661cac90464e6ca990bb95e66f178ce9f0189f
permit2(): 0x000000000000000000000000769da7b0919ff7ade64bc556b2f52b434e11e82c
```

### **方法2：在Etherscan上查看**
1. 打开：https://sepolia.etherscan.io/address/0x1301D57eF3763fdd2DFd7f7e8684d718A4698fD0#readContract
2. 点击 "Read Contract"
3. 查看 `token()` 和 `permit2()` 的返回值

## 🚨 **如果地址不匹配**

### **立即重新部署TokenBank：**
```bash
export RPC_URL="YOUR_RPC_URL"
export PRIVATE_KEY="YOUR_PRIVATE_KEY"

forge script script/TokenBank.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify --broadcast -vvv
```

### **然后更新前端：**
```javascript
// 在 tokenbank-front/src/app/page.tsx 第11行
const TOKENBANK_ADDRESS = "0x新TokenBank地址" as `0x${string}`;
```

## 🎯 **快速判断**

### **如果 Etherscan 交易显示：**

**❌ "execution reverted"**
- 很可能是合约配置问题
- 需要重新部署TokenBank

**❌ "invalid signature"**  
- 签名格式问题
- 需要检查前端签名逻辑

**❌ "insufficient allowance"**
- 授权问题
- 需要重新授权或检查授权状态

**❌ "wrong address" 或类似**
- 地址不匹配
- 必须重新部署TokenBank

## 🚀 **快速解决路径**

### **最快的解决方案：**
1. **查看Etherscan错误** (2分钟)
2. **重新部署TokenBank** (3分钟) 
3. **更新前端地址** (1分钟)
4. **重新测试** (2分钟)

**总共8分钟就能解决！** 🎉 