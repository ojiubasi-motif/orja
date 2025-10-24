// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@src/ERC20Base.sol";
import "@src/Common.sol";
import {IShop, IUser} from "@custom-interfaces/IEcomm.sol";
// import {IEcomEscrow} from "@custom-interfaces/IEscrow.sol";
import "@chainlink/AggregatorV3Interface.sol";
// import "forge-std/console.sol";

abstract contract Escrowv1 is Base, ERC20Base {
    mapping(string => bool) public isAccepted;
    mapping(string => Token) public tokenSymbolToDetails;
    string[] public acceptedTokens;

    bool isEcommAndUserManagerProxySet;
    address public ecommercePlatform;
    address public userContract;
    // @test uncomment next line later in live deployment
    AggregatorV3Interface priceFeed;

    // IERC20 erc20Interface;

    IShop ecommInterface;
    IUser userInterface;

    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
         userBalance;
    mapping(uint256 _paymentRef => string _symbol) public paymentRefToToken;
    mapping(uint256 _paymentRef => uint256 _tokenPrice)
        public tokenPriceAtcheckout;
    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
         withdrawableBalance;
    mapping(uint256 _payref => mapping(uint256 _product => bool _cancel)) letBuyerCancel;
    mapping(uint256 _payref => OrderItem[] _order) trxToCart;

}
