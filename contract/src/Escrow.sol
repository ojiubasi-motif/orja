// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IEcomm} from "../lib/interfaces/IEcomm.sol";

contract Escrow {
    address public owner;
    address public ecommercePlatform;
    IEcomm ecommInterface;
    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
        public userBalance;

    constructor() {
        owner = msg.sender;
        // Assuming the contract deployer is the ecommerce platform
    }

    function setEcommercePlatform(
        address _ecommercePlatform
    ) external onlyOwner {
        require(
            _ecommercePlatform != address(0),
            "Invalid ecommerce platform address"
        );
        ecommercePlatform = _ecommercePlatform;
        ecommInterface = IEcomm(ecommercePlatform);
    }

    function payForItems(
        uint _payRef,
        uint _userId
    ) external payable isCorrectFundsSent(_userId, _payRef) returns (bool) {
        require(msg.value > 0, "Payment must be greater than zero");
        require(
            msg.value == ecommInterface.userCheckoutAmount(_userId),
            "Incorrect payment amount"
        );
        // Logic to handle payment
        // For example, transfer funds to the seller
        // and emit an event for the transaction
        return true;
    }

    modifier isCorrectFundsSent(uint _userId, uint _payRef) {
        uint escrowBalBefore = address(this).balance;
        uint userBalBefore = userBalance[_userId][_payRef]; // Assuming 0 is the payment reference for the user
        _;
        uint escrowBalAfter = address(this).balance;
        uint userBalAfter = userBalance[_userId][_payRef];
        require(
            escrowBalAfter == escrowBalBefore + userBalAfter,
            "Incorrect funds sent to escrow"
        );
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the  deployer can call this function"
        );
        _;
    }
}
