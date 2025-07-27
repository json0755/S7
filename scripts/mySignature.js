import { generateWhitelistSignature, generateNonce } from './generateWhitelistSignature.js';

async function generateMySignature() {
    // 🔧 在这里修改你的实际参数
    const signerPrivateKey = "20d003dd2477d62d9f031d238bdffaa69d544d3cb12ba580578c5f7e36c5761e"; // 替换为你的项目方私钥
    const buyerAddress = "0x3F67EccD86D802355046909Ffc68308dA0969EC7";     // 替换为购买者地址
    const nftAddress = "0xdE57605aF3382564341d2fD4065156d0960E7d26";       // 替换为你的NFT合约地址
    const tokenId = "0";                                                   // 替换为要购买的NFT ID
    const nonce = generateNonce();                                         // 自动生成随机nonce

    console.log("🔄 生成白名单签名...");
    console.log("购买者地址:", buyerAddress);
    console.log("NFT合约地址:", nftAddress);
    console.log("TokenId:", tokenId);
    console.log("Nonce:", nonce);
    console.log("---");

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
        console.log("📋 前端使用参数:");
        console.log("NFT TokenId:", tokenId);
        console.log("Nonce:", nonce);
        console.log("项目方签名:", result.data.signature);
        return result.data;
    } else {
        console.error("❌ 签名生成失败:", result.error);
        return null;
    }
}

// 执行函数
generateMySignature().catch(console.error); 