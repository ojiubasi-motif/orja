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

// import {OrderItem, OrderSpec, User, Product} from "src/Common.sol";

abstract contract EcommerceTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function ecommerce_checkOutWithERC20(
        OrderSpec[] memory _order,
        string memory _payToken
    ) public asActor {
        ecommerce.checkOutWithERC20(_order, _payToken);
    }

    function ecommerce_checkOutWithETH(
        OrderSpec[] memory _order
    ) public payable asActor {
        ecommerce.checkOutWithETH{value: msg.value}(_order);
    }

    function ecommerce_getTokenEquivalence(
        uint256 _totalBill,
        string memory _paymentToken
    ) public asActor {
        ecommerce.getTokenEquivalence(_totalBill, _paymentToken);
    }

    // function ecommerce_initialize(address _escrowAddress, address _userContract, address _productContract, address initialOwner) public asActor {
    //     ecommerce.initialize(_escrowAddress, _userContract, _productContract, initialOwner);
    // }

    function ecommerce_previewCheckoutAmount(
        uint256 _total,
        string memory _paymentToken
    ) public asActor {
        ecommerce.previewCheckoutAmount(_total, _paymentToken);
    }

    // =========== clamped ============//__actorEthBalBefore
    function ecommerce_EthCheckout_clamped() public {
        if (_listedProducts.length > 0) {
            OrderSpec[] memory orderSpecs = new OrderSpec[](
                _listedProducts.length
            );
            for (uint i = 0; i < _listedProducts.length; i++) {
                orderSpecs[i] = OrderSpec({
                    prodId: _listedProducts[i].productId,
                    qty: i == 0 ? 2 : uint8(10 % i)
                });
            }
            this.ecommerce_checkOutWithETH{value: 50 ether}(orderSpecs);
        }
    }

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
