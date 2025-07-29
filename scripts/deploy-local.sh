#!/bin/bash

echo "🚀 开始本地Permit2完整部署..."
echo "======================================"

# 检查环境
if ! command -v forge &> /dev/null; then
    echo "❌ Forge未安装，请先安装Foundry"
    exit 1
fi

# 设置变量
PRIVATE_KEY=${PRIVATE_KEY:-}
RPC_URL=${RPC_URL:-http://127.0.0.1:8545}
USER_ADDRESS=${USER_ADDRESS:-0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266}

echo "📋 配置信息:"
echo "  RPC URL: $RPC_URL"
echo "  用户地址: $USER_ADDRESS"
echo "======================================"

# 1. 检查网络连接
echo "🔍 检查本地网络连接..."
if ! curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL > /dev/null; then
    echo "❌ 无法连接到本地网络，请确保启动了anvil或hardhat节点"
    echo "💡 启动本地节点命令: anvil"
    exit 1
fi
echo "✅ 网络连接正常"

# 2. 编译合约
echo "🔨 编译合约..."
forge build
if [ $? -ne 0 ]; then
    echo "❌ 合约编译失败"
    exit 1
fi
echo "✅ 合约编译成功"

# 3. 运行测试（可选）
echo "🧪 运行Permit2测试..."
forge test --match-contract LocalPermit2Test -vv
if [ $? -ne 0 ]; then
    echo "⚠️  测试失败，但继续部署..."
else
    echo "✅ 测试通过"
fi

# 4. 部署合约
echo "🚀 开始部署合约..."
forge script script/DeployAllLocal.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast

if [ $? -ne 0 ]; then
    echo "❌ 部署失败"
    exit 1
fi

echo "✅ 部署完成!"

# 5. 从部署文件中提取地址
DEPLOYMENT_FILE="deployments/local-deployment.txt"
if [ -f "$DEPLOYMENT_FILE" ]; then
    echo "📋 从部署文件中提取地址..."
    
    TOKEN_ADDRESS=$(grep "EIP2612Token:" "$DEPLOYMENT_FILE" | cut -d' ' -f2)
    PERMIT2_ADDRESS=$(grep "Permit2:" "$DEPLOYMENT_FILE" | cut -d' ' -f2)
    TOKENBANK_ADDRESS=$(grep "TokenBank:" "$DEPLOYMENT_FILE" | cut -d' ' -f2)
    
    echo "📍 部署的合约地址:"
    echo "  🪙 Token: $TOKEN_ADDRESS"
    echo "  🔐 Permit2: $PERMIT2_ADDRESS"  
    echo "  🏦 TokenBank: $TOKENBANK_ADDRESS"
    
    # 6. Mint测试token
    echo "🪙 Mint测试tokens..."
    TOKEN_ADDRESS=$TOKEN_ADDRESS RECIPIENT_ADDRESS=$USER_ADDRESS MINT_AMOUNT=10000000000000000000000 \
    forge script script/MintTokens.s.sol \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast
    
    if [ $? -eq 0 ]; then
        echo "✅ Token mint成功!"
    else
        echo "⚠️  Token mint失败，请手动执行"
    fi
    
    # 7. 生成前端配置
    echo "🔧 生成前端配置..."
    cat > tokenbank-front-config.js << EOF
// 本地部署的合约地址 - 复制到 tokenbank-front/src/app/page.tsx
const TOKEN_ADDRESS = "$TOKEN_ADDRESS";
const PERMIT2_ADDRESS = "$PERMIT2_ADDRESS";  
const TOKENBANK_ADDRESS = "$TOKENBANK_ADDRESS";

// 本地网络配置
const LOCAL_CHAIN_ID = 31337; // Anvil默认链ID
const LOCAL_RPC_URL = "$RPC_URL";

export {
    TOKEN_ADDRESS,
    PERMIT2_ADDRESS, 
    TOKENBANK_ADDRESS,
    LOCAL_CHAIN_ID,
    LOCAL_RPC_URL
};
EOF
    
    echo "✅ 前端配置已生成: tokenbank-front-config.js"
    
else
    echo "❌ 找不到部署文件: $DEPLOYMENT_FILE"
    exit 1
fi

echo "======================================"
echo "🎉 本地Permit2部署完成!"
echo ""
echo "📋 下一步操作:"
echo "1. 将生成的地址复制到前端配置文件"
echo "2. 确保MetaMask连接到本地网络 (Chain ID: 31337)"
echo "3. 在MetaMask中导入测试账户私钥"
echo "4. 启动前端应用进行测试"
echo ""
echo "🔧 快捷命令:"
echo "  测试合约: forge test --match-contract LocalPermit2Test -vv"
echo "  重新部署: ./scripts/deploy-local.sh"
echo "  查看部署信息: cat deployments/local-deployment.txt"
echo "======================================" 