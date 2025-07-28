#!/bin/bash

# 配置参数
TOKEN_BANK_ADDRESS="0x你的TokenBank合约地址"
TOKEN_ADDRESS="0xBe8446a91ec13Cd2d506D90E515635891B736b54"
PERMIT2_ADDRESS="0x000000000022D473030F116dDEE9F6B43aC78BA3"
USER_PRIVATE_KEY="0x你的私钥"
RPC_URL="https://sepolia.infura.io/v3/YOUR_PROJECT_ID"

# 交易参数
AMOUNT="100000000000000000000"  # 100 tokens (18 decimals)
NONCE="1753626377635974742"     # 从签名工具获得
DEADLINE="1753712777"           # 从签名工具获得
SIGNATURE="0x..."               # 从签名工具获得的完整签名

echo "🚀 调用 TokenBank.depositWithPermit2..."
echo "TokenBank地址: $TOKEN_BANK_ADDRESS"
echo "存款金额: 100 tokens"
echo "Nonce: $NONCE"
echo "截止时间: $DEADLINE"

# 1. 先查询存款前余额
echo ""
echo "📊 查询存款前余额..."
BALANCE_BEFORE=$(cast call $TOKEN_BANK_ADDRESS \
    "getBalance(address)(uint256)" \
    $(cast wallet address --private-key $USER_PRIVATE_KEY) \
    --rpc-url $RPC_URL)

echo "存款前余额: $(cast to-dec $BALANCE_BEFORE) wei"

# 2. 调用 depositWithPermit2
echo ""
echo "💰 执行 depositWithPermit2..."

# 构造transferDetails结构体
TRANSFER_DETAILS="($TOKEN_BANK_ADDRESS,$AMOUNT)"

# 调用合约
TX_HASH=$(cast send $TOKEN_BANK_ADDRESS \
    "depositWithPermit2(uint256,uint256,uint256,(address,uint256),bytes)" \
    $AMOUNT \
    $NONCE \
    $DEADLINE \
    $TRANSFER_DETAILS \
    $SIGNATURE \
    --private-key $USER_PRIVATE_KEY \
    --rpc-url $RPC_URL \
    --json | jq -r '.transactionHash')

echo "交易哈希: $TX_HASH"

# 3. 等待交易确认
echo "⏳ 等待交易确认..."
cast receipt $TX_HASH --rpc-url $RPC_URL > /dev/null

echo "✅ 交易确认成功!"

# 4. 查询存款后余额
echo ""
echo "📊 查询存款后余额..."
BALANCE_AFTER=$(cast call $TOKEN_BANK_ADDRESS \
    "getBalance(address)(uint256)" \
    $(cast wallet address --private-key $USER_PRIVATE_KEY) \
    --rpc-url $RPC_URL)

echo "存款后余额: $(cast to-dec $BALANCE_AFTER) wei"

# 5. 计算差值
DIFF=$(($(cast to-dec $BALANCE_AFTER) - $(cast to-dec $BALANCE_BEFORE)))
echo "存款增加: $DIFF wei"

echo ""
echo "🎉 depositWithPermit2 调用成功!" 