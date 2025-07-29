import { ethers } from 'ethers';

// 错误代码
const errorCode = '0xb0669cbc';

// 常见的错误选择器
const commonErrors = {
  '0x4e487b71': 'Panic(uint256)',
  '0x08c379a0': 'Error(string)',
  '0xb0669cbc': 'Custom Error - 需要检查合约源码'
};

console.log('🔍 错误分析:');
console.log(`错误代码: ${errorCode}`);
console.log(`选择器: ${errorCode.slice(0, 10)}`);

if (commonErrors[errorCode.slice(0, 10)]) {
  console.log(`错误类型: ${commonErrors[errorCode.slice(0, 10)]}`);
} else {
  console.log('❓ 未知错误类型');
}

// 检查是否是 Permit2 相关错误
console.log('\n📋 可能的错误原因:');
console.log('1. Token 未在 TokenBank 中注册为支持的代币');
console.log('2. Permit2 签名验证失败');
console.log('3. Nonce 已被使用');
console.log('4. Deadline 已过期');
console.log('5. 签名者不是 msg.sender');

// 检查合约状态
const NETWORK_CONFIG = {
  rpc: 'https://eth-sepolia.api.onfinality.io/public',
  chainId: 11155111
};

const CONTRACTS = {
  EIP2612_TOKEN: '0x05a1ecCcaF01F6898863696832Fdfef90077D1BC',
  TOKEN_BANK: '0x8D3eB6eDAE5d6A44eDa750e29f3Ae63bAe97Ce8e',
  PERMIT2: '0x000000000022D473030F116dDEE9F6B43aC78BA3'
};

async function checkContractState() {
  console.log('\n🔍 检查合约状态...');
  
  try {
    const provider = new ethers.JsonRpcProvider(NETWORK_CONFIG.rpc);
    
    // 检查 Token 是否在 TokenBank 中注册
    const tokenBankABI = [
      'function isTokenSupported(address token) external view returns (bool)',
      'function supportedTokens(address token) external view returns (bool)'
    ];
    
    const tokenBank = new ethers.Contract(CONTRACTS.TOKEN_BANK, tokenBankABI, provider);
    
    try {
      const isSupported = await tokenBank.isTokenSupported(CONTRACTS.EIP2612_TOKEN);
      console.log(`✅ Token 支持状态: ${isSupported}`);
      
      if (!isSupported) {
        console.log('❌ Token 未在 TokenBank 中注册！这是错误的根本原因。');
        console.log('💡 解决方案: 需要调用 addSupportedToken() 函数注册 Token');
      }
    } catch (error) {
      console.log(`❌ 检查 Token 支持状态失败: ${error.message}`);
    }
    
  } catch (error) {
    console.log(`❌ 网络连接失败: ${error.message}`);
  }
}

checkContractState(); 