import React, { useState } from "react";
import { ethers } from "ethers";

type Props = { contractAddress: string; roundId: number };

export default function BetWidget({ contractAddress, roundId }: Props) {
  const [amount, setAmount] = useState("0.01");
  const [side, setSide] = useState<"yes" | "no">("yes");

  const handlePlace = async () => {
    if (!(window as any).ethereum || !contractAddress) return alert("No wallet or contract address");
    await (window as any).ethereum.request({ method: "eth_requestAccounts" });
    const provider = new ethers.providers.Web3Provider((window as any).ethereum);
    const signer = provider.getSigner();
    const abi = ["function placeBet(uint256,bool) payable"];
    const c = new ethers.Contract(contractAddress, abi, signer);
    const value = ethers.utils.parseEther(amount);
    try {
      const tx = await c.placeBet(roundId, side === "yes", { value });
      await tx.wait();
      alert("Bet placed");
    } catch (e) {
      console.error(e);
      alert("Tx failed");
    }
  };

  return (
    <div className="p-6 bg-gray-800 rounded">
      <div className="mb-4">Round #{roundId}</div>
      <div className="flex gap-2 mb-4">
        <button onClick={() => setSide("yes")} className={`px-4 py-2 rounded ${side === "yes" ? "bg-green-500" : "bg-gray-700"}`}>Yes</button>
        <button onClick={() => setSide("no")} className={`px-4 py-2 rounded ${side === "no" ? "bg-red-500" : "bg-gray-700"}`}>No</button>
      </div>
      <input className="w-full p-2 mb-4 bg-gray-900 rounded" value={amount} onChange={(e) => setAmount(e.target.value)} />
      <button onClick={handlePlace} className="w-full bg-blue-600 p-2 rounded">Place Bet</button>
    </div>
  );
}
