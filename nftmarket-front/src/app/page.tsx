"use client";

import React, { useState } from "react";
import { Button, Input, Card, Typography, message, Form } from "antd";
import { nftMarketAbi } from "../abi/NFTMarket";
import { myTokenAbi } from "../abi/MyToken";
import { myNFTAbi } from "../abi/MyNFT";
import { parseUnits } from "viem";
import {
  useAccount,
  useConnect,
  useDisconnect,
} from "wagmi";

const NFTMARKET_ADDRESS = "0xYourNFTMarketAddress" as `0x${string}`;
const TOKEN_ADDRESS = "0xYourTokenAddress" as `0x${string}`;
const NFT_ADDRESS = "0xYourNFTAddress" as `0x${string}`;
const TOKEN_SYMBOL = "BAPE";
const TOKEN_DECIMALS = 18;

function NFTMarketApp() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  // 上架 NFT
  const [listTokenId, setListTokenId] = useState("");
  const [listPrice, setListPrice] = useState("");

  // 购买 NFT
  const [buyTokenId, setBuyTokenId] = useState("");

  // 上架操作
  const handleList = async () => {
    if (!isConnected) return message.error("请先连接钱包");
    try {
      message.info("请在钱包中确认上架交易");
      // ...合约交互逻辑（略，需集成 viem/ethers）
      setListTokenId("");
      setListPrice("");
    } catch (e: any) {
      message.error(e?.reason || e?.message || "上架失败");
    }
  };

  // 购买操作
  const handleBuy = async () => {
    if (!isConnected) return message.error("请先连接钱包");
    try {
      message.info("请在钱包中确认购买交易");
      // ...合约交互逻辑（略，需集成 viem/ethers）
      setBuyTokenId("");
    } catch (e: any) {
      message.error(e?.reason || e?.message || "购买失败");
    }
  };

  return (
    <div style={{ minHeight: "100vh", background: "#f5f6f8" }}>
      <div style={{ maxWidth: 520, margin: "0 auto", paddingTop: 32 }}>
        <Typography.Title level={2} style={{ textAlign: "center", marginBottom: 16 }}>NFTMarket DApp</Typography.Title>
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginBottom: 16 }}>
          {!isConnected ? (
            <Button type="primary" onClick={() => connect({ connector: connectors[0] })}>
              WalletConnect扫码登录
            </Button>
          ) : (
            <>
              <span style={{ color: "#888" }}>已连接: {address?.slice(0, 6)}...{address?.slice(-4)}</span>
              <Button onClick={() => disconnect()}>断开连接</Button>
            </>
          )}
        </div>
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee", marginBottom: 24 }}>
          <Typography.Title level={4}>上架 NFT</Typography.Title>
          <Form layout="vertical">
            <Form.Item label="NFT TokenId">
              <Input
                value={listTokenId}
                onChange={e => setListTokenId(e.target.value)}
                placeholder="输入你拥有的NFT TokenId"
                disabled={!isConnected}
              />
            </Form.Item>
            <Form.Item label={`上架价格 (${TOKEN_SYMBOL})`}>
              <Input
                value={listPrice}
                onChange={e => setListPrice(e.target.value)}
                placeholder={`输入上架价格（${TOKEN_SYMBOL}）`}
                disabled={!isConnected}
              />
            </Form.Item>
            <Button type="primary" block onClick={handleList} disabled={!isConnected || !listTokenId || !listPrice}>
              上架
            </Button>
          </Form>
        </Card>
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee" }}>
          <Typography.Title level={4}>购买 NFT</Typography.Title>
          <Form layout="vertical">
            <Form.Item label="NFT TokenId">
              <Input
                value={buyTokenId}
                onChange={e => setBuyTokenId(e.target.value)}
                placeholder="输入要购买的NFT TokenId"
                disabled={!isConnected}
              />
            </Form.Item>
            <Button type="primary" block onClick={handleBuy} disabled={!isConnected || !buyTokenId}>
              购买
            </Button>
          </Form>
        </Card>
      </div>
    </div>
  );
}

export default function App() {
  return <NFTMarketApp />;
}
