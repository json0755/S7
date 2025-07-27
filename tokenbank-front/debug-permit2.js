// Permit2功能调试脚本
// 使用方法: node debug-permit2.js

const { ethers } = require('ethers');

// 配置常量
const TOKEN_ADDRESS = "0xd5Be2044b11D75C4d199CE3e4f1F8b79C37Cb9EB";
const TOKENBANK_ADDRESS = "0x8088fA53C22aB521d0aE1f84A42A70A4a131184D";
const PERMIT2_ADDRESS = "0xe32b6e161a3d9bEb7D2882716b78C2DCbAAB6Ad9";

// Permit2域配置
const PERMIT2_DOMAIN = {
    name: "Permit2",
    version: "1",
    chainId: 11155111, // Sepolia
    verifyingContract: PERMIT2_ADDRESS,
};

// EIP-712类型定义（修复后的版本）
const TYPES = {
    PermitTransferFrom: [
        { name: "permitted", type: "TokenPermissions" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
    ],
    TokenPermissions: [
        { name: "token", type: "address" },
        { name: "amount", type: "uint256" },
    ],
};

// 类型哈希验证
const TOKEN_PERMISSIONS_TYPEHASH = "TokenPermissions(address token,uint256 amount)";
const PERMIT_TRANSFER_FROM_TYPEHASH = "PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)";

console.log("🔧 Permit2调试工具");
console.log("==========================================");
console.log("配置信息:");
console.log("- TOKEN_ADDRESS:", TOKEN_ADDRESS);
console.log("- TOKENBANK_ADDRESS:", TOKENBANK_ADDRESS);
console.log("- PERMIT2_ADDRESS:", PERMIT2_ADDRESS);
console.log("- Chain ID:", PERMIT2_DOMAIN.chainId);
console.log("");

console.log("🔍 类型哈希验证:");
console.log("- TOKEN_PERMISSIONS_TYPEHASH:", TOKEN_PERMISSIONS_TYPEHASH);
console.log("- PERMIT_TRANSFER_FROM_TYPEHASH:", PERMIT_TRANSFER_FROM_TYPEHASH);
console.log("- TOKEN_PERMISSIONS哈希:", ethers.keccak256(ethers.toUtf8Bytes(TOKEN_PERMISSIONS_TYPEHASH)));
console.log("- PERMIT_TRANSFER_FROM哈希:", ethers.keccak256(ethers.toUtf8Bytes(PERMIT_TRANSFER_FROM_TYPEHASH)));
console.log("");

console.log("📋 域分隔符计算:");
const domainSeparator = ethers.TypedDataEncoder.hashDomain(PERMIT2_DOMAIN);
console.log("- 域分隔符:", domainSeparator);
console.log("");

// 生成测试签名数据
const testPermitData = {
    permitted: {
        token: TOKEN_ADDRESS,
        amount: ethers.parseUnits("100", 18), // 100 tokens
    },
    nonce: BigInt(12345),
    deadline: BigInt(Math.floor(Date.now() / 1000) + 3600), // 1小时后过期
};

console.log("🧪 测试签名数据:");
console.log("- token:", testPermitData.permitted.token);
console.log("- amount:", testPermitData.permitted.amount.toString());
console.log("- nonce:", testPermitData.nonce.toString());
console.log("- deadline:", testPermitData.deadline.toString());
console.log("");

// 计算结构哈希
const structHash = ethers.TypedDataEncoder.hash(PERMIT2_DOMAIN, TYPES, testPermitData);
console.log("📝 结构哈希:");
console.log("- structHash:", structHash);
console.log("");

console.log("✅ 调试完成！");
console.log("==========================================");
console.log("修复要点:");
console.log("1. ✅ 修复了PERMIT_TRANSFER_FROM_TYPEHASH定义");
console.log("2. 🔍 确保Token已授权给Permit2合约");
console.log("3. 🔢 验证nonce生成正确");
console.log("4. ⏰ 检查deadline未过期");
console.log("5. 🔐 确认签名者地址正确"); 