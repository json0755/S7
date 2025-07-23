import { createPublicClient, http, parseAbiItem } from 'viem';
import { sepolia } from 'viem/chains';
import { abi_origin } from './abi.js';

const NFTMARKET_ADDRESS = '0x2e50ba7CE19C591481De8C893213D918C74c5a0C';

const abi = abi_origin;

const client = createPublicClient({
  chain: sepolia,
  transport: http('https://eth-sepolia.api.onfinality.io/public')
});

client.watchEvent({
  address: NFTMARKET_ADDRESS,
  event: parseAbiItem("event NFTListed(address,address,uint256,uint256)"),
  onLogs: logs => {
    logs.forEach(log => {
      console.log(`[上架] 卖家: ${log.args.seller}, NFT: ${log.args.nftAddress}, TokenId: ${log.args.tokenId}, 价格: ${log.args.price}`);
    });
  }
});

client.watchEvent({
  address: NFTMARKET_ADDRESS,
  abi,
  event: parseAbiItem("event NFTBought(address, address, uint256, uint256)"),
  // eventName: 'NFTBought',
  onLogs: logs => {
    console.log(logs);
    logs.forEach(log => {
      console.log(`[买卖] 买家: ${log.args.buyer}, NFT: ${log.args.nftAddress}, TokenId: ${log.args.tokenId}, 价格: ${log.args.price}`);
    });
  }
});

console.log('监听 NFTMarket 合约事件中...');