// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract AggregatorV3Mock {
    int256 private answer;
    constructor(int256 _initial) {
        answer = _initial;
    }
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, answer, 0, block.timestamp, 0);
    }
    function setAnswer(int256 _a) external {
        answer = _a;
    }
}
