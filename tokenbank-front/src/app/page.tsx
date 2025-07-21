"use client";
import { useState } from "react";
import { WagmiConfig, createConfig, useAccount, useConnect, useDisconnect, http } from "wagmi";
import { injected } from "wagmi/connectors";
import { useReadContract, useWriteContract } from "wagmi";
import { tokenBankAbi } from "../../abi/TokenBank";
import { myTokenAbi } from "../../abi/MyToken";
import { Button, Input, Card, Typography, message, Space, Layout } from "antd";
import { parseUnits, formatUnits } from "viem";
import { sepolia } from "wagmi/chains";

const TOKENBANK_ADDRESS = "0xaE7Cdc7f2B32f69aD600661CF61b9EA8E0573B00" as `0x${string}`;
const TOKEN_ADDRESS = "0x5451F618691C10FD757a1341CBD3aad2dC844823" as `0x${string}`;

const config = createConfig({
  chains: [sepolia],
  connectors: [injected()],
  transports: {
    [sepolia.id]: http(),
  },
});

const { Header, Content, Footer } = Layout;
const { Title, Text } = Typography;

function TokenBankApp() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

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
  const { writeContract: approve } = useWriteContract();
  const { writeContract: deposit } = useWriteContract();

  // 取款
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const { writeContract: withdraw } = useWriteContract();

  // 授权并存款
  const handleDeposit = async () => {
    try {
      await approve({
        address: TOKEN_ADDRESS,
        abi: myTokenAbi,
        functionName: "approve",
        args: [TOKENBANK_ADDRESS, parseUnits(depositAmount, 18)],
      });
      await deposit({
        address: TOKENBANK_ADDRESS,
        abi: tokenBankAbi,
        functionName: "deposit",
        args: [parseUnits(depositAmount, 18)],
      });
      message.success("存款成功！");
      refetchTokenBalance && refetchTokenBalance();
      refetchBankBalance && refetchBankBalance();
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
        args: [parseUnits(withdrawAmount, 18)],
      });
      message.success("取款成功！");
      refetchTokenBalance && refetchTokenBalance();
      refetchBankBalance && refetchBankBalance();
    } catch (e) {
      message.error("取款失败");
    }
  };

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header>
        <Title style={{ color: "#fff", margin: 0 }} level={3}>Token Bank 前端界面</Title>
      </Header>
      <Content style={{ padding: 24, maxWidth: 500, margin: "0 auto" }}>
        <Card>
          {!isConnected ? (
            <Button type="primary" onClick={() => connect({ connector: connectors[0] })}>连接钱包</Button>
          ) : (
            <Space direction="vertical" style={{ width: "100%" }}>
              <Text>钱包地址：{address}</Text>
              <Button onClick={() => disconnect()}>断开连接</Button>
            </Space>
          )}
        </Card>

        {isConnected && (
          <>
            <Card style={{ marginTop: 24 }}>
              <Space direction="vertical" size="middle" style={{ width: "100%" }}>
                <Text>当前Token余额：{typeof tokenBalance === "bigint" ? formatUnits(tokenBalance, 18) : "加载中..."}</Text>
                <Text>TokenBank存款余额：{typeof bankBalance === "bigint" ? formatUnits(bankBalance, 18) : "加载中..."}</Text>
              </Space>
            </Card>

            <Card title="存款到TokenBank" style={{ marginTop: 24 }}>
              <Space>
                <Input
                  type="number"
                  value={depositAmount}
                  onChange={e => setDepositAmount(e.target.value)}
                  placeholder="输入存款数量"
                  style={{ width: 200 }}
                />
                <Button type="primary" onClick={handleDeposit}>授权并存款</Button>
              </Space>
            </Card>

            <Card title="从TokenBank取款" style={{ marginTop: 24 }}>
              <Space>
                <Input
                  type="number"
                  value={withdrawAmount}
                  onChange={e => setWithdrawAmount(e.target.value)}
                  placeholder="输入取款数量"
                  style={{ width: 200 }}
                />
                <Button type="primary" onClick={handleWithdraw}>取款</Button>
              </Space>
            </Card>
          </>
        )}
      </Content>
      <Footer style={{ textAlign: "center" }}>Token Bank ©2024</Footer>
    </Layout>
  );
}

export default function App() {
  return (
    <WagmiConfig config={config}>
      <TokenBankApp />
    </WagmiConfig>
  );
} 