// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import "@custom-interfaces/IEscrow.sol";
import "@src/Common.sol";
import "@src/ERC20Base.sol";
// import "@chainlink/AggregatorV3Interface.sol";
import {IUser, IShop, IProduct} from "@src/interfaces/IEcomm.sol";
// import {Utils, ProductsUtils} from "@src/truss-lib/Utils.sol";
import "forge-std/console.sol";

// import "forge-std/console.sol";

abstract contract Ecommercev1 is IShop, Base, ERC20Base {
    IEcomEscrow escrowInterface;
    IUser userInterface;
    IProduct productInterface;

    address payable escrowContract;
    address userContract;
    address productContract;

    uint constant USD_PRECISION = 1e8; //
    uint8 constant USD_DECIMALS = 8;

    mapping(uint256 _payRef => mapping(string _token => uint256 _checkoutRate)) checkoutTokenRate;

    mapping(uint256 _paymentReference => uint256 _amount)
         _checkoutAmount;
}
