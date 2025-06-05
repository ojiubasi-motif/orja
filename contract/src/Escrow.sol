// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IEcomm} from "@custom-interfaces/IEcomm.sol";
import {OrderLib} from "@library/OrderManager.sol";

contract Escrow {
    // 0x0f5C4Fdf728AAc8261FC17061c6dCFAb21D7bc62==verified
    using OrderLib for OrderLib.UserType;
    using OrderLib for OrderLib.VerificationStatus;
    using OrderLib for OrderLib.User;
    using OrderLib for OrderLib.OrderStatus;
    using OrderLib for OrderLib.OrderItem;

    address public owner;
    address public ecommercePlatform;
    IEcomm ecommInterface;
    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
        public userBalance;
    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
        public withdrawableBalance;

    constructor() {
        owner = msg.sender;
        // Assuming the contract deployer is the ecommerce platform
    }

    function setEcommercePlatform(
        address _ecommercePlatform
    ) external onlyContractOwner {
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
        require(
            msg.sender == ecommercePlatform,
            "only ecommerce contract can interract with this function"
        );
        require(msg.value > 0, "Payment must be greater than zero");
        require(
            msg.value == ecommInterface.userCheckoutAmount(_userId),
            "Incorrect payment amount"
        );
        require(
            userBalance[_userId][_payRef] == 0,
            "Payment has already been made with this reference"
        );
        // Logic to handle payment
        userBalance[_userId][_payRef] += msg.value;
        // For example, transfer funds to the seller
        // and emit an event for the transaction
        return true;
    }

    function updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _delivered
    ) external {
        _updateDeliveryStatus(_payRef, _productId, _delivered);
    }

    function _updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _delivered
    ) internal {
        // !!!! define a library for enums...
        IEcomm.User memory buyer = ecommInterface.getUserAccount(msg.sender);
        require(msg.sender == buyer.account, "unathorized caller");
        IEcomm.OrderItem[] memory allCartItems = ecommInterface.getCart(
            buyer.account
        );

        IEcomm.OrderItem memory cartItem;
        // Logic to update delivery status
        for (uint i = 0; i < allCartItems.length; i++) {
            if (allCartItems[i].productId == _productId) {
                require(
                    allCartItems[i].sellerId != buyer.userId,
                    "malicious action detected, seller cannot confirm delivery of their own product"
                );
                if (
                    allCartItems[i].orderStatus == IEcomm.OrderStatus.Processing
                ) {
                    cartItem = allCartItems[i];
                } else {
                    revert(
                        "Order already delivered or not in processing state"
                    );
                }

                break;
            } else if (
                i == allCartItems.length - 1 &&
                allCartItems[i].productId != _productId
            ) {
                revert("Product not found in cart");
            }
        }

        uint256 _bal = uint256(cartItem.unitPrice) * cartItem.qty; // total amount for the item
        // execute the delivery confirmation logic
        if (_delivered) {
            cartItem.orderStatus = IEcomm.OrderStatus.Delivered;

            userBalance[buyer.userId][_payRef] -= _bal; // deduct it from the buyer balance
            userBalance[cartItem.sellerId][_payRef] += _bal; //add it to the seller balance
            withdrawableBalance[cartItem.sellerId][_payRef] += _bal; // add it to the seller withdrawable balance
        } else {
            // !!!buyer should not be eligible to withdraw  funds until settled
            // !!add delivery duration to the order item in order to check if supposed delivery time is expired
            if (cartItem._proposedDeliveryTime + 60 seconds > block.timestamp) {
                revert(
                    "Delivery time not yet expired, cannot withdraw funds yet"
                );
            } else {
                userBalance[buyer.userId][_payRef] -= _bal; //remove from balance of the buyer
                withdrawableBalance[buyer.userId][_payRef] += _bal; //add to buyer withdrawable balance
            }
            // emit DeliveryPending(_userId, _payRef);
        }
    }

    event DeliveryConfirmed(uint indexed userId, uint indexed payRef);
    event DeliveryPending(uint indexed userId, uint indexed payRef);
    event PaymentReceived(
        uint indexed userId,
        uint indexed payRef,
        uint amount
    );

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

    modifier onlyContractOwner() {
        require(
            msg.sender == owner,
            "Only the  deployer can call this function"
        );
        _;
    }

    // modifier onlyOwner(){
    //     require
    // }
}
