#!/bin/bash

# approve-permit2.sh
# 授权Token给Permit2

# 配置
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RPC_URL="http://127.0.0.1:8545"
TOKEN_ADDRESS="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
PERMIT2_ADDRESS="0x000000000022D473030F116dDEE9F6B43aC78BA3"
WALLET_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

echo "🔐 授权Token给Permit2..."
echo "=================================="
echo ""

# 检查当前allowance
echo "�� 检查当前allowance..."
CURRENT_ALLOWANCE=$(cast call $TOKEN_ADDRESS \
  "allowance(address,address)(uint256)" \
  $WALLET_ADDRESS $PERMIT2_ADDRESS \
  --rpc-url $RPC_URL)

echo "当前allowance: $CURRENT_ALLOWANCE"
echo "格式化: $(cast --to-dec $CURRENT_ALLOWANCE | xargs -I {} cast --to-eth {} 18) tokens"
echo ""

if [ "$CURRENT_ALLOWANCE" != "0" ]; then
    echo "✅ 已经授权过了！"
    exit 0
fi

# 执行授权
echo "🔐 执行授权..."
echo "Token地址: $TOKEN_ADDRESS"
echo "Permit2地址: $PERMIT2_ADDRESS"
echo "授权金额: 最大授权值"
echo ""

# 使用cast发送授权交易
TX_HASH=$(cast send $TOKEN_ADDRESS \
  "approve(address,uint256)" \
  $PERMIT2_ADDRESS \
  "115792089237316195423570985008687907853269984665640564039457584007913129639935" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL)

echo "📝 交易哈希: $TX_HASH"
echo ""

# 等待交易确认
echo "⏳ 等待交易确认..."
sleep 2

# 验证授权结果
echo "�� 验证授权结果..."
NEW_ALLOWANCE=$(cast call $TOKEN_ADDRESS \
  "allowance(address,address)(uint256)" \
  $WALLET_ADDRESS $PERMIT2_ADDRESS \
  --rpc-url $RPC_URL)

echo "新的allowance: $NEW_ALLOWANCE"
echo "格式化: $(cast --to-dec $NEW_ALLOWANCE | xargs -I {} cast --to-eth {} 18) tokens"

if [ "$NEW_ALLOWANCE" != "0" ]; then
    echo "✅ 授权成功！"
else
    echo "❌ 授权失败！"
fi