'use client';

import React, { useState, useEffect } from 'react';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { Button, Card, Input, message, Typography, Space, Divider, Statistic, Row, Col } from 'antd';
import { WalletOutlined, BankOutlined, SendOutlined, SwapOutlined } from '@ant-design/icons';
import { ethers } from 'ethers';
import { 
  createTokenBankContract, 
  createTokenContract, 
  createPermit2Contract,
  createPermit2Signature,
  formatAmount, 
  parseAmount, 
  truncateAddress, 
  generateNonce, 
  getDeadline,
  getExpiration,
  getSigDeadline
} from '@/utils/ethers';
import { CONTRACTS } from '@/config/contracts';

const { Title, Text } = Typography;

// 声明全局window.ethereum
declare global {
  interface Window {
    ethereum?: any;
  }
}

export default function Home() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  const [depositAmount, setDepositAmount] = useState('');
  const [isStandardDepositLoading, setIsStandardDepositLoading] = useState(false);
  const [isPermit2DepositLoading, setIsPermit2DepositLoading] = useState(false);
  const [isWithdrawLoading, setIsWithdrawLoading] = useState(false);
  const [tokenBalance, setTokenBalance] = useState<bigint>(0n);
  const [bankBalance, setBankBalance] = useState<bigint>(0n);
  const [tokenSymbol, setTokenSymbol] = useState('');
  const [tokenDecimals, setTokenDecimals] = useState(18);

  // 连接钱包
  const handleConnect = () => {
    if (window.ethereum) {
      connect({ connector: connectors[0] });
    } else {
      message.error('请安装MetaMask钱包');
    }
  };

  // 断开连接
  const handleDisconnect = () => {
    disconnect();
  };

  // 加载余额
  const loadBalances = async () => {
    if (!address || !window.ethereum) return;

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const tokenContract = createTokenContract(signer);
      const tokenBankContract = createTokenBankContract(signer);

      const [balance, bankBalance, symbol, decimals] = await Promise.all([
        tokenContract.balanceOf(address),
        tokenBankContract.balanceOf(address),
        tokenContract.symbol(),
        tokenContract.decimals()
      ]);

      setTokenBalance(balance);
      setBankBalance(bankBalance);
      setTokenSymbol(symbol);
      setTokenDecimals(decimals);
    } catch (error) {
      console.error('加载余额失败:', error);
    }
  };

  // 标准存款
  const handleStandardDeposit = async () => {
    if (!address || !depositAmount || !window.ethereum) {
      message.error('请连接钱包并输入存款金额');
      return;
    }

    setIsStandardDepositLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const tokenContract = createTokenContract(signer);
      const tokenBankContract = createTokenBankContract(signer);

      const amount = parseAmount(depositAmount, tokenDecimals);

      // 检查余额
      const balance = await tokenContract.balanceOf(address);
      if (balance < amount) {
        message.error('余额不足');
        return;
      }

      // 授权
      message.info('正在授权...');
      const approveTx = await tokenContract.approve(CONTRACTS.SEPOLIA.TOKEN_BANK, amount);
      await approveTx.wait();

      // 存款
      message.info('正在存款...');
      const depositTx = await tokenBankContract.deposit(amount, address);
      await depositTx.wait();

      message.success('标准存款成功!');
      loadBalances();
    } catch (error) {
      message.error('标准存款失败');
      console.error(error);
    } finally {
      setIsStandardDepositLoading(false);
    }
  };

  // Permit2签名存款
  const handlePermit2Deposit = async () => {
    if (!address || !depositAmount || !window.ethereum) {
      message.error('请连接钱包并输入存款金额');
      return;
    }

    setIsPermit2DepositLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const tokenContract = createTokenContract(signer);
      const tokenBankContract = createTokenBankContract(signer);

      const amount = parseAmount(depositAmount, tokenDecimals);

      // 检查余额
      const balance = await tokenContract.balanceOf(address);
      if (balance < amount) {
        message.error('余额不足');
        return;
      }

      // 生成Permit2参数
      const nonce = generateNonce();
      const deadline = getDeadline();
      const expiration = getExpiration(); // Permit的过期时间
      const sigDeadline = getSigDeadline(); // 签名的截止时间

      message.info('正在创建签名...');
      const signature = await createPermit2Signature(
        signer,
        CONTRACTS.SEPOLIA.EIP2612_TOKEN,
        CONTRACTS.SEPOLIA.TOKEN_BANK,
        amount,
        nonce,
        expiration,
        sigDeadline
      );

      // 执行Permit2存款
      message.info('正在执行Permit2存款...');
      const depositTx = await tokenBankContract.permitDeposit2(
        amount,           // assets
        address,          // receiver
        amount,           // amount (uint160)
        expiration,       // expiration (uint48) - Permit的过期时间
        nonce,            // nonce (uint48)
        sigDeadline,      // sigDeadline - 签名的截止时间
        signature,        // signature
        {
          gasLimit: 500000,
          gasPrice: ethers.parseUnits('20', 'gwei')
        }
      );

      await depositTx.wait();
      message.success('Permit2存款成功!');
      loadBalances();
    } catch (error) {
      message.error('Permit2存款失败');
      console.error(error);
    } finally {
      setIsPermit2DepositLoading(false);
    }
  };

  // 提现
  const handleWithdraw = async () => {
    if (!address || !depositAmount || !window.ethereum) {
      message.error('请连接钱包并输入提现金额');
      return;
    }

    setIsWithdrawLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const tokenBankContract = createTokenBankContract(signer);
      const amount = parseAmount(depositAmount, tokenDecimals);

      // 检查余额
      const balance = await tokenBankContract.balanceOf(address);
      if (balance < amount) {
        message.error('TokenBank余额不足');
        return;
      }

      message.info('正在提现...');
      const withdrawTx = await tokenBankContract.withdraw(amount, address, address);
      await withdrawTx.wait();

      message.success('提现成功!');
      loadBalances();
    } catch (error) {
      message.error('提现失败');
      console.error(error);
    } finally {
      setIsWithdrawLoading(false);
    }
  };

  // 监听钱包连接状态变化
  useEffect(() => {
    if (isConnected && address) {
      loadBalances();
    }
  }, [isConnected, address]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="max-w-4xl mx-auto">
        {/* 头部 */}
        <div className="text-center mb-8">
          <Title level={1} className="text-blue-600 mb-2">
            <BankOutlined className="mr-2" />
            TokenBank - Permit2 存款
          </Title>
          <Text type="secondary">
            使用Permit2进行无gas授权的智能存款
          </Text>
        </div>

        {/* 钱包连接 */}
        <Card className="mb-6">
          <div className="flex justify-between items-center">
            <div>
              <Title level={4} className="mb-2">
                <WalletOutlined className="mr-2" />
                钱包连接
              </Title>
              {isConnected && (
                <Text type="secondary">
                  已连接: {truncateAddress(address!)}
                </Text>
              )}
            </div>
            <div>
              {!isConnected ? (
                <Button type="primary" onClick={handleConnect} icon={<WalletOutlined />}>
                  连接钱包
                </Button>
              ) : (
                <Button onClick={handleDisconnect} danger>
                  断开连接
                </Button>
              )}
            </div>
          </div>
        </Card>

        {/* 余额信息 */}
        {isConnected && (
          <Row gutter={16} className="mb-6">
            <Col span={12}>
              <Card>
                <Statistic
                  title="Token余额"
                  value={formatAmount(tokenBalance, tokenDecimals)}
                  suffix={tokenSymbol}
                  valueStyle={{ color: '#3f8600' }}
                />
              </Card>
            </Col>
            <Col span={12}>
              <Card>
                <Statistic
                  title="TokenBank余额"
                  value={formatAmount(bankBalance, 18)}
                  suffix="TBANK"
                  valueStyle={{ color: '#cf1322' }}
                />
              </Card>
            </Col>
          </Row>
        )}

        {/* 存款操作 */}
        {isConnected && (
          <Card className="mb-6">
            <Title level={4} className="mb-4">
              <SendOutlined className="mr-2" />
              存款操作
            </Title>
            
            <Space direction="vertical" size="large" className="w-full">
              <div>
                <Text strong>存款金额:</Text>
                <Input
                  type="number"
                  placeholder="输入存款金额"
                  value={depositAmount}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setDepositAmount(e.target.value)}
                  className="mt-2"
                  suffix={tokenSymbol}
                />
              </div>

              {/* 存款操作按钮组 */}
              <div className="space-y-4">
                <div className="flex gap-4">
                  <Button
                    type="primary"
                    onClick={handleStandardDeposit}
                    loading={isStandardDepositLoading}
                    icon={<SendOutlined />}
                    className="flex-1"
                    size="large"
                  >
                    标准存款
                  </Button>
                  <Button
                    type="primary"
                    onClick={handlePermit2Deposit}
                    loading={isPermit2DepositLoading}
                    icon={<SwapOutlined />}
                    className="flex-1"
                    size="large"
                  >
                    Permit2存款
                  </Button>
                </div>
                
                {/* 提现按钮单独一行 */}
                <div className="flex justify-center">
                  <Button
                    onClick={handleWithdraw}
                    loading={isWithdrawLoading}
                    danger
                    size="large"
                    style={{ minWidth: '200px' }}
                  >
                    提现
                  </Button>
                </div>
              </div>
            </Space>
          </Card>
        )}

        {/* 功能说明 */}
        <Card>
          <Title level={4} className="mb-4">
            功能说明
          </Title>
          <div className="space-y-4">
            <div>
              <Text strong>标准存款:</Text>
              <Text type="secondary" className="ml-2">
                需要先授权Token，然后调用deposit方法进行存款
              </Text>
            </div>
            <div>
              <Text strong>Permit2存款:</Text>
              <Text type="secondary" className="ml-2">
                使用Permit2签名进行无gas授权的存款，无需预先授权
              </Text>
            </div>
            <div>
              <Text strong>提现:</Text>
              <Text type="secondary" className="ml-2">
                将TokenBank中的份额兑换回Token
              </Text>
            </div>
          </div>
        </Card>

        {/* 合约信息 */}
        <Card className="mt-6">
          <Title level={4} className="mb-4">
            合约信息
          </Title>
          <div className="space-y-2 text-sm">
            <div>
              <Text strong>Token地址:</Text>
              <Text code className="ml-2">{CONTRACTS.SEPOLIA.EIP2612_TOKEN}</Text>
            </div>
            <div>
              <Text strong>TokenBank地址:</Text>
              <Text code className="ml-2">{CONTRACTS.SEPOLIA.TOKEN_BANK}</Text>
            </div>
            <div>
              <Text strong>Permit2地址:</Text>
              <Text code className="ml-2">{CONTRACTS.SEPOLIA.PERMIT2}</Text>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
} 