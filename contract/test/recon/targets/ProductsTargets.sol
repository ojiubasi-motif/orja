// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Products.sol";

abstract contract ProductsTargets is
    BaseTargetFunctions,
    Properties
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    // function products_initialize(address _userContractAddress, address initialOwner) public asActor {
    //     products.initialize(_userContractAddress, initialOwner);
    // }

    function products_listProduct(uint256 _unitprice, string memory _title, uint256 _waranteeDuration, uint256 _expectedDeliveryTime) public updateProductsList asActor {
        products.listProduct(_unitprice, _title, _waranteeDuration, _expectedDeliveryTime);
    }

    // =========clamped ==========
    function products_listProduct_clamped(uint _price,  uint256 _delivery, uint8 _entropy) public {
        uint expected = between(_delivery,1, 4 weeks);
        uint _uintP = between(_price,1,5_000);
        uint clamper = between(_entropy,1,4);
        string memory _title = "product";
        _switchActor(clamper);
        products_listProduct(_uintP,_title,5 weeks,expected);
    }

    function products_getProducts(uint start, uint end) public {
        products.getProducts(start,end);
    }

    // function products_renounceOwnership() public asActor {
    //     products.renounceOwnership();
    // }

    // function products_transferOwnership(address newOwner) public asActor {
    //     products.transferOwnership(newOwner);
    // }

    // function products_updateProductPrice(uint256 _productId, uint256 _newPrice) public asActor {
    //     products.updateProductPrice(_productId, _newPrice);
    // }

    // function products_upgradeToAndCall(address newImplementation, bytes memory data) public payable asActor {
    //     products.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }
}