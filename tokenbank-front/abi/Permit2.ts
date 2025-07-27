// Permit2智能合约相关类型定义
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

// Permit2 EIP-712 域配置
export const PERMIT2_DOMAIN_NAME = "Permit2";
export const PERMIT2_DOMAIN_VERSION = "1";

// Permit2 EIP-712 类型哈希（与合约保持一致）
export const TOKEN_PERMISSIONS_TYPEHASH = "TokenPermissions(address token,uint256 amount)";
export const PERMIT_TRANSFER_FROM_TYPEHASH = "PermitTransferFrom(TokenPermissions permitted,uint256 nonce,uint256 deadline)";

// Permit2 官方合约地址（多链通用）
export const PERMIT2_ADDRESS = "0xe32b6e161a3d9bEb7D2882716b78C2DCbAAB6Ad9" as const;

export const permit2Abi = [
  {
    "type": "function",
    "name": "permitTransferFrom",
    "inputs": [
      {
        "name": "permit",
        "type": "tuple",
        "internalType": "struct PermitTransferFrom",
        "components": [
          {
            "name": "permitted",
            "type": "tuple",
            "internalType": "struct TokenPermissions",
            "components": [
              { "name": "token", "type": "address", "internalType": "address" },
              { "name": "amount", "type": "uint256", "internalType": "uint256" }
            ]
          },
          { "name": "nonce", "type": "uint256", "internalType": "uint256" },
          { "name": "deadline", "type": "uint256", "internalType": "uint256" }
        ]
      },
      {
        "name": "transferDetails",
        "type": "tuple",
        "internalType": "struct SignatureTransferDetails",
        "components": [
          { "name": "to", "type": "address", "internalType": "address" },
          { "name": "requestedAmount", "type": "uint256", "internalType": "uint256" }
        ]
      },
      { "name": "owner", "type": "address", "internalType": "address" },
      { "name": "signature", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "DOMAIN_SEPARATOR",
    "inputs": [],
    "outputs": [{ "name": "", "type": "bytes32", "internalType": "bytes32" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "nonceBitmap",
    "inputs": [
      { "name": "owner", "type": "address", "internalType": "address" },
      { "name": "word", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [{ "name": "", "type": "uint256", "internalType": "uint256" }],
    "stateMutability": "view"
  }
] as const; 