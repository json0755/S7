"use client";

import React, { useState } from "react";
import { Button, Input, Card, Typography, message, Form } from "antd";
import { nftMarketAbi } from "../abi/NFTMarket";
import { eIP2612TokenAbi } from "../abi/eIPToken";
import { myNFTAbi } from "../abi/MyNFT";
import { parseUnits } from "viem";
import {
  useAccount,
  useConnect,
  useDisconnect,
} from "wagmi";
import { writeContract } from "wagmi/actions";
import { config } from "./wagmiConfig";

const NFTMARKET_ADDRESS = "0x6a61C055ad20d83DF2Fa7320dd37A149C6D7f556" as `0x${string}`;
const TOKEN_ADDRESS = "0xBe8446a91ec13Cd2d506D90E515635891B736b54" as `0x${string}`;
const NFT_ADDRESS = "0xdE57605aF3382564341d2fD4065156d0960E7d26" as `0x${string}`;
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

  // 白名单购买 NFT
  const [whitelistTokenId, setWhitelistTokenId] = useState("");
  const [whitelistNonce, setWhitelistNonce] = useState("");
  const [whitelistSignature, setWhitelistSignature] = useState("");

  // 上架操作
  const handleList = async () => {
    if (!isConnected) return message.error("请先连接钱包");
    if (!listTokenId || !listPrice) return message.error("请填写完整信息");
    try {
      console.log("listTokenId", listTokenId, NFT_ADDRESS)
      // 1. 先授权 NFTMarket 合约操作你的 NFT
      await writeContract(config, {
        address: NFT_ADDRESS,
        abi: myNFTAbi,
        functionName: "approve",
        args: [NFTMARKET_ADDRESS, BigInt(listTokenId)],
      });
      // 2. 调用 list 上架
      await writeContract(config, {
        address: NFTMARKET_ADDRESS,
        abi: nftMarketAbi,
        functionName: "list",
        args: [NFT_ADDRESS, BigInt(listTokenId), parseUnits(listPrice, TOKEN_DECIMALS)],
      });
      message.success("上架成功");
      setListTokenId("");
      setListPrice("");
    } catch (e: any) {
      message.error(e?.reason || e?.message || "上架失败");
    }
  };

  // 购买操作
  const handleBuy = async () => {
    if (!isConnected) return message.error("请先连接钱包");
    if (!buyTokenId) return message.error("请填写TokenId");
    try {
      // 1. 查询链上该NFT的价格
      const listing: any = await (await import("wagmi/actions")).readContract(config, {
        address: NFTMARKET_ADDRESS,
        abi: nftMarketAbi,
        functionName: "listings",
        args: [NFT_ADDRESS, BigInt(String(buyTokenId))],
      });
      const price = listing.price ?? (Array.isArray(listing) ? listing[3] : undefined);
      if (!price || price === "0" || price === BigInt(0)) return message.error("该NFT未上架或价格为0");

      // 2. 先授权 NFTMarket 合约消费你的 Token
      await writeContract(config, {
        address: TOKEN_ADDRESS,
        abi: eIP2612TokenAbi,
        functionName: "approve",
        args: [NFTMARKET_ADDRESS, price],
      });

      // 3. 调用 buyNFT
      await writeContract(config, {
        address: NFTMARKET_ADDRESS,
        abi: nftMarketAbi,
        functionName: "buyNFT",
        args: [NFT_ADDRESS, BigInt(String(buyTokenId))],
      });
      message.success("购买成功");
      setBuyTokenId("");
    } catch (e: any) {
      message.error(e?.reason || e?.message || "购买失败");
    }
  };

  // 白名单购买操作
  const handleWhitelistBuy = async () => {
    if (!isConnected) return message.error("请先连接钱包");
    if (!whitelistTokenId || !whitelistNonce || !whitelistSignature) {
      return message.error("请填写完整的白名单购买信息");
    }
    try {
      // 1. 查询链上该NFT的价格
      const listing: any = await (await import("wagmi/actions")).readContract(config, {
        address: NFTMARKET_ADDRESS,
        abi: nftMarketAbi,
        functionName: "listings",
        args: [NFT_ADDRESS, BigInt(String(whitelistTokenId))],
      });
      const price = listing.price ?? (Array.isArray(listing) ? listing[3] : undefined);
      if (!price || price === "0" || price === BigInt(0)) return message.error("该NFT未上架或价格为0");

      // 2. 先授权 NFTMarket 合约消费你的 Token
      await writeContract(config, {
        address: TOKEN_ADDRESS,
        abi: eIP2612TokenAbi,
        functionName: "approve",
        args: [NFTMARKET_ADDRESS, price],
      });

      // 3. 调用 permitBuy 白名单购买
      await writeContract(config, {
        address: NFTMARKET_ADDRESS,
        abi: nftMarketAbi,
        functionName: "permitBuy",
        args: [NFT_ADDRESS, BigInt(String(whitelistTokenId)), BigInt(String(whitelistNonce)), whitelistSignature as `0x${string}`],
      });
      message.success("白名单购买成功");
      setWhitelistTokenId("");
      setWhitelistNonce("");
      setWhitelistSignature("");
    } catch (e: any) {
      message.error(e?.reason || e?.message || "白名单购买失败");
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
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee", marginBottom: 24 }}>
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
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee" }}>
          <Typography.Title level={4}>白名单购买 NFT</Typography.Title>
          <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
            需要项目方签名授权才能购买
          </Typography.Text>
          <Form layout="vertical">
            <Form.Item label="NFT TokenId">
              <Input
                value={whitelistTokenId}
                onChange={e => setWhitelistTokenId(e.target.value)}
                placeholder="输入要购买的NFT TokenId"
                disabled={!isConnected}
              />
            </Form.Item>
            <Form.Item label="Nonce">
              <Input
                value={whitelistNonce}
                onChange={e => setWhitelistNonce(e.target.value)}
                placeholder="输入签名时使用的 nonce"
                disabled={!isConnected}
              />
            </Form.Item>
            <Form.Item label="项目方签名">
              <Input.TextArea
                value={whitelistSignature}
                onChange={e => setWhitelistSignature(e.target.value)}
                placeholder="输入项目方提供的签名"
                disabled={!isConnected}
                rows={3}
              />
            </Form.Item>
            <Button 
              type="primary" 
              block 
              onClick={handleWhitelistBuy} 
              disabled={!isConnected || !whitelistTokenId || !whitelistNonce || !whitelistSignature}
            >
              白名单购买
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
