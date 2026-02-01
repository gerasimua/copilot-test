// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract Betting is ReentrancyGuard, Ownable {
    uint256 public constant FEE_BPS = 500; // 5%
    uint256 public constant BPS = 10000;

    struct RoundInfo {
        uint256 startTimestamp;
        uint256 endTimestamp;
        int256 startPrice;
        int256 endPrice;
        bool settled;
        bool yesWins;
        uint256 totalYes;
        uint256 totalNo;
    }

    struct UserBet {
        uint256 yesAmount;
        uint256 noAmount;
        bool claimedYes;
        bool claimedNo;
    }

    AggregatorV3Interface public priceFeed;
    address public feeRecipient;

    uint256 public nextRoundId = 1;
    mapping(uint256 => RoundInfo) public rounds;
    mapping(uint256 => mapping(address => UserBet)) public bets; // roundId => user => bets

    event RoundCreated(uint256 indexed roundId, uint256 startTimestamp, uint256 endTimestamp, int256 startPrice);
    event BetPlaced(uint256 indexed roundId, address indexed user, uint256 amount, bool yes);
    event RoundSettled(uint256 indexed roundId, bool yesWins, uint256 totalYes, uint256 totalNo, int256 endPrice);
    event Payout(address indexed user, uint256 indexed roundId, uint256 amount);

    constructor(address _priceFeed, address _feeRecipient) {
        require(_priceFeed != address(0), "zero feed");
        priceFeed = AggregatorV3Interface(_priceFeed);
        // allow placeholder (0x0) by defaulting feeRecipient to deployer
        if (_feeRecipient == address(0)) {
            feeRecipient = msg.sender;
        } else {
            feeRecipient = _feeRecipient;
        }
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "zero fee recipient");
        feeRecipient = _feeRecipient;
    }

    function createRound(uint256 startTimestamp, uint256 endTimestamp) external onlyOwner {
        require(endTimestamp > startTimestamp, "invalid times");
        require(startTimestamp >= block.timestamp, "start in past");

        (, int256 price, , ,) = priceFeed.latestRoundData();

        rounds[nextRoundId] = RoundInfo({
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            startPrice: price,
            endPrice: 0,
            settled: false,
            yesWins: false,
            totalYes: 0,
            totalNo: 0
        });

        emit RoundCreated(nextRoundId, startTimestamp, endTimestamp, price);
        nextRoundId++;
    }

    function placeBet(uint256 roundId, bool yes) external payable nonReentrant {
        RoundInfo storage r = rounds[roundId];
        require(block.timestamp >= r.startTimestamp && block.timestamp < r.endTimestamp, "round not active");
        require(msg.value > 0, "stake zero");

        UserBet storage u = bets[roundId][msg.sender];
        if (yes) {
            u.yesAmount += msg.value;
            r.totalYes += msg.value;
        } else {
            u.noAmount += msg.value;
            r.totalNo += msg.value;
        }
        emit BetPlaced(roundId, msg.sender, msg.value, yes);
    }

    function settleRound(uint256 roundId) external nonReentrant {
        RoundInfo storage r = rounds[roundId];
        require(block.timestamp >= r.endTimestamp, "round not ended");
        require(!r.settled, "already settled");

        (, int256 endPrice, , ,) = priceFeed.latestRoundData();
        bool yesWins = endPrice > r.startPrice;
        r.endPrice = endPrice;
        r.yesWins = yesWins;
        r.settled = true;

        emit RoundSettled(roundId, yesWins, r.totalYes, r.totalNo, endPrice);
    }

    function claim(uint256 roundId) external nonReentrant {
        RoundInfo storage r = rounds[roundId];
        require(r.settled, "not settled");

        UserBet storage u = bets[roundId][msg.sender];
        uint256 payout = 0;

        if (r.yesWins) {
            if (u.yesAmount > 0) {
                uint256 winnersPool = r.totalYes;
                uint256 losersPool = r.totalNo;
                if (winnersPool > 0 && losersPool > 0) {
                    uint256 share = (u.yesAmount * losersPool) / winnersPool;
                    uint256 fee = (share * FEE_BPS) / BPS;
                    uint256 reward = u.yesAmount + (share - fee);
                    payout += reward;
                    if (fee > 0) {
                        (bool fOk,) = feeRecipient.call{value: fee}("", "");
                        require(fOk, "fee transfer failed");
                    }
                } else {
                    payout += u.yesAmount; // refund if no losers
                }
                require(!u.claimedYes, "already claimed yes");
                u.claimedYes = true;
            }
        } else {
            if (u.noAmount > 0) {
                uint256 winnersPool = r.totalNo;
                uint256 losersPool = r.totalYes;
                if (winnersPool > 0 && losersPool > 0) {
                    uint256 share = (u.noAmount * losersPool) / winnersPool;
                    uint256 fee = (share * FEE_BPS) / BPS;
                    uint256 reward = u.noAmount + (share - fee);
                    payout += reward;
                    if (fee > 0) {
                        (bool fOk,) = feeRecipient.call{value: fee}("", "");
                        require(fOk, "fee transfer failed");
                    }
                } else {
                    payout += u.noAmount;
                }
                require(!u.claimedNo, "already claimed no");
                u.claimedNo = true;
            }
        }

        require(payout > 0, "no payout");
        (bool ok,) = msg.sender.call{value: payout}("", "");
        require(ok, "payout failed");
        emit Payout(msg.sender, roundId, payout);
    }

    // emergency withdraw for owner only
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "zero addr");
        (bool ok,) = to.call{value: amount}("", "");
        require(ok, "withdraw failed");
    }

    function getRoundTotals(uint256 roundId) external view returns (uint256 yesTotal, uint256 noTotal, bool settled, int256 startPrice, int256 endPrice, uint256 startTimestamp, uint256 endTimestamp) {
        RoundInfo storage r = rounds[roundId];
        return (r.totalYes, r.totalNo, r.settled, r.startPrice, r.endPrice, r.startTimestamp, r.endTimestamp);
    }

    receive() external payable {}
}