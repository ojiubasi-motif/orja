// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@src/Common.sol";

abstract contract TrussUserv1 is Base {
    mapping(address => bool)  isRegistered; //is acc is registered
    mapping(address => bool)  isVerified; //is acc verified?
    mapping(address => uint256)  userToRecordIndex;

    // address payable escrowContract;

    User[] users;
}