// test-permit2-deposit.js
// 简化的Permit2签名存款测试脚本

const { ethers } = require('ethers');

// 配置
const CONFIG = {
  rpc: 'http://127.0.0.1:8545',
  chainId: 31337,
  privateKey: '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
  tokenAddress: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
  tokenBankAddress: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
  permit2Address: '0x000000000022D473030F116dDEE9F6B43aC78BA3',
  amount: '1000000000000000000' // 1 token
};

// TokenBank ABI (修正版)
const TOKEN_BANK_ABI = [
  {
    "inputs": [
      {"internalType": "uint256", "name": "assets", "type": "uint256"},
      {"internalType": "address", "name": "receiver", "type": "address"},
      {"internalType": "uint160", "name": "amount", "type": "uint160"},
      {"internalType": "uint48", "name": "expiration", "type": "uint48"},
      {"internalType": "uint48", "name": "nonce", "type": "uint48"},
      {"internalType": "uint256", "name": "sigDeadline", "type": "uint256"},
      {"internalType": "bytes", "name": "signature", "type": "bytes"}
    ],
    "name": "permitDeposit2",
    "outputs": [{"internalType": "uint256", "name": "shares", "type": "uint256"}],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [{"internalType": "address", "name": "account", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "asset",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getPermit2Address",
    "outputs": [{"internalType": "address", "name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
];

// 工具函数
function formatAmount(amount) {
  return ethers.formatUnits(amount, 18);
}

function truncateAddress(address) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// 生成随机nonce
function generateNonce() {
  return Math.floor(Math.random() * 1000000);
}

// 创建Permit2签名
async function createPermit2Signature(wallet, tokenAddress, spender, amount, nonce, deadline) {
  const domain = {
    name: 'Permit2',
    chainId: CONFIG.chainId,
    verifyingContract: CONFIG.permit2Address
  };

  const types = {
    PermitSingle: [
      { name: 'details', type: 'PermitDetails' },
      { name: 'spender', type: 'address' },
      { name: 'sigDeadline', type: 'uint256' }
    ],
    PermitDetails: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint160' },
      { name: 'expiration', type: 'uint48' },
      { name: 'nonce', type: 'uint48' }
    ]
  };

  const message = {
    details: {
      token: tokenAddress,
      amount: amount,
      expiration: deadline,
      nonce: nonce
    },
    spender: spender,
    sigDeadline: deadline
  };

  return await wallet.signTypedData(domain, types, message);
}

// 主测试函数
async function testPermit2Deposit() {
  console.log(' 开始Permit2签名存款测试...\n');
  
  try {
    // 1. 初始化provider和wallet
    console.log('📡 连接到Anvil网络...');
    const provider = new ethers.JsonRpcProvider(CONFIG.rpc);
    const wallet = new ethers.Wallet(CONFIG.privateKey, provider);
    console.log(`✅ 钱包地址: ${truncateAddress(wallet.address)}\n`);
    
    // 2. 创建TokenBank合约实例
    console.log('🏗️ 创建合约实例...');
    const tokenBankContract = new ethers.Contract(CONFIG.tokenBankAddress, TOKEN_BANK_ABI, wallet);
    console.log(`✅ TokenBank地址: ${truncateAddress(CONFIG.tokenBankAddress)}\n`);
    
    // 3. 验证合约配置
    console.log('🔍 验证合约配置...');
    try {
      const assetAddress = await tokenBankContract.asset();
      console.log(`🏦 资产地址: ${truncateAddress(assetAddress)}`);
      
      const permit2Address = await tokenBankContract.getPermit2Address();
      console.log(`�� Permit2地址: ${truncateAddress(permit2Address)}`);
      
      if (assetAddress.toLowerCase() !== CONFIG.tokenAddress.toLowerCase()) {
        console.log(`⚠️ 资产地址不匹配: 期望 ${truncateAddress(CONFIG.tokenAddress)}, 实际 ${truncateAddress(assetAddress)}`);
      }
    } catch (error) {
      console.log(`❌ 无法获取合约配置: ${error.message}`);
    }
    
    // 4. 获取初始余额
    console.log('🔍 获取初始余额...');
    const initialBalance = await tokenBankContract.balanceOf(wallet.address);
    console.log(`🏦 初始份额: ${formatAmount(initialBalance)} TBANK\n`);
    
    // 5. 准备签名参数
    console.log('📝 准备签名参数...');
    const amount = CONFIG.amount;
    const nonce = generateNonce();
    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1小时后过期
    
    console.log(`💰 存款金额: ${formatAmount(amount)} tokens`);
    console.log(`📝 Nonce: ${nonce}`);
    console.log(`⏰ Deadline: ${deadline}\n`);
    
    // 6. 创建Permit2签名
    console.log('✍️ 创建Permit2签名...');
    const signature = await createPermit2Signature(
      wallet,
      CONFIG.tokenAddress,
      CONFIG.tokenBankAddress, // spender是TokenBank合约地址
      amount,
      nonce,
      deadline
    );
    console.log(`✅ 签名创建成功: ${signature.slice(0, 20)}...\n`);
    
    // 7. 执行Permit2存款
    console.log(' 执行Permit2存款...');
    const depositTx = await tokenBankContract.permitDeposit2(
      amount,           // assets
      wallet.address,   // receiver
      amount,           // amount (uint160)
      deadline,         // expiration (uint48)
      nonce,            // nonce (uint48)
      deadline,         // sigDeadline
      signature,        // signature
      {
        gasLimit: 500000,
        gasPrice: 20000000000
      }
    );
    
    console.log(`⏳ 等待交易确认: ${depositTx.hash}`);
    const receipt = await depositTx.wait();
    console.log(`✅ 存款成功! Gas used: ${receipt.gasUsed.toString()}\n`);
    
    // 8. 验证结果
    console.log('🔍 验证存款结果...');
    const finalBalance = await tokenBankContract.balanceOf(wallet.address);
    console.log(`🏦 最终份额: ${formatAmount(finalBalance)} TBANK`);
    console.log(`📈 份额增加: ${formatAmount(finalBalance - initialBalance)} TBANK`);
    
    // 9. 测试总结
    console.log('\n🎉 Permit2签名存款测试完成!');
    console.log('📊 测试总结:');
    console.log(`   - 存款金额: ${formatAmount(amount)} tokens`);
    console.log(`   - 交易Hash: ${receipt.hash}`);
    console.log(`   - Gas used: ${receipt.gasUsed.toString()}`);
    console.log(`   - 份额增加: ${formatAmount(finalBalance - initialBalance)} TBANK`);
    
  } catch (error) {
    console.error('\n❌ 测试失败:', error.message);
    console.error('详细错误:', error);
    
    // 提供调试信息
    console.log('\n🔍 调试信息:');
    console.log(`  - TokenBank地址: ${CONFIG.tokenBankAddress}`);
    console.log(`  - Token地址: ${CONFIG.tokenAddress}`);
    console.log(`  - Permit2地址: ${CONFIG.permit2Address}`);
    console.log(`  - 网络: Anvil (${CONFIG.chainId})`);
    
    process.exit(1);
  }
}

// 运行测试
if (require.main === module) {
  testPermit2Deposit()
    .then(() => {
      console.log('\n✅ 测试完成!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ 测试过程中发生错误:', error);
      process.exit(1);
    });
}

module.exports = {
  testPermit2Deposit,
  CONFIG
};