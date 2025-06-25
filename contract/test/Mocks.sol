// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    int256 public answer;
    uint8 public override decimals;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        answer = _initialAnswer;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80, int256, uint256, uint256, uint80
        )
    {
        return (0, answer, 0, 0, 0);
    }

    function setAnswer(int256 _answer) external {
        answer = _answer;
    }

    // unused, but needed for interface compatibility
    function description() external pure override returns (string memory) { return "MOCK"; }
    function version() external pure override returns (uint256) { return 1; }
    function getRoundData(uint80) external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, answer, 0, 0, 0);
    }
}
