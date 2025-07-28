# 🔧 手动测试Permit2授权指南

## 🎯 **目标**
如果自动授权流程卡住，我们手动测试授权功能

## 🚀 **方法1：浏览器控制台手动授权**

### **第1步：打开控制台**
- 按 `F12` 打开开发者工具
- 切换到 `Console` 标签页

### **第2步：手动执行授权**
在控制台粘贴并回车：

```javascript
// 手动授权Permit2合约
(async () => {
  try {
    console.log("🔐 开始手动授权测试...");
    
    // 获取当前连接的账户
    const accounts = await window.ethereum.request({ method: 'eth_accounts' });
    const account = accounts[0];
    console.log("- 当前账户:", account);
    
    // 检查网络
    const chainId = await window.ethereum.request({ method: 'eth_chainId' });
    console.log("- 当前网络:", chainId, "(应该是0x1a54b91 = Sepolia)");
    
    // 构造授权交易
    const tokenAddress = "0x7b661cAc90464E6ca990bb95E66f178ce9F0189F";
    const permit2Address = "0x769DA7B0919FF7ADe64bc556B2f52b434E11E82c";
    const maxAmount = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    
    console.log("- Token合约:", tokenAddress);
    console.log("- Permit2合约:", permit2Address);
    console.log("- 授权金额:", "最大值");
    
    // 发送授权交易
    const txHash = await window.ethereum.request({
      method: 'eth_sendTransaction',
      params: [{
        from: account,
        to: tokenAddress,
        data: `0x095ea7b3${permit2Address.slice(2).padStart(64, '0')}${maxAmount.slice(2)}`
      }]
    });
    
    console.log("✅ 授权交易已发送:", txHash);
    console.log("🔗 查看交易:", `https://sepolia.etherscan.io/tx/${txHash}`);
    
  } catch (error) {
    console.error("❌ 手动授权失败:", error);
    console.error("错误详情:", error.message);
  }
})();
```

### **第3步：等待交易确认**
- 看到交易hash后，等待1-2分钟
- 在Etherscan查看交易状态
- 确认后刷新页面重试

## 🚀 **方法2：使用MetaMask直接调用**

### **在MetaMask中手动发送交易**
1. 打开MetaMask
2. 点击 "发送"
3. 填写信息：
   - **收件人**: `0x7b661cAc90464E6ca990bb95E66f178ce9F0189F` (Token合约)
   - **金额**: `0` ETH
   - **数据**: 
   ```
   0x095ea7b3000000000000000000000000769da7b0919ff7ade64bc556b2f52b434e11e82cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
   ```

4. 发送交易
5. 等待确认
6. 刷新页面重试

## 🔍 **验证授权是否成功**

### **在控制台检查授权状态**
```javascript
// 检查授权状态
(async () => {
  const tokenAddress = "0x7b661cAc90464E6ca990bb95E66f178ce9F0189F";
  const permit2Address = "0x769DA7B0919FF7ADe64bc556B2f52b434E11E82c";
  const userAddress = "你的钱包地址";
  
  const allowance = await window.ethereum.request({
    method: 'eth_call',
    params: [{
      to: tokenAddress,
      data: `0xdd62ed3e${userAddress.slice(2).padStart(64, '0')}${permit2Address.slice(2).padStart(64, '0')}`
    }, 'latest']
  });
  
  console.log("🔍 当前授权额度:", allowance);
  console.log("✅ 授权成功:", allowance !== "0x0000000000000000000000000000000000000000000000000000000000000000");
})();
```

## 🎯 **成功标志**
当看到：
- ✅ 交易hash显示
- ✅ Etherscan显示交易成功
- ✅ 授权额度 > 0
- ✅ 页面刷新后不再显示"未授权"

**表示授权成功！可以正常使用Permit2存款了！** 🎉 