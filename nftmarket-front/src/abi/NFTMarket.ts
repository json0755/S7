export const nftMarketAbi = [
  {
    "type": "constructor",
    "inputs": [
      { "name": "tokenAddress", "type": "address", "internalType": "address" },
      { "name": "signerAddress", "type": "address", "internalType": "address" }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "buyNFT",
    "inputs": [
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "list",
    "inputs": [
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
      { "name": "price", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "listings",
    "inputs": [
      { "name": "", "type": "address", "internalType": "address" },
      { "name": "", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [
      { "name": "seller", "type": "address", "internalType": "address" },
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
      { "name": "price", "type": "uint256", "internalType": "uint256" },
      { "name": "active", "type": "bool", "internalType": "bool" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "onERC721Received",
    "inputs": [
      { "name": "operator", "type": "address", "internalType": "address" },
      { "name": "from", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
      { "name": "data", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "onTransferReceived",
    "inputs": [
      { "name": "operator", "type": "address", "internalType": "address" },
      { "name": "from", "type": "address", "internalType": "address" },
      { "name": "value", "type": "uint256", "internalType": "uint256" },
      { "name": "data", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [{ "name": "", "type": "bytes4", "internalType": "bytes4" }],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "paymentToken",
    "inputs": [],
    "outputs": [{ "name": "", "type": "address", "internalType": "address" }],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "unlist",
    "inputs": [
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "NFTBought",
    "inputs": [
      {
        "name": "buyer",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "nftAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "price",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "NFTListed",
    "inputs": [
      {
        "name": "seller",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "nftAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "price",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "function",
    "name": "permitBuy",
    "inputs": [
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
      { "name": "nonce", "type": "uint256", "internalType": "uint256" },
      { "name": "signature", "type": "bytes", "internalType": "bytes" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "updateSigner",
    "inputs": [
      { "name": "newSigner", "type": "address", "internalType": "address" }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getMessageHash",
    "inputs": [
      { "name": "buyer", "type": "address", "internalType": "address" },
      { "name": "nftAddress", "type": "address", "internalType": "address" },
      { "name": "tokenId", "type": "uint256", "internalType": "uint256" },
      { "name": "nonce", "type": "uint256", "internalType": "uint256" }
    ],
    "outputs": [
      { "name": "", "type": "bytes32", "internalType": "bytes32" }
    ],
    "stateMutability": "pure"
  },
  {
    "type": "function",
    "name": "signer",
    "inputs": [],
    "outputs": [
      { "name": "", "type": "address", "internalType": "address" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "usedSignatures",
    "inputs": [
      { "name": "", "type": "bytes32", "internalType": "bytes32" }
    ],
    "outputs": [
      { "name": "", "type": "bool", "internalType": "bool" }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "WhitelistBought",
    "inputs": [
      {
        "name": "buyer",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "nftAddress",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "tokenId",
        "type": "uint256",
        "indexed": true,
        "internalType": "uint256"
      },
      {
        "name": "price",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "SignerUpdated",
    "inputs": [
      {
        "name": "oldSigner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newSigner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  }
] as const; 