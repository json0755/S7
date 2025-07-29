// 合约地址配置
// export const CONTRACTS = {
//   // Sepolia 测试网
//   SEPOLIA: {
//     EIP2612_TOKEN: '0xf7AcD8C8B2C2D584b4EE44354465B3b18a80DD9B',
//     TOKEN_BANK: '0xD25d9cEfC76c6AC569328C0afBded425e7E7B678', // 使用您提供的地址
//     PERMIT2: '0x000000000022D473030F116dDEE9F6B43aC78BA3'
//   }
// };

export const CONTRACTS = {
  // Sepolia 测试网
  SEPOLIA: {
    EIP2612_TOKEN: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
    TOKEN_BANK: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0', // 使用您提供的地址
    PERMIT2: '0x000000000022D473030F116dDEE9F6B43aC78BA3'
  }
};

// 网络配置
// export const NETWORKS = {
//   SEPOLIA: {
//     id: 11155111,
//     name: 'Sepolia',
//     rpc: 'https://eth-sepolia.api.onfinality.io/public',
//     explorer: 'https://sepolia.etherscan.io',
//     chainId: '0xaa36a7'
//   }
// };

export const NETWORKS = {
  SEPOLIA: {
    id: 31337,
    name: 'Anvil',
    rpc: 'http://127.0.0.1:8545',
    explorer: 'https://sepolia.etherscan.io',
    chainId: '0x7a69'
  }
};

// 默认网络
export const DEFAULT_NETWORK = NETWORKS.SEPOLIA;
export const DEFAULT_CONTRACTS = CONTRACTS.SEPOLIA; 