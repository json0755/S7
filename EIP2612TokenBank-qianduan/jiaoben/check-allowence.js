const { ethers } = require('ethers');

async function checkAllowance() {
    console.log('�� 检查ERC20对Permit2的授权情况...');
    
    // 配置
    const config = {
        rpc: 'http://127.0.0.1:8545',
        tokenAddress: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
        permit2Address: '0x000000000022D473030F116dDEE9F6B43aC78BA3',
        walletAddress: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'
    };

    // 连接provider
    const provider = new ethers.JsonRpcProvider(config.rpc);
    
    // Token合约ABI (简化版)
    const tokenABI = [
        "function allowance(address owner, address spender) view returns (uint256)",
        "function balanceOf(address account) view returns (uint256)",
        "function approve(address spender, uint256 amount) returns (bool)"
    ];

    // Permit2合约ABI (简化版)
    const permit2ABI = [
        "function allowance(address owner, address token, address spender) view returns (uint160 amount, uint48 expiration)"
    ];

    try {
        // 创建合约实例
        const tokenContract = new ethers.Contract(config.tokenAddress, tokenABI, provider);
        const permit2Contract = new ethers.Contract(config.permit2Address, permit2ABI, provider);

        console.log('📊 检查Token合约的allowance...');
        
        // 检查Token合约的allowance
        const allowance = await tokenContract.allowance(config.walletAddress, config.permit2Address);
        console.log(`✅ Token Allowance: ${allowance.toString()}`);
        console.log(`💰 格式化: ${ethers.formatUnits(allowance, 18)} tokens`);

        // 检查Token余额
        const balance = await tokenContract.balanceOf(config.walletAddress);
        console.log(`✅ Token余额: ${balance.toString()}`);
        console.log(`💰 格式化: ${ethers.formatUnits(balance, 18)} tokens`);

        // 检查Permit2合约的allowance
        console.log('\n🔍 检查Permit2合约的allowance...');
        const permit2Allowance = await permit2Contract.allowance(config.walletAddress, config.tokenAddress, config.permit2Address);
        console.log(`✅ Permit2 Allowance: ${permit2Allowance[0].toString()}`);
        console.log(`📅 Expiration: ${permit2Allowance[1].toString()}`);
        console.log(`💰 格式化: ${ethers.formatUnits(permit2Allowance[0], 18)} tokens`);

        // 检查授权状态
        console.log('\n🎯 授权状态:');
        if (allowance > 0) {
            console.log('✅ Token合约已授权给Permit2');
        } else {
            console.log('❌ Token合约未授权给Permit2');
            console.log('💡 需要执行approve操作');
        }

    } catch (error) {
        console.error('❌ 错误:', error.message);
    }
}

checkAllowance();