import React from "react";
import BetWidget from "../components/BetWidget";

export default function Home() {
  const contractAddress = process.env.NEXT_PUBLIC_CONTRACT_ADDRESS || "";
  return (
    <main className="min-h-screen bg-gray-900 text-white p-8">
      <div className="max-w-3xl mx-auto">
        <h1 className="text-3xl font-bold mb-4">BTC 24h Up/Down — Betting DApp</h1>
        <p className="mb-6">Connect your wallet and place a yes/no bet on whether BTC price will be up 24h from GMT+0.</p>
        <BetWidget contractAddress={contractAddress} roundId={1} />
      </div>
    </main>
  );
}
