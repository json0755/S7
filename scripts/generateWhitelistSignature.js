import { ethers } from 'ethers';
import crypto from 'crypto';

/**
 * 生成白名单购买签名
 * @param {string} signerPrivateKey - 项目方签名者私钥
 * @param {string} buyerAddress - 购买者地址
 * @param {string} nftAddress - NFT合约地址
 * @param {string} tokenId - NFT TokenId
 * @param {string} nonce - 防重放随机数
 * @returns {object} 签名信息
 */
async function generateWhitelistSignature(signerPrivateKey, buyerAddress, nftAddress, tokenId, nonce) {
    try {
        // 创建钱包实例
        const wallet = new ethers.Wallet(signerPrivateKey);
        
        // 构造消息哈希（与合约中的逻辑一致）
        const messageHash = ethers.solidityPackedKeccak256(
            ['address', 'address', 'uint256', 'uint256'],
            [buyerAddress, nftAddress, tokenId, nonce]
        );
        
        // 生成以太坊签名消息哈希
        const ethSignedMessageHash = ethers.hashMessage(ethers.getBytes(messageHash));
        
        // 生成签名
        const signature = await wallet.signMessage(ethers.getBytes(messageHash));
        
        return {
            success: true,
            data: {
                buyer: buyerAddress,
                nftAddress: nftAddress,
                tokenId: tokenId,
                nonce: nonce,
                messageHash: messageHash,
                ethSignedMessageHash: ethSignedMessageHash,
                signature: signature,
                signer: wallet.address
            }
        };
    } catch (error) {
        return {
            success: false,
            error: error.message
        };
    }
}

/**
 * 验证签名
 * @param {string} signature - 签名
 * @param {string} expectedSigner - 期望的签名者地址
 * @param {string} buyerAddress - 购买者地址
 * @param {string} nftAddress - NFT合约地址
 * @param {string} tokenId - NFT TokenId
 * @param {string} nonce - 防重放随机数
 * @returns {boolean} 验证结果
 */
async function verifySignature(signature, expectedSigner, buyerAddress, nftAddress, tokenId, nonce) {
    try {
        // 构造消息哈希
        const messageHash = ethers.solidityPackedKeccak256(
            ['address', 'address', 'uint256', 'uint256'],
            [buyerAddress, nftAddress, tokenId, nonce]
        );
        
        // 恢复签名者地址
        const recoveredSigner = ethers.verifyMessage(ethers.getBytes(messageHash), signature);
        
        return recoveredSigner.toLowerCase() === expectedSigner.toLowerCase();
    } catch (error) {
        console.error('Verification error:', error);
        return false;
    }
}

/**
 * 生成随机 nonce
 * @returns {string} 随机 nonce
 */
function generateNonce() {
    return Date.now().toString() + Math.floor(Math.random() * 1000000).toString();
}

// 使用示例
async function example() {
    // 项目方私钥（实际使用时应该安全保存）
    const signerPrivateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
    
    // 参数
    const buyerAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
    const nftAddress = "0x6F673bcFbfF56f142EAaBCB2F0A28260264Bd849";
    const tokenId = "1";
    const nonce = generateNonce();
    
    console.log("生成白名单签名...");
    console.log("购买者地址:", buyerAddress);
    console.log("NFT合约地址:", nftAddress);
    console.log("TokenId:", tokenId);
    console.log("Nonce:", nonce);
    console.log("---");
    
    // 生成签名
    const result = await generateWhitelistSignature(
        signerPrivateKey,
        buyerAddress,
        nftAddress,
        tokenId,
        nonce
    );
    
    if (result.success) {
        console.log("✅ 签名生成成功!");
        console.log("签名者地址:", result.data.signer);
        console.log("消息哈希:", result.data.messageHash);
        console.log("签名:", result.data.signature);
        console.log("---");
        
        // 验证签名
        const isValid = await verifySignature(
            result.data.signature,
            result.data.signer,
            buyerAddress,
            nftAddress,
            tokenId,
            nonce
        );
        
        console.log("✅ 签名验证:", isValid ? "通过" : "失败");
        
        return result.data;
    } else {
        console.error("❌ 签名生成失败:", result.error);
        return null;
    }
}

// 导出函数
export {
    generateWhitelistSignature,
    verifySignature,
    generateNonce,
    example
};

// 如果直接运行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
    example().catch(console.error);
} 