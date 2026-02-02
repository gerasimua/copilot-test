import { expect } from "chai";
import { ethers } from "hardhat";

describe("Betting contract", function () {
  it("should allow bets, settle and claim correctly", async function () {
    const [owner, alice, bob] = await ethers.getSigners();

    const Betting = await ethers.getContractFactory("Betting");
    const DummyFeed = await ethers.getContractFactory("AggregatorV3Mock");
    const feed = await DummyFeed.deploy(20000 * 1e8);
    await feed.deployed();

    const betting = await Betting.deploy(feed.address, owner.address);
    await betting.deployed();

    const now = Math.floor(Date.now() / 1000);
    await betting.connect(owner).createRound(now, now + 1);

    await betting.connect(alice).placeBet(1, true, { value: ethers.utils.parseEther("1") });
    await betting.connect(bob).placeBet(1, false, { value: ethers.utils.parseEther("2") });

    await feed.setAnswer(22000 * 1e8);

    await ethers.provider.send("evm_increaseTime", [2]);
    await ethers.provider.send("evm_mine", []);

    await betting.connect(owner).settleRound(1);

    const aliceBalBefore = await ethers.provider.getBalance(alice.address);
    await betting.connect(alice).claim(1);
    const aliceBalAfter = await ethers.provider.getBalance(alice.address);

    expect(aliceBalAfter).to.be.gt(aliceBalBefore);
  });
});
