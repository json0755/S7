import { ethers } from 'ethers';

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
  depositAmount: '10'
};

async function diagnosePermit2() {
  console.log('🔍 开始诊断 Permit2 问题...\n');
  
  try {
    // 1. 初始化
    console.log('📡 连接到网络...');
    const provider = new ethers.JsonRpcProvider(NETWORK_CONFIG.rpc);
    const wallet = new ethers.Wallet(TEST_CONFIG.privateKey, provider);
    console.log(`✅ 钱包地址: ${wallet.address}\n`);
    
    // 2. 检查 TokenBank 状态
    console.log('🏦 检查 TokenBank 状态...');
    const tokenBankABI = [
      'function isTokenSupported(address token) external view returns (bool)',
      'function owner() external view returns (address)'
    ];
    
    const tokenBank = new ethers.Contract(CONTRACTS.TOKEN_BANK, tokenBankABI, provider);
    
    try {
      const isSupported = await tokenBank.isTokenSupported(CONTRACTS.EIP2612_TOKEN);
      console.log(`✅ Token 支持状态: ${isSupported}`);
      
      if (!isSupported) {
        console.log('❌ 问题1: Token 未在 TokenBank 中注册！');
        console.log('💡 解决方案: 需要调用 addSupportedToken() 注册 Token');
        return;
      }
    } catch (error) {
      console.log(`❌ 检查 Token 支持状态失败: ${error.message}`);
      return;
    }
    
    // 3. 检查 Token 余额和授权
    console.log('\n💰 检查 Token 状态...');
    const tokenABI = [
      'function balanceOf(address account) external view returns (uint256)',
      'function allowance(address owner, address spender) external view returns (uint256)',
      'function decimals() external view returns (uint8)',
      'function symbol() external view returns (string)'
    ];
    
    const token = new ethers.Contract(CONTRACTS.EIP2612_TOKEN, tokenABI, provider);
    
    try {
      const balance = await token.balanceOf(wallet.address);
      const allowance = await token.allowance(wallet.address, CONTRACTS.PERMIT2);
      const decimals = await token.decimals();
      const symbol = await token.symbol();
      
      console.log(`✅ Token 余额: ${ethers.formatUnits(balance, decimals)} ${symbol}`);
      console.log(`✅ Permit2 授权: ${ethers.formatUnits(allowance, decimals)} ${symbol}`);
      
      if (allowance === 0n) {
        console.log('❌ 问题2: Token 未授权给 Permit2！');
        console.log('💡 解决方案: 需要调用 token.approve(permit2, amount) 授权');
        return;
      }
      
    } catch (error) {
      console.log(`❌ 检查 Token 状态失败: ${error.message}`);
      return;
    }
    
    // 4. 检查 Permit2 合约状态
    console.log('\n🔐 检查 Permit2 状态...');
    const permit2ABI = [
      'function DOMAIN_SEPARATOR() external view returns (bytes32)',
      'function isNonceUsed(address owner, uint256 nonce) external view returns (bool)'
    ];
    
    const permit2 = new ethers.Contract(CONTRACTS.PERMIT2, permit2ABI, provider);
    
    try {
      const domainSeparator = await permit2.DOMAIN_SEPARATOR();
      console.log(`✅ Permit2 域分隔符: ${domainSeparator}`);
      
      // 检查 nonce 是否已使用
      const testNonce = 123456;
      const isNonceUsed = await permit2.isNonceUsed(wallet.address, testNonce);
      console.log(`✅ Nonce 检查功能正常: ${isNonceUsed}`);
      
    } catch (error) {
      console.log(`❌ 检查 Permit2 状态失败: ${error.message}`);
      return;
    }
    
    // 5. 生成测试签名并验证
    console.log('\n✍️ 测试签名生成...');
    const amount = ethers.parseUnits(TEST_CONFIG.depositAmount, 18);
    const nonce = ethers.getBigInt(Math.floor(Math.random() * 1000000));
    const deadline = ethers.getBigInt(Math.floor(Date.now() / 1000) + 3600);
    
    console.log(`📝 测试参数:`);
    console.log(`  Amount: ${ethers.formatUnits(amount, 18)} BAPE`);
    console.log(`  Nonce: ${nonce.toString()}`);
    console.log(`  Deadline: ${deadline.toString()} (${new Date(Number(deadline) * 1000).toLocaleString()})`);
    
    // 创建签名
    const domain = {
      name: 'Permit2',
      chainId: NETWORK_CONFIG.chainId,
      verifyingContract: CONTRACTS.PERMIT2
    };
    
    const types = {
      PermitTransferFrom: [
        { name: 'permitted', type: 'TokenPermissions' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' }
      ],
      TokenPermissions: [
        { name: 'token', type: 'address' },
        { name: 'amount', type: 'uint256' }
      ]
    };
    
    const permit = {
      permitted: {
        token: CONTRACTS.EIP2612_TOKEN,
        amount: amount
      },
      nonce: nonce,
      deadline: deadline
    };
    
    try {
      const signature = await wallet.signTypedData(domain, types, permit);
      console.log(`✅ 签名生成成功: ${signature.slice(0, 20)}...`);
      
      // 验证签名
      const structHash = ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
        ['bytes32', 'bytes32', 'uint256', 'uint256'],
        [
          ethers.keccak256(ethers.toUtf8Bytes('PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)')),
          ethers.keccak256(ethers.AbiCoder.defaultAbiCoder().encode(
            ['bytes32', 'address', 'uint256'],
            [
              ethers.keccak256(ethers.toUtf8Bytes('TokenPermissions(address token,uint256 amount)')),
              CONTRACTS.EIP2612_TOKEN,
              amount
            ]
          )),
          nonce,
          deadline
        ]
      ));
      
      const domainSeparator = await permit2.DOMAIN_SEPARATOR();
      const hash = ethers.keccak256(ethers.solidityPacked(
        ['string', 'bytes32', 'bytes32'],
        ['\x19\x01', domainSeparator, structHash]
      ));
      
      const recoveredSigner = ethers.verifyMessage(ethers.getBytes(hash), signature);
      console.log(`✅ 签名验证成功: ${recoveredSigner === wallet.address}`);
      
    } catch (error) {
      console.log(`❌ 签名生成/验证失败: ${error.message}`);
      return;
    }
    
    // 6. 检查 TokenBank 的 depositWithPermit2 函数
    console.log('\n🏗️ 检查 TokenBank 函数...');
    const depositABI = [
      'function depositWithPermit2(address token, uint256 amount, uint256 nonce, uint256 deadline, bytes calldata signature) external'
    ];
    
    const tokenBankDeposit = new ethers.Contract(CONTRACTS.TOKEN_BANK, depositABI, provider);
    
    try {
      // 尝试调用函数（不发送交易）
      const data = tokenBankDeposit.interface.encodeFunctionData('depositWithPermit2', [
        CONTRACTS.EIP2612_TOKEN,
        amount,
        nonce,
        deadline,
        signature
      ]);
      
      console.log(`✅ 函数编码成功: ${data.slice(0, 20)}...`);
      
    } catch (error) {
      console.log(`❌ 函数编码失败: ${error.message}`);
      return;
    }
    
    console.log('\n🎉 诊断完成！所有基本检查都通过了。');
    console.log('💡 如果仍然遇到错误，可能是以下原因之一:');
    console.log('1. Permit2 合约与 TokenBank 的接口不匹配');
    console.log('2. 签名格式或域分隔符不正确');
    console.log('3. Token 的 transferFrom 函数有问题');
    console.log('4. 网络或 RPC 节点问题');
    
  } catch (error) {
    console.error('\n❌ 诊断失败:', error.message);
    console.error('详细错误:', error);
  }
}

diagnosePermit2(); 