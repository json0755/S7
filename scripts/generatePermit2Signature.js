import { ethers } from 'ethers';

/**
 * Permit2 域分隔符和类型哈希常量
 */
const PERMIT2_DOMAIN_NAME = "Permit2";
const PERMIT2_DOMAIN_VERSION = "1";

const TOKEN_PERMISSIONS_TYPEHASH = ethers.keccak256(
    ethers.toUtf8Bytes("TokenPermissions(address token,uint256 amount)")
);

const PERMIT_TRANSFER_FROM_TYPEHASH = ethers.keccak256(
    ethers.toUtf8Bytes(
        "PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    )
);

/**
 * 生成 Permit2 存款签名
 * @param {string} userPrivateKey - 用户私钥
 * @param {string} tokenAddress - Token合约地址
 * @param {string} tokenBankAddress - TokenBank合约地址
 * @param {string} permit2Address - Permit2合约地址
 * @param {string} amount - 存款金额
 * @param {string} nonce - 防重放随机数
 * @param {string} deadline - 签名过期时间
 * @param {number} chainId - 链ID
 * @returns {object} 签名信息
 */
async function generatePermit2Signature(
    userPrivateKey,
    tokenAddress,
    tokenBankAddress,
    permit2Address,
    amount,
    nonce,
    deadline,
    chainId = 1
) {
    try {
        // 创建钱包实例
        const wallet = new ethers.Wallet(userPrivateKey);
        
        // 构造域分隔符
        const domain = {
            name: PERMIT2_DOMAIN_NAME,
            version: PERMIT2_DOMAIN_VERSION,
            chainId: chainId,
            verifyingContract: permit2Address
        };
        
        // 构造 TokenPermissions 结构体哈希
        const tokenPermissionsHash = ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ["bytes32", "address", "uint256"],
                [TOKEN_PERMISSIONS_TYPEHASH, tokenAddress, amount]
            )
        );
        
        // 构造 PermitTransferFrom 结构体哈希
        const structHash = ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ["bytes32", "bytes32", "uint256", "uint256"],
                [PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, nonce, deadline]
            )
        );
        
        // 构造最终的消息哈希
        const domainSeparator = ethers.TypedDataEncoder.hashDomain(domain);
        const messageHash = ethers.keccak256(
            ethers.concat([
                "0x1901",
                domainSeparator,
                structHash
            ])
        );
        
        // 生成签名
        const signature = await wallet.signMessage(ethers.getBytes(messageHash));
        
        return {
            success: true,
            data: {
                user: wallet.address,
                tokenAddress: tokenAddress,
                tokenBankAddress: tokenBankAddress,
                permit2Address: permit2Address,
                amount: amount,
                nonce: nonce,
                deadline: deadline,
                chainId: chainId,
                messageHash: messageHash,
                domainSeparator: domainSeparator,
                signature: signature,
                structHash: structHash
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
 * 验证 Permit2 签名
 * @param {string} signature - 签名
 * @param {string} expectedSigner - 期望的签名者地址
 * @param {string} tokenAddress - Token合约地址
 * @param {string} permit2Address - Permit2合约地址
 * @param {string} amount - 存款金额
 * @param {string} nonce - 防重放随机数
 * @param {string} deadline - 签名过期时间
 * @param {number} chainId - 链ID
 * @returns {boolean} 验证结果
 */
async function verifyPermit2Signature(
    signature,
    expectedSigner,
    tokenAddress,
    permit2Address,
    amount,
    nonce,
    deadline,
    chainId = 1
) {
    try {
        // 重新构造消息哈希
        const domain = {
            name: PERMIT2_DOMAIN_NAME,
            version: PERMIT2_DOMAIN_VERSION,
            chainId: chainId,
            verifyingContract: permit2Address
        };
        
        const tokenPermissionsHash = ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ["bytes32", "address", "uint256"],
                [TOKEN_PERMISSIONS_TYPEHASH, tokenAddress, amount]
            )
        );
        
        const structHash = ethers.keccak256(
            ethers.AbiCoder.defaultAbiCoder().encode(
                ["bytes32", "bytes32", "uint256", "uint256"],
                [PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, nonce, deadline]
            )
        );
        
        const domainSeparator = ethers.TypedDataEncoder.hashDomain(domain);
        const messageHash = ethers.keccak256(
            ethers.concat([
                "0x1901",
                domainSeparator,
                structHash
            ])
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

/**
 * 生成未来的截止时间（24小时后）
 * @returns {string} 截止时间戳
 */
function generateDeadline() {
    return Math.floor(Date.now() / 1000) + 24 * 60 * 60; // 24小时后
}

// 使用示例
async function example() {
    // 用户私钥（实际使用时应该安全保存）
    const userPrivateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
    
    // 合约地址（需要替换为实际部署的地址）
    const tokenAddress = "0xBe8446a91ec13Cd2d506D90E515635891B736b54";
    const tokenBankAddress = "0x你的TokenBank合约地址";
    const permit2Address = "0x000000000022D473030F116dDEE9F6B43aC78BA3"; // Permit2 官方地址
    
    // 参数
    const amount = ethers.parseEther("100"); // 100 tokens
    const nonce = generateNonce();
    const deadline = generateDeadline();
    const chainId = 11155111; // Sepolia 测试网
    
    console.log("生成 Permit2 存款签名...");
    console.log("用户地址:", ethers.computeAddress(userPrivateKey));
    console.log("Token地址:", tokenAddress);
    console.log("TokenBank地址:", tokenBankAddress);
    console.log("Permit2地址:", permit2Address);
    console.log("存款金额:", ethers.formatEther(amount), "tokens");
    console.log("Nonce:", nonce);
    console.log("截止时间:", new Date(deadline * 1000).toLocaleString());
    console.log("---");
    
    // 生成签名
    const result = await generatePermit2Signature(
        userPrivateKey,
        tokenAddress,
        tokenBankAddress,
        permit2Address,
        amount.toString(),
        nonce,
        deadline.toString(),
        chainId
    );
    
    if (result.success) {
        console.log("✅ Permit2 签名生成成功!");
        console.log("用户地址:", result.data.user);
        console.log("消息哈希:", result.data.messageHash);
        console.log("域分隔符:", result.data.domainSeparator);
        console.log("结构体哈希:", result.data.structHash);
        console.log("签名:", result.data.signature);
        console.log("---");
        
        // 验证签名
        const isValid = await verifyPermit2Signature(
            result.data.signature,
            result.data.user,
            tokenAddress,
            permit2Address,
            amount.toString(),
            nonce,
            deadline.toString(),
            chainId
        );
        
        console.log("✅ 签名验证:", isValid ? "通过" : "失败");
        console.log("---");
        console.log("📋 合约调用参数:");
        console.log("amount:", amount.toString());
        console.log("nonce:", nonce);
        console.log("deadline:", deadline.toString());
        console.log("transferDetails: {");
        console.log("  to:", tokenBankAddress);
        console.log("  requestedAmount:", amount.toString());
        console.log("}");
        console.log("signature:", result.data.signature);
        
        return result.data;
    } else {
        console.error("❌ 签名生成失败:", result.error);
        return null;
    }
}

// 导出函数
export {
    generatePermit2Signature,
    verifyPermit2Signature,
    generateNonce,
    generateDeadline,
    example
};

// 如果直接运行此脚本
if (import.meta.url === `file://${process.argv[1]}`) {
    example().catch(console.error);
} 