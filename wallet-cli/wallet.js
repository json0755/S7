#!/usr/bin/env node

import { Wallet, JsonRpcProvider, Contract, parseUnits, formatEther } from "ethers";
import fs from "fs";

const SEPOLIA_RPC = "https://eth-sepolia.public.blastapi.io";
const provider = new JsonRpcProvider(SEPOLIA_RPC);
const WALLET_FILE = "wallet.json";
const ERC20_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function transfer(address,uint256) returns (bool)",
  "function decimals() view returns (uint8)"
];

// 1. 生成钱包
async function generateWallet() {
  const wallet = Wallet.createRandom();
  fs.writeFileSync(WALLET_FILE, JSON.stringify({
    privateKey: wallet.privateKey,
    address: wallet.address
  }, null, 2));
  console.log("新钱包已生成:", wallet.address);
}

// 2. 查询余额
async function queryBalance() {
  const { privateKey } = JSON.parse(fs.readFileSync(WALLET_FILE));
  const wallet = new Wallet(privateKey, provider);
  const ethBalance = await provider.getBalance(wallet.address);
  console.log(`ETH余额: ${formatEther(ethBalance)} ETH`);
}

// 3. 构建 ERC20 EIP-1559 转账交易（不签名不发送）
async function buildERC20Tx(contractAddr, to, amount) {
  const { privateKey } = JSON.parse(fs.readFileSync(WALLET_FILE));
  const wallet = new Wallet(privateKey, provider);
  const erc20 = new Contract(contractAddr, ERC20_ABI, provider);
  const decimals = await erc20.decimals();
  const value = parseUnits(amount, decimals);

  // 构造 data 字段
  const data = erc20.interface.encodeFunctionData("transfer", [to, value]);

  // 获取 gas 相关参数
  const [maxFeePerGas, maxPriorityFeePerGas, nonce, chainId] = await Promise.all([
    provider.getFeeData().then(f => f.maxFeePerGas),
    provider.getFeeData().then(f => f.maxPriorityFeePerGas),
    provider.getTransactionCount(wallet.address),
    provider.getNetwork().then(n => n.chainId)
  ]);

  const tx = {
    to: contractAddr,
    data,
    value: 0,
    nonce,
    chainId,
    type: 2, // EIP-1559
    maxFeePerGas,
    maxPriorityFeePerGas,
    gasLimit: 100000 // 可根据实际情况调整
  };
  fs.writeFileSync("erc20tx.json", JSON.stringify(tx, null, 2));
  console.log("已构建原始交易，已保存到 erc20tx.json");
}

// 4. 用钱包私钥对交易签名
async function signTx() {
  const { privateKey } = JSON.parse(fs.readFileSync(WALLET_FILE));
  const wallet = new Wallet(privateKey, provider);
  const tx = JSON.parse(fs.readFileSync("erc20tx.json"));
  const signedTx = await wallet.signTransaction(tx);
  fs.writeFileSync("signedtx.txt", signedTx);
  console.log("已签名，签名结果已保存到 signedtx.txt");
}

// 5. 发送已签名交易
async function sendTx() {
  const rawTx = fs.readFileSync("signedtx.txt", "utf-8");
  const txHash = await provider.sendTransaction(rawTx);
  console.log("已发送，交易哈希:", txHash.hash);
}

async function main() {
  const [,, cmd, ...args] = process.argv;
  if (cmd === "generate") {
    await generateWallet();
  } else if (cmd === "balance") {
    await queryBalance();
  } else if (cmd === "erc20tx") {
    if (args.length < 3) {
      console.log("用法: node wallet.js erc20tx <ERC20合约地址> <收款地址> <数量>");
      return;
    }
    await buildERC20Tx(args[0], args[1], args[2]);
  } else if (cmd === "sign") {
    await signTx();
  } else if (cmd === "send") {
    await sendTx();
  } else {
    console.log("用法:");
    console.log("  node wallet.js generate");
    console.log("  node wallet.js balance");
    console.log("  node wallet.js erc20tx <ERC20合约地址> <收款地址> <数量>");
    console.log("  node wallet.js sign");
    console.log("  node wallet.js send");
  }
}

main();