import { createPublicClient, http, parseAbi } from 'viem';
import { sepolia } from 'viem/chains';

// 替换为你的NFTMarket合约地址
const NFTMARKET_ADDRESS = '0x74F8629751902A7d4650DAED78A9a067D9932Ef7';

// 事件 ABI
const abi = parseAbi([
  'event NFTListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price)',
  'event NFTBought(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price)'
]);

const client = createPublicClient({
  chain: sepolia,
  transport: http('https://gateway.pinata.cloud/ipfs/bafkreidb6munmoilyyhaimrsyge5eedvsmdgfz2qs7zkj5vmdvfsgwqo3u')
});

// 监听 NFTListed
client.watchEvent({
  address: NFTMARKET_ADDRESS,
  abi,
  eventName: 'NFTListed',
  onLogs: logs => {
    logs.forEach(log => {
      console.log(`[上架] 卖家: ${log.args.seller}, NFT: ${log.args.nftAddress}, TokenId: ${log.args.tokenId}, 价格: ${log.args.price}`);
    });
  }
});

// 监听 NFTBought
client.watchEvent({
  address: NFTMARKET_ADDRESS,
  abi,
  eventName: 'NFTBought',
  onLogs: logs => {
    logs.forEach(log => {
      console.log(`[买卖] 买家: ${log.args.buyer}, NFT: ${log.args.nftAddress}, TokenId: ${log.args.tokenId}, 价格: ${log.args.price}`);
    });
  }
});


console.log('监听 NFTMarket 合约事件中...'); 