# copilot-test

Scaffold for EVM betting dApp (Solidity + Hardhat + Next.js frontend).

Quickstart:

1. Install dependencies (root + frontend):
   - pnpm install
   - cd frontend && pnpm install
2. Run tests:
   - pnpm test
3. Local dev:
   - npx hardhat node
   - cd frontend && pnpm dev
4. Deploy:
   - Set env vars (see .env.example) and run:
     - pnpm run deploy

Security note: Contract is a starter implementation and requires a professional audit before mainnet use. Fee recipient is placeholder in .env.example.

Notes:
- Replace FEE_RECIPIENT after deployment or call `setFeeRecipient(...)`.
- For strict 24h snapshot correctness you may prefer recording Chainlink roundId at round start or using a keeper service to call `settleRound` exactly at `endTimestamp`.
- CI workflow expects pnpm to be available in the Actions runner (setup via `actions/setup-node` and pnpm install).
