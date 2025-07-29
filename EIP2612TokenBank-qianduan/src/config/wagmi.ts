import { http, createConfig } from 'wagmi'
import { sepolia } from 'wagmi/chains'
import { injected, metaMask, walletConnect } from 'wagmi/connectors'

// export const config = createConfig({
//   chains: [sepolia],
//   connectors: [
//     injected(),
//     metaMask(),
//     walletConnect({ projectId: 'your-project-id' }),
//   ],
//   transports: {
//     [sepolia.id]: http('https://eth-sepolia.api.onfinality.io/public'),
//   },
// }) 

export const config = createConfig({
  chains: [
    {
      id: 31337,
      name: 'Anvil',
      nativeCurrency: {
        decimals: 18,
        name: 'Ether',
        symbol: 'ETH',
      },
      rpcUrls: {
        default: { http: ['http://127.0.0.1:8545'] },
        public: { http: ['http://127.0.0.1:8545'] },
      },
    }
  ],
  connectors: [
    injected(),
    metaMask(),
    walletConnect({ projectId: 'your-project-id' }),
  ],
  transports: {
    31337: http('http://127.0.0.1:8545'),
  },
}) 