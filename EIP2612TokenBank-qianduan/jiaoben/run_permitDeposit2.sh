#!/bin/bash
cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 \
  "permitDeposit2(uint256,address,uint160,uint48,uint48,uint256,bytes)" \
  1000000000000000000 \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  1000000000000000000 \
  1753873660 \
  3 \
  1753790860 \
  0x6e76af86a22a492b269f0ed87101d03bac905fafb1d7f9bab63468ebbb382d8e569d377c3f50b3eacc38fa75784322c635f945a0536a33feab2f56c6b43ca1071c \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --rpc-url http://localhost:8545
