// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;


import {IProduct,IUser} from "@src/interfaces/IEcomm.sol";
import {Utils,ProductsUtils} from "@src/truss-lib/Utils.sol";
import "@src/Common.sol";

abstract contract Productsv1 is Base, IProduct {
    IUser userInterface;
    address userContract;

     using ProductsUtils for Product[];
    Product[] public products;

    mapping(uint256 => uint256) productIdToRecordIndex;
    

    
}