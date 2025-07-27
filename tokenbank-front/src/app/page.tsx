"use client";
import { useState, useMemo } from "react";
import { useAccount, useConnect, useDisconnect, useBalance } from "wagmi";
import { useReadContract, useWriteContract, useSignTypedData } from "wagmi";
import { tokenBankAbi } from "../../abi/TokenBank";
import { eIP2612TokenAbi } from "../../abi/eIPToken";
import { Button, Input, Card, Typography, Space, message, Divider, Row, Col, Tooltip, Switch } from "antd";
import { parseUnits, formatUnits } from "viem";

const TOKENBANK_ADDRESS = "0x3B8C8BAEf7f3885159A347B8515AEB8123A76aD5" as `0x${string}`;
const TOKEN_ADDRESS = "0x4e7C8e2c43aC1d69811D2d00d5AD385dB43899fa" as `0x${string}`;
const TOKEN_SYMBOL = "BAPE";
const TOKEN_DECIMALS = 18;

export default function TokenBankApp() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { data: ethBalance } = useBalance({ address, chainId: 11155111 });

  // 配置检查和调试信息
  console.log("🔧 前端配置信息:");
  console.log("- TOKEN_ADDRESS:", TOKEN_ADDRESS);
  console.log("- TOKENBANK_ADDRESS:", TOKENBANK_ADDRESS);
  console.log("- 注意：如果使用旧的MyToken地址，签名存款将无法工作！");

  // 查询 Token 余额
  const { data: tokenBalance, refetch: refetchTokenBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
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

  // 查询用户的nonce（用于签名）
  const { data: nonces } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "nonces",
    args: [address as `0x${string}`],
  });

  // 查询DOMAIN_SEPARATOR（用于签名）
  const { data: domainSeparator } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: eIP2612TokenAbi,
    functionName: "DOMAIN_SEPARATOR",
  });

  // 存款相关状态
  const [depositAmount, setDepositAmount] = useState("");
  const [usePermitDeposit, setUsePermitDeposit] = useState(false);

  // 合约写入操作
  const { writeContract: approve, isPending: isApproving } = useWriteContract();
  const { writeContract: deposit, isPending: isDepositing } = useWriteContract();
  const { writeContract: permitDeposit, isPending: isPermitDepositing } = useWriteContract();

  // 取款
  const [withdrawAmount, setWithdrawAmount] = useState("");
  const { writeContract: withdraw, isPending: isWithdrawing } = useWriteContract();

  // 签名相关
  const { signTypedData, isPending: isSigning } = useSignTypedData();

  // 传统授权并存款
  const handleDeposit = async () => {
    try {
      await approve({
        address: TOKEN_ADDRESS,
        abi: eIP2612TokenAbi,
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
      refetchTokenBalance?.();
      refetchBankBalance?.();
      setDepositAmount("");
    } catch (error) {
      console.error("存款失败:", error);
      message.error("存款失败");
    }
  };

  // 签名存款
  const handlePermitDeposit = async () => {
    console.log("🚀 开始签名存款流程");
    console.log("- address:", address);
    console.log("- nonces:", nonces);
    console.log("- domainSeparator:", domainSeparator);
    console.log("- depositAmount:", depositAmount);

    if (!address) {
      message.error("未连接钱包");
      return;
    }

    if (nonces === undefined || nonces === null) {
      message.error("无法获取nonces信息");
      return;
    }

    if (!domainSeparator) {
      message.error("无法获取DOMAIN_SEPARATOR信息");
      return;
    }

    if (!depositAmount || Number(depositAmount) <= 0) {
      message.error("请输入有效的存款金额");
      return;
    }

    try {
      const amount = parseUnits(depositAmount, TOKEN_DECIMALS);
      const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600); // 1小时后过期

      // 准备签名数据
      const domain = {
        name: "BapeToken",
        version: "1",
        chainId: 11155111, // Sepolia
        verifyingContract: TOKEN_ADDRESS,
      };

      console.log("🔍 签名存款调试信息:");
      console.log("- address:", address);
      console.log("- nonces:", nonces?.toString());
      console.log("- domainSeparator:", domainSeparator);
      console.log("- amount:", amount.toString());
      console.log("- deadline:", deadline.toString());
      console.log("- domain:", domain);

      const types = {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      };

      const value = {
        owner: address,
        spender: TOKENBANK_ADDRESS,
        value: amount,
        nonce: nonces,
        deadline: deadline,
      };

      console.log("📝 准备签名的数据:");
      console.log("- types:", types);
      console.log("- value:", value);
      console.log("- 即将调用signTypedData...");

      // 生成签名
      console.log("🖊️ 调用signTypedData");
      signTypedData(
        { domain, types, primaryType: "Permit", message: value },
        {
          onSuccess: async (signature: `0x${string}`) => {
                          console.log("✅ 签名成功:", signature);
              try {
                // 解析签名
                const r = signature.slice(0, 66) as `0x${string}`;
                const s = `0x${signature.slice(66, 130)}` as `0x${string}`;
                const v = parseInt(signature.slice(130, 132), 16);

                console.log("🔧 解析签名:");
                console.log("- r:", r);
                console.log("- s:", s); 
                console.log("- v:", v);

                console.log("📞 调用permitDeposit合约方法...");
                // 调用permitDeposit
                await permitDeposit({
                  address: TOKENBANK_ADDRESS,
                  abi: tokenBankAbi,
                  functionName: "permitDeposit",
                  args: [amount, deadline, v, r, s],
                });

                console.log("🎉 permitDeposit调用成功!");
                message.success("签名存款成功！");
                refetchTokenBalance?.();
                refetchBankBalance?.();
                setDepositAmount("");
              } catch (error) {
                console.error("❌ Permit deposit 合约调用错误:", error);
                message.error("签名存款失败: " + (error as Error).message);
              }
            },
            onError: (error: Error) => {
              console.error("❌ 签名被用户拒绝或失败:", error);
              message.error("签名失败: " + error.message);
            },
        }
      );
    } catch (e) {
      console.error("Error:", e);
      message.error("签名存款失败");
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
      refetchTokenBalance?.();
      refetchBankBalance?.();
      setWithdrawAmount("");
    } catch (error) {
      console.error("取款失败:", error);
      message.error("取款失败");
    }
  };

  // 按钮点击包装函数
  const handleDepositClick = () => {
    console.log("🖱️ 存款按钮被点击");
    console.log("- usePermitDeposit:", usePermitDeposit);
    console.log("- depositAmount:", depositAmount);
    if (usePermitDeposit) {
      console.log("📝 执行签名存款");
      handlePermitDeposit();
    } else {
      console.log("💰 执行传统存款");
      handleDeposit();
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
          
          {/* 配置状态提示 */}
          <div style={{ 
            background: "#fff7e6", 
            border: "1px solid #ffd591", 
            borderRadius: 6, 
            padding: 12, 
            marginBottom: 16,
            fontSize: 13
          }}>
            <div style={{ fontWeight: 600, color: "#d4690e", marginBottom: 4 }}>⚠️ 配置提醒</div>
            <div style={{ color: "#8c5e07" }}>
              当前TOKEN_ADDRESS: {TOKEN_ADDRESS.slice(0, 10)}...{TOKEN_ADDRESS.slice(-8)}
              <br />
              如果签名存款无反应，请确认使用的是支持EIP-2612的token地址
            </div>
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
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 }}>
              <div style={{ fontWeight: 500 }}>存款到TokenBank</div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <Typography.Text style={{ fontSize: 12 }}>传统存款</Typography.Text>
                <Switch 
                  size="small"
                  checked={usePermitDeposit}
                  onChange={setUsePermitDeposit}
                  disabled={!isConnected}
                />
                <Typography.Text style={{ fontSize: 12, color: usePermitDeposit ? "#1890ff" : "#666" }}>
                  签名存款 {usePermitDeposit && "✨"}
                </Typography.Text>
              </div>
            </div>
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
                onClick={handleDepositClick}
                loading={usePermitDeposit ? (isSigning || isPermitDepositing) : (isApproving || isDepositing)}
                disabled={!isConnected || !depositAmount || Number(depositAmount) <= 0}
              >
                {usePermitDeposit ? "签名存款" : "存款"}
              </Button>
            </Space.Compact>
            {usePermitDeposit && (
              <Typography.Text type="secondary" style={{ fontSize: 11, display: "block", marginTop: 4 }}>
                💡 签名存款无需预先授权，节省一次交易的gas费用
              </Typography.Text>
            )}
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