// TokenBank智能合约相关类型定义
export interface TokenPermissions {
  token: `0x${string}`;
  amount: bigint;
}

export interface PermitTransferFrom {
  permitted: TokenPermissions;
  nonce: bigint;
  deadline: bigint;
}

export interface SignatureTransferDetails {
  to: `0x${string}`;
  requestedAmount: bigint;
}

export const tokenBankAbi = [
    {
      "type": "constructor",
      "inputs": [
        { "name": "tokenAddress", "type": "address", "internalType": "address" },
        { "name": "permit2Address", "type": "address", "internalType": "address" }
      ],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "balances",
      "inputs": [{ "name": "", "type": "address", "internalType": "address" }],
      "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "deposit",
      "inputs": [
        { "name": "amount", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "permitDeposit",
      "inputs": [
        { "name": "amount", "type": "uint256", "internalType": "uint256" },
        { "name": "deadline", "type": "uint256", "internalType": "uint256" },
        { "name": "v", "type": "uint8", "internalType": "uint8" },
        { "name": "r", "type": "bytes32", "internalType": "bytes32" },
        { "name": "s", "type": "bytes32", "internalType": "bytes32" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "depositWithPermit2",
      "inputs": [
        { "name": "amount", "type": "uint256", "internalType": "uint256" },
        { "name": "nonce", "type": "uint256", "internalType": "uint256" },
        { "name": "deadline", "type": "uint256", "internalType": "uint256" },
        { "name": "signature", "type": "bytes", "internalType": "bytes" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    },
    {
      "type": "function",
      "name": "balanceOf",
      "inputs": [{ "name": "account", "type": "address", "internalType": "address" }],
      "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "getTotalBalance",
      "inputs": [],
      "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "permit2",
      "inputs": [],
      "outputs": [
        { "name": "", "type": "address", "internalType": "contract IPermit2" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "token",
      "inputs": [],
      "outputs": [
        { "name": "", "type": "address", "internalType": "contract IBaseERC20" }
      ],
      "stateMutability": "view"
    },
    {
      "type": "function",
      "name": "withdraw",
      "inputs": [
        { "name": "amount", "type": "uint256", "internalType": "uint256" }
      ],
      "outputs": [],
      "stateMutability": "nonpayable"
    }
  ] as const; 