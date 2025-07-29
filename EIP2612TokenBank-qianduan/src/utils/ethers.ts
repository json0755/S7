import { ethers } from 'ethers';
import { CONTRACTS } from '@/config/contracts';
import { EIP2612TokenBankABI, EIP2612TokenABI, Permit2ABI } from '@/abi';

// 格式化金额显示
export function formatAmount(amount: bigint, decimals: number = 18): string {
  return ethers.formatUnits(amount, decimals);
}

// 解析金额
export function parseAmount(amount: string, decimals: number = 18): bigint {
  return ethers.parseUnits(amount, decimals);
}

// 截断地址显示
export function truncateAddress(address: string): string {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

// 生成随机nonce
export function generateNonce(): bigint {
  return BigInt(Math.floor(Math.random() * 1000000));
}

// 获取deadline (1小时后)
export function getDeadline(): bigint {
  return BigInt(Math.floor(Date.now() / 1000) + 3600);
}

// 获取expiration (24小时后) - Permit的过期时间
export function getExpiration(): bigint {
  return BigInt(Math.floor(Date.now() / 1000) + 86400); // 24小时
}

// 获取sigDeadline (1小时后) - 签名的截止时间
export function getSigDeadline(): bigint {
  return BigInt(Math.floor(Date.now() / 1000) + 3600); // 1小时
}

// 创建Permit2签名
export async function createPermit2Signature(
  signer: ethers.Signer,
  tokenAddress: string,
  spender: string,
  amount: bigint,
  nonce: bigint,
  expiration: bigint,
  sigDeadline: bigint
): Promise<string> {
  // Permit2 domain
  // const domain = {
  //   name: 'Permit2',
  //   chainId: 11155111, // Sepolia
  //   verifyingContract: CONTRACTS.SEPOLIA.PERMIT2
  // };
  const domain = {
    name: 'Permit2',
    chainId: 31337, // Sepolia
    verifyingContract: CONTRACTS.SEPOLIA.PERMIT2
  };

  // 新的Permit types
  const types = {
    PermitSingle: [
      { name: 'details', type: 'PermitDetails' },
      { name: 'spender', type: 'address' },
      { name: 'sigDeadline', type: 'uint256' }
    ],
    PermitDetails: [
      { name: 'token', type: 'address' },
      { name: 'amount', type: 'uint160' },
      { name: 'expiration', type: 'uint48' },
      { name: 'nonce', type: 'uint48' }
    ]
  };

  // 新的Permit data
  const permit = {
    details: {
      token: tokenAddress,
      amount: amount,
      expiration: expiration, // 使用传入的expiration
      nonce: nonce
    },
    spender: spender,
    sigDeadline: sigDeadline // 使用传入的sigDeadline
  };

  // 签名
  const signature = await signer.signTypedData(domain, types, permit);
  return signature;
}

// 创建合约实例
export function createContractInstance(
  address: string,
  abi: any,
  signer: ethers.Signer
): ethers.Contract {
  return new ethers.Contract(address, abi, signer);
}

// 创建TokenBank合约实例
export function createTokenBankContract(signer: ethers.Signer): ethers.Contract {
  return createContractInstance(
    CONTRACTS.SEPOLIA.TOKEN_BANK,
    EIP2612TokenBankABI,
    signer
  );
}

// 创建Token合约实例
export function createTokenContract(signer: ethers.Signer): ethers.Contract {
  return createContractInstance(
    CONTRACTS.SEPOLIA.EIP2612_TOKEN,
    EIP2612TokenABI,
    signer
  );
}

// 创建Permit2合约实例
export function createPermit2Contract(signer: ethers.Signer): ethers.Contract {
  return createContractInstance(
    CONTRACTS.SEPOLIA.PERMIT2,
    Permit2ABI,
    signer
  );
} 