#!/bin/bash

echo "🚀 开始 Permit2 签名存款自动化测试"
echo "=========================================="

# 清理之前的编译
echo "🧹 清理编译缓存..."
forge clean

# 编译合约
echo "🔨 编译合约..."
forge build
if [ $? -ne 0 ]; then
    echo "❌ 合约编译失败"
    exit 1
fi
echo "✅ 合约编译成功"

# 运行完整的Permit2存款流程测试
echo ""
echo "🧪 运行完整的Permit2存款流程测试..."
echo "----------------------------------------"
forge test --match-test test_FullPermit2DepositFlow -vv

if [ $? -eq 0 ]; then
    echo "✅ 完整流程测试通过!"
else
    echo "❌ 完整流程测试失败"
    exit 1
fi

# 运行签名验证测试
echo ""
echo "🔐 运行Permit2签名验证测试..."
echo "----------------------------------------"
forge test --match-test test_SignatureValidation -vv

if [ $? -eq 0 ]; then
    echo "✅ 签名验证测试通过!"
else
    echo "❌ 签名验证测试失败"
    exit 1
fi

# 运行nonce管理测试
echo ""
echo "🔢 运行Permit2 Nonce管理测试..."
echo "----------------------------------------"
forge test --match-test test_NonceManagement -vv

if [ $? -eq 0 ]; then
    echo "✅ Nonce管理测试通过!"
else
    echo "❌ Nonce管理测试失败"
    exit 1
fi

echo ""
echo "🎉 所有Permit2测试都通过了!"
echo "=========================================="
echo "📋 测试总结:"
echo "  ✅ 完整的Permit2存款流程"
echo "  ✅ Permit2签名验证机制"
echo "  ✅ Permit2 Nonce管理功能"
echo ""
echo "🚀 Permit2签名存款功能本地测试完全通过!"
echo "现在可以在前端安全地使用该功能。" 