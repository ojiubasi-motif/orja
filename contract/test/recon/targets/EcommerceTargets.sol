// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Ecomm.sol";

abstract contract EcommerceTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function ecommerce_addProductToCart(uint256 _productId, uint32 _qty) public asActor {
        ecommerce.addProductToCart(_productId, _qty);
    }

    function ecommerce_checkOutWithNative(string memory _payToken) public payable asActor {
        ecommerce.checkOutWithNative{value: msg.value}(_payToken);
    }

    function ecommerce_checkOutWithUSD(string memory _payToken) public asActor {
        ecommerce.checkOutWithUSD(_payToken);
    }

    // function ecommerce_initialize(address _escrowAddress, address _userContract, address _productContract, address initialOwner) public asActor {
    //     ecommerce.initialize(_escrowAddress, _userContract, _productContract, initialOwner);
    // }

    // function ecommerce_renounceOwnership() public asActor {
    //     ecommerce.renounceOwnership();
    // }

    // function ecommerce_transferOwnership(address newOwner) public asActor {
    //     ecommerce.transferOwnership(newOwner);
    // }

    // function ecommerce_upgradeToAndCall(address newImplementation, bytes memory data) public payable asActor {
    //     ecommerce.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }
}