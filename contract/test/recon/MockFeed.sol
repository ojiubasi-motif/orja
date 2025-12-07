// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@chainlink/AggregatorV3Interface.sol";
// import {BeforeAfter} from "./BeforeAfter.sol"; //@fuzz introduced this
import {MockERC20} from "@recon/MockERC20.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    // struct Token {
    //     string symbol;
    //     uint8 decimals;
    //     uint256 initialPrice;
    // }
    int256 public answer;
    // mapping(string => int256) public tokenPriceAnswer;
    uint8 public  feedDecimals;
    string public tokenSymbol;
    // mapping(string => uint8) public feedDecimals;

    // constructor(
    //     address[] memory _tokens,
    //     uint256[] memory _initialPrices,
    //     uint8[] memory _decimals
    // ) {
    //     for (uint i = 0; i < _tokens.length; i++) {
    //         string memory symbol = MockERC20(_tokens[i]).symbol();
    //         // uint8  decimals= MockERC20(_tokens[i]).decimals();
    //         tokenPriceAnswer[symbol] = int256(_initialPrices[i]);
    //         feedDecimals[symbol] = _decimals[i];
    //     }
    //     // setup ETH data;
    //     tokenPriceAnswer["ETH"] = 4141e8;
    //     feedDecimals["ETH"] = 8;
    // }
    constructor(int256 _initialPrice, uint8 _decimals, string memory _tokenSymbol) {
        answer = _initialPrice;
        feedDecimals = _decimals;
        tokenSymbol = _tokenSymbol;
    }

    // constructor(uint8 _decimals, int256 _initialAnswer) {
    //     decimals = _decimals;
    //     answer = _initialAnswer;
    // }
    function decimals() external view override returns (uint8) {
        // string memory _checkoutTokenSymb = BeforeAfter._checkoutTokenSymbol;
        // return feedDecimals[_checkoutTokenSymb];
        return feedDecimals;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // string memory _checkoutTokenSymb = BeforeAfter._checkoutTokenSymbol;
        return (0, answer, 0, 0, 0);
    }

    function setAnswer( int256 _answer) external {
       answer = _answer;
    }

    // unused, but needed for interface compatibility
    function description() external view override returns (string memory) {
        // string memory _checkoutTokenSymb = BeforeAfter._checkoutTokenSymbol;
        return tokenSymbol;
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        // string memory _checkoutTokenSymb = BeforeAfter._checkoutTokenSymbol;
        return (0, answer, 0, 0, 0);
    }
}

contract MockV3Aggregator1 is AggregatorV3Interface {
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
