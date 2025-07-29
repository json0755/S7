import { ethers } from 'ethers';
import { generatePermit2Signature, generateNonce, generateDeadline } from './generatePermit2Signature.js';

/**
 * 调用 TokenBank 的 depositWithPermit2 方法
 */
async function callDepositWithPermit2() {
    // 配置参数
    const config = {
        // 用户私钥
        userPrivateKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        
        // 合约地址
        tokenAddress: "0xBe8446a91ec13Cd2d506D90E515635891B736b54",
        tokenBankAddress: "0x你的TokenBank合约地址", // 替换为实际地址
        permit2Address: "0x000000000022D473030F116dDEE9F6B43aC78BA3",
        
        // 网络配置
        rpcUrl: "https://sepolia.infura.io/v3/YOUR_PROJECT_ID", // 替换为实际RPC
        chainId: 11155111, // Sepolia testnet
        
        // 交易参数
        amount: ethers.parseEther("100"), // 100 tokens
    };

    try {
        console.log("🚀 开始调用 depositWithPermit2...");
        
        // 1. 连接到网络
        const provider = new ethers.JsonRpcProvider(config.rpcUrl);
        const wallet = new ethers.Wallet(config.userPrivateKey, provider);
        
        console.log("用户地址:", wallet.address);
        console.log("存款金额:", ethers.formatEther(config.amount), "tokens");
        
        // 2. 生成签名参数
        const nonce = generateNonce();
        const deadline = generateDeadline();
        
        console.log("Nonce:", nonce);
        console.log("截止时间:", new Date(deadline * 1000).toLocaleString());
        
        // 3. 生成 Permit2 签名
        console.log("\n📝 生成 Permit2 签名...");
        const signatureResult = await generatePermit2Signature(
            config.userPrivateKey,
            config.tokenAddress,
            config.tokenBankAddress,
            config.permit2Address,
            config.amount.toString(),
            nonce,
            deadline.toString(),
            config.chainId
        );
        
        if (!signatureResult.success) {
            throw new Error(`签名生成失败: ${signatureResult.error}`);
        }
        
        console.log("✅ 签名生成成功!");
        console.log("签名:", signatureResult.data.signature);
        
        // 4. 构造 TokenBank 合约实例
        const tokenBankABI = [
            "function depositWithPermit2(uint256 amount, uint256 nonce, uint256 deadline, tuple(address to, uint256 requestedAmount) transferDetails, bytes calldata signature) external",
            "function getBalance(address user) external view returns (uint256)",
            "function balances(address) external view returns (uint256)"
        ];
        
        const tokenBank = new ethers.Contract(config.tokenBankAddress, tokenBankABI, wallet);
        
        // 5. 查询存款前余额
        const balanceBefore = await tokenBank.balanceOf(wallet.address);
        console.log("\n📊 存款前余额:", ethers.formatEther(balanceBefore), "tokens");
        
        // 6. 调用 depositWithPermit2
        console.log("\n💰 执行 depositWithPermit2...");
        
        const transferDetails = {
            to: config.tokenBankAddress,
            requestedAmount: config.amount
        };
        
        const tx = await tokenBank.depositWithPermit2(
            config.amount,          // amount
            nonce,                 // nonce
            deadline,              // deadline
            transferDetails,       // transferDetails
            signatureResult.data.signature  // signature
        );
        
        console.log("交易哈希:", tx.hash);
        console.log("⏳ 等待交易确认...");
        
        // 7. 等待交易确认
        const receipt = await tx.wait();
        console.log("✅ 交易确认成功!");
        console.log("Gas使用量:", receipt.gasUsed.toString());
        
        // 8. 查询存款后余额
        const balanceAfter = await tokenBank.balanceOf(wallet.address);
        console.log("\n📊 存款后余额:", ethers.formatEther(balanceAfter), "tokens");
        console.log("存款增加:", ethers.formatEther(balanceAfter - balanceBefore), "tokens");
        
        console.log("\n🎉 depositWithPermit2 调用成功!");
        
        return {
            success: true,
            txHash: tx.hash,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter
        };
        
    } catch (error) {
        console.error("❌ 调用失败:", error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// 导出函数
export { callDepositWithPermit2 };

// 如果直接运行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
    callDepositWithPermit2().catch(console.error);
} 