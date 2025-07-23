import { createConfig, http } from "wagmi";
import { walletConnect } from "wagmi/connectors";
import { sepolia } from "wagmi/chains";

export const config = createConfig({
  chains: [sepolia],
  connectors: [
    walletConnect({
      projectId: "0fe5c36241f975334438850aac61f941",
      showQrModal: true,
    }),
  ],
  transports: {
    [sepolia.id]: http(),
  },
}); 