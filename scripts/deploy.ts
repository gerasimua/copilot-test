import { ethers, run } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

async function main() {
  const Betting = await ethers.getContractFactory("Betting");
  const priceFeed = process.env.CHAINLINK_PRICE_FEED || "0x0000000000000000000000000000000000000000"; // replace per network
  const feeRecipient = process.env.FEE_RECIPIENT || "0x0000000000000000000000000000000000000000";

  const betting = await Betting.deploy(priceFeed, feeRecipient);
  await betting.deployed();

  console.log("Betting deployed to:", betting.address);

  // Attempt Etherscan verification if API key and network provided
  try {
    if (process.env.ETHERSCAN_API_KEY && process.env.NETWORK_NAME) {
      console.log("Verifying on Etherscan...");
      await run("verify:verify", {
        address: betting.address,
        constructorArguments: [priceFeed, feeRecipient],
      });
    }
  } catch (e) {
    console.warn("Verification failed:", e);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
