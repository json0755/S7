# Permit2签名存款故障诊断指南

## 🚨 第一步失败 - 快速诊断

当Permit2签名存款第一步就失败时，按以下顺序检查：

### 1. 检查合约配置状态

在前端界面查看"🔧 合约配置"区域：

```
TOKEN: 0xe9D0a28F...545F9
TOKENBANK: 0x4fDEeB0A...6B4DE  
PERMIT2: 0x00000000...C78BA3
余额: [你的余额] BAPE | 授权: ✅/❌
DOMAIN_SEPARATOR: ✅/❌ | Nonces: ✅/❌ | Bitmap: [数字]
```

### 2. 检查浏览器控制台日志

**打开开发者工具 → Console**，查看详细日志：

#### 正常的日志应该是：
```
🚀 开始Permit2签名存款流程
🔍 授权检查:
- 需要金额: 10000000000000000000
- 授权金额: 0
- 授权是否足够: false
⚠️ 授权不足，开始授权流程
🔐 开始授权Permit2合约...
🔍 授权参数检查:
- 用户地址: 0x...
- Token地址: 0xe9D0a28F919579252A6E08d6C933baa84BE545F9
- Permit2地址: 0x000000000022D473030F116dDEE9F6B43aC78BA3
- 用户Token余额: 1000000000000000000000
- 当前授权额度: 0
💰 执行approve交易...
✅ approve交易已提交
```

#### 如果看到错误日志：
```
❌ Permit2授权失败: [错误信息]
❌ 错误详情: [详细信息]
```

### 3. 常见问题及解决方案

#### 问题1: "Token余额为0，无法进行授权"
**原因**: 你的钱包没有BAPE Token
**解决**: 
1. 确认钱包连接正确
2. 从合约部署者获取一些测试Token
3. 或者重新部署Token并mint给自己

#### 问题2: "execution reverted"
**原因**: Token合约地址错误或不支持EIP-2612
**解决**:
1. 确认TOKEN_ADDRESS是否正确
2. 确认是否部署的EIP2612Token而不是普通ERC20
3. 在Etherscan查看合约是否有`approve`函数

#### 问题3: "insufficient funds for gas"
**原因**: ETH余额不足
**解决**: 获取更多Sepolia测试ETH

#### 问题4: "User rejected the request"
**原因**: 用户在MetaMask中拒绝了交易
**解决**: 重新尝试并确认交易

#### 问题5: DOMAIN_SEPARATOR显示❌
**原因**: Token合约不支持EIP-2612
**解决**: 确认使用的是EIP2612Token合约

### 4. 验证Token合约

在Etherscan上查看你的Token合约，确认有以下函数：
- ✅ `approve(address,uint256)`
- ✅ `DOMAIN_SEPARATOR()` 
- ✅ `nonces(address)`
- ✅ `permit(address,address,uint256,uint256,uint8,bytes32,bytes32)`

### 5. 手动测试授权

如果自动授权失败，可以手动测试：

1. **在Etherscan上直接调用approve**：
   - 去 `https://sepolia.etherscan.io/address/[你的TOKEN_ADDRESS]#writeContract`
   - 连接钱包
   - 调用 `approve`
   - spender: `0x000000000022D473030F116dDEE9F6B43aC78BA3`
   - amount: `115792089237316195423570985008687907853269984665640564039457584007913129639935`

2. **检查授权是否生效**：
   - 去 `#readContract`
   - 调用 `allowance`
   - owner: [你的钱包地址]
   - spender: `0x000000000022D473030F116dDEE9F6B43aC78BA3`

### 6. 重新部署合约（最后手段）

如果确认Token合约有问题：

```bash
# 重新部署EIP2612Token
forge script script/DeployEIP2612Token.s.sol --rpc-url sepolia --broadcast --verify

# 重新部署TokenBank
forge script script/TokenBank.s.sol --rpc-url sepolia --broadcast --verify

# 更新前端地址配置
```

### 7. 获取帮助

如果以上步骤都无法解决，请提供：
1. 完整的浏览器控制台日志
2. 你的TOKEN_ADDRESS和TOKENBANK_ADDRESS
3. 你的钱包地址
4. 错误截图

---

## 🔧 快速检查清单

- [ ] 钱包有BAPE Token余额 > 0
- [ ] 钱包有ETH余额用于gas
- [ ] TOKEN_ADDRESS正确且支持EIP-2612
- [ ] PERMIT2_ADDRESS是官方地址
- [ ] 网络是Sepolia测试网
- [ ] MetaMask没有pending交易阻塞
- [ ] DOMAIN_SEPARATOR查询成功
- [ ] Nonces查询成功

如果所有项目都打✅，但仍然失败，问题可能在合约实现层面。 