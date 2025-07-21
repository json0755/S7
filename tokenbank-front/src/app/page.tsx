"use client";
import { useState, useMemo } from "react";
import { useAccount, useConnect, useDisconnect, useBalance } from "wagmi";
import { useReadContract, useWriteContract } from "wagmi";
import { tokenBankAbi } from "../../abi/TokenBank";
import { myTokenAbi } from "../../abi/MyToken";
import { Button, Input, Card, Typography, Space, message, Divider, Row, Col, Tooltip } from "antd";
import { parseUnits, formatUnits } from "viem";

const TOKENBANK_ADDRESS = "0x80268b191986b614989B5484A860710b2DAb9D82" as `0x${string}`;
const TOKEN_ADDRESS = "0x15A43C6eed098cD749E33D269eb3705Be5EC02A0" as `0x${string}`;
const TOKEN_SYMBOL = "BAPE";
const TOKEN_DECIMALS = 18;

export default function TokenBankApp() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });

  // 查询 Token 余额
  const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: myTokenAbi,
    functionName: "balanceOf",
    args: [address as `0x${string}`],
  });

  // 查询用户在 TokenBank 的存款
  const { data: bankBalance, refetch: refetchBankBalance } = useReadContract({
    address: TOKENBANK_ADDRESS,
    abi: tokenBankAbi,
    functionName: "balances",
    args: [address as `0x${string}`],
  });

  // 存款
  const [depositAmount, setDepositAmount] = useState("");
  const { writeContract: approve, isPending: isApproving } = useWriteContract();
  const { writeContract: deposit, isPending: isDepositing } = useWriteContract();

  // 取款
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const { writeContract: withdraw, isPending: isWithdrawing } = useWriteContract();

  // 授权并存款
  const handleDeposit = async () => {
    try {
      await approve({
        address: TOKEN_ADDRESS,
        abi: myTokenAbi,
        functionName: "approve",
        args: [TOKENBANK_ADDRESS, parseUnits(depositAmount, TOKEN_DECIMALS)],
      });
      await deposit({
        address: TOKENBANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "deposit",
        args: [parseUnits(depositAmount, TOKEN_DECIMALS)],
      });
      message.success("存款成功！");
      refetchTokenBalance && refetchTokenBalance();
      refetchBankBalance && refetchBankBalance();
      setDepositAmount("");
    } catch (e) {
      message.error("存款失败");
    }
  };

  // 取款
  const handleWithdraw = async () => {
    try {
      await withdraw({
        address: TOKENBANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "withdraw",
        args: [parseUnits(withdrawAmount, TOKEN_DECIMALS)],
      });
      message.success("取款成功！");
      refetchTokenBalance && refetchTokenBalance();
      refetchBankBalance && refetchBankBalance();
      setWithdrawAmount("");
    } catch (e) {
      message.error("取款失败");
    }
  };

  // 格式化余额
  const walletToken = useMemo(() => typeof tokenBalance === "bigint" ? formatUnits(tokenBalance, TOKEN_DECIMALS) : "0", [tokenBalance]);
  const bankToken = useMemo(() => typeof bankBalance === "bigint" ? formatUnits(bankBalance, TOKEN_DECIMALS) : "0", [bankBalance]);
  const eth = useMemo(() => ethBalance ? Number(formatUnits(ethBalance.value, 18)).toFixed(3) : "-", [ethBalance]);

  return (
    <div style={{ minHeight: "100vh", background: "#f5f6f8" }}>
      <div style={{ maxWidth: 480, margin: "0 auto", paddingTop: 32 }}>
        <Typography.Title level={2} style={{ textAlign: "center", marginBottom: 16 }}>TokenBank DApp</Typography.Title>
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginBottom: 16 }}>
          <Button type="default" shape="round" size="small" disabled>Sepolia</Button>
          <Button type="default" shape="round" size="small" disabled>
            {eth} ETH
          </Button>
          <Button type="default" shape="round" size="small" disabled>
            {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : "未连接"}
          </Button>
        </div>
        <Card style={{ borderRadius: 16, boxShadow: "0 2px 8px #eee" }}>
          <div style={{ textAlign: "center", marginBottom: 8 }}>
            <Typography.Title level={4} style={{ margin: 0 }}>TokenBank</Typography.Title>
            <Typography.Text type="secondary" style={{ fontSize: 13 }}>网络: Sepolia</Typography.Text>
          </div>
          <Row gutter={16} style={{ marginBottom: 16 }}>
            <Col span={12}>
              <div style={{ background: "#e6f0fa", borderRadius: 8, padding: 16, textAlign: "center" }}>
                <div style={{ color: "#888", fontSize: 14 }}>钱包余额</div>
                <div style={{ fontWeight: 700, fontSize: 28 }}>{walletToken} {TOKEN_SYMBOL}</div>
              </div>
            </Col>
            <Col span={12}>
              <div style={{ background: "#eafae6", borderRadius: 8, padding: 16, textAlign: "center" }}>
                <div style={{ color: "#888", fontSize: 14 }}>银行存款</div>
                <div style={{ fontWeight: 700, fontSize: 28 }}>{bankToken} {TOKEN_SYMBOL}</div>
              </div>
            </Col>
          </Row>
          {!isConnected ? (
            <Button type="primary" block onClick={() => connect({ connector: connectors[0] })} style={{ marginBottom: 8 }}>连接钱包</Button>
          ) : (
            <Button block onClick={() => disconnect()} style={{ marginBottom: 8 }}>断开连接</Button>
          )}
          <Divider style={{ margin: "16px 0" }} />
          <div style={{ marginBottom: 12 }}>
            <div style={{ fontWeight: 500, marginBottom: 4 }}>存款到TokenBank</div>
            <Space.Compact style={{ width: "100%" }}>
              <Input
                type="number"
                min={0}
                value={depositAmount}
                onChange={e => setDepositAmount(e.target.value)}
                placeholder="输入存款金额"
                disabled={!isConnected}
              />
              <Button
                type="primary"
                onClick={handleDeposit}
                loading={isApproving || isDepositing}
                disabled={!isConnected || !depositAmount || Number(depositAmount) <= 0}
              >存款</Button>
            </Space.Compact>
          </div>
          <div style={{ marginBottom: 12 }}>
            <div style={{ fontWeight: 500, marginBottom: 4 }}>从TokenBank取款</div>
            <Space.Compact style={{ width: "100%" }}>
              <Input
                type="number"
                min={0}
                value={withdrawAmount}
                onChange={e => setWithdrawAmount(e.target.value)}
                placeholder="输入取款金额"
                disabled={!isConnected}
              />
              <Button
                type="primary"
                onClick={handleWithdraw}
                loading={isWithdrawing}
                disabled={!isConnected || !withdrawAmount || Number(withdrawAmount) <= 0}
              >取款</Button>
            </Space.Compact>
          </div>
          <Divider style={{ margin: "16px 0" }} />
          <div style={{ color: "#888", fontSize: 13 }}>
            <span>合约地址：</span>
            <Tooltip title={TOKENBANK_ADDRESS}><span style={{ fontFamily: "monospace" }}>{TOKENBANK_ADDRESS.slice(0, 8)}...{TOKENBANK_ADDRESS.slice(-6)}</span></Tooltip>
          </div>
        </Card>
      </div>
    </div>
  );
} 