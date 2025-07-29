import { ethers } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

const NETWORK_CONFIG = {
  rpc: 'https://eth-sepolia.api.onfinality.io/public',
  chainId: 11155111
};

const CONTRACTS = {
  EIP2612_TOKEN: '0x05a1ecCcaF01F6898863696832Fdfef90077D1BC',
  TOKEN_BANK: '0x8D3eB6eDAE5d6A44eDa750e29f3Ae63bAe97Ce8e',
  PERMIT2: '0x000000000022D473030F116dDEE9F6B43aC78BA3'
};

const TEST_CONFIG = {
  privateKey: process.env.PRIVATE_KEY || '0x1234567890123456789012345678901234567890123456789012345678901234',
  gasLimit: 500000,
  gasPrice: 20000000000 // 20 gwei
};

async function registerToken() {
  console.log('🔧 开始注册 Token 到 TokenBank...\n');
  
  try {
    // 1. 初始化provider和wallet
    console.log('📡 连接到网络...');
    const provider = new ethers.JsonRpcProvider(NETWORK_CONFIG.rpc);
    const wallet = new ethers.Wallet(TEST_CONFIG.privateKey, provider);
    console.log(`✅ 钱包地址: ${wallet.address}\n`);
    
    // 2. 创建合约实例
    console.log('🏗️ 创建合约实例...');
    const tokenBankABI = [
      'function addSupportedToken(address token) external',
      'function isTokenSupported(address token) external view returns (bool)',
      'function owner() external view returns (address)'
    ];
    
    const tokenBank = new ethers.Contract(CONTRACTS.TOKEN_BANK, tokenBankABI, wallet);
    
    // 3. 检查当前状态
    console.log('🔍 检查当前状态...');
    try {
      const owner = await tokenBank.owner();
      console.log(`🏦 TokenBank 所有者: ${owner}`);
      console.log(`👤 当前钱包: ${wallet.address}`);
      
      if (owner.toLowerCase() !== wallet.address.toLowerCase()) {
        console.log('❌ 当前钱包不是 TokenBank 的所有者！');
        console.log('💡 需要所有者钱包来注册 Token');
        return;
      }
      
      const isSupported = await tokenBank.isTokenSupported(CONTRACTS.EIP2612_TOKEN);
      console.log(`✅ Token 当前支持状态: ${isSupported}`);
      
      if (isSupported) {
        console.log('✅ Token 已经注册，无需重复注册');
        return;
      }
      
    } catch (error) {
      console.log(`❌ 检查状态失败: ${error.message}`);
      return;
    }
    
    // 4. 注册 Token
    console.log('\n📝 注册 Token...');
    const tx = await tokenBank.addSupportedToken(
      CONTRACTS.EIP2612_TOKEN,
      {
        gasLimit: TEST_CONFIG.gasLimit,
        gasPrice: TEST_CONFIG.gasPrice
      }
    );
    
    console.log(`📤 交易已发送: ${tx.hash}`);
    console.log('⏳ 等待确认...');
    
    const receipt = await tx.wait();
    console.log(`✅ 交易已确认: ${receipt.status === 1 ? '成功' : '失败'}`);
    
    // 5. 验证注册结果
    console.log('\n🔍 验证注册结果...');
    const newIsSupported = await tokenBank.isTokenSupported(CONTRACTS.EIP2612_TOKEN);
    console.log(`✅ Token 新支持状态: ${newIsSupported}`);
    
    if (newIsSupported) {
      console.log('🎉 Token 注册成功！现在可以测试 Permit2 deposit 了');
    } else {
      console.log('❌ Token 注册失败');
    }
    
  } catch (error) {
    console.error('\n❌ 注册失败:', error.message);
    console.error('详细错误:', error);
  }
}

// 运行注册
registerToken(); 