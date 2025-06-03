// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IEcomm} from "../lib/interfaces/IEcomm.sol";

contract Escrow {
    // 0x0f5C4Fdf728AAc8261FC17061c6dCFAb21D7bc62==verified
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
        userBalance[_userId][_payRef] += msg.value;
        // For example, transfer funds to the seller
        // and emit an event for the transaction
        return true;
    }

    function updateDeliveryStatus(
        uint _userId,
        uint _payRef,
        bool _delivered
    ) external onlyOwner {
        // Logic to update delivery status
        // This could involve updating a mapping or emitting an event
        // For simplicity, we will just log the delivery status
        if (_delivered) {
            emit DeliveryConfirmed(_userId, _payRef);
        } else {
            emit DeliveryPending(_userId, _payRef);
        }
    }
    
    event DeliveryConfirmed(uint indexed userId, uint indexed payRef);
    event DeliveryPending(uint indexed userId, uint indexed payRef);
    event PaymentReceived(uint indexed userId, uint indexed payRef, uint amount);

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
