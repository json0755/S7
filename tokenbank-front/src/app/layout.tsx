"use client";
import { ReactNode } from "react";
import { WagmiProvider } from "wagmi";
import { wagmiConfig } from "../wagmiConfig";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import "../app/globals.css";

const queryClient = new QueryClient();

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="zh">
      <body>
        <QueryClientProvider client={queryClient}>
          <WagmiProvider config={wagmiConfig}>
        {children}
          </WagmiProvider>
        </QueryClientProvider>
      </body>
    </html>
  );
}
