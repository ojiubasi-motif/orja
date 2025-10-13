// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {console} from "forge-std/console.sol";

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Products.sol";

abstract contract ProductsTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    // function products_initialize(address _userContractAddress, address initialOwner) public asActor {
    //     products.initialize(_userContractAddress, initialOwner);
    // }

    function products_listProduct(
        uint256 _unitprice,
        uint256 _waranteeDuration,
        uint256 _expectedDeliveryTime
    ) public asActor {
        address _actor = _getActor();
        if (_actor == address(this)) return;
        __userBefore(_actor);
        if (
            _userBefore.userId == 0 ||
            _userBefore.verificationStatus != VerificationStatus.Verified
        ) return; // user not registered or verified

        string memory title = string(
            abi.encodePacked(
                "product-",
                Strings.toString(block.timestamp % 1000)
            )
        );
        uint256 price = between(_unitprice, 0.5 * 1e8, 1000 * 1e8);
        uint256 warDuration = between(_waranteeDuration, 0, 365 days);
        uint256 expDelivery = between(_expectedDeliveryTime, 1 days, 30 days);
        uint256 _prodId = products.listProduct(
            price,
            title,
            warDuration,
            expDelivery
        );
        __productAfter(_prodId);
        // _listedProducts.push(_productAfter);
        // t(
        //     _userBefore.account != admin,"the user is still admin"
        // );
        eq(
            _userBefore.userId,
            _productAfter.sellerId,
            "product not listed by the same user"
        );
        eq(
            _productAfter.unitPrice,
            price,
            "product with this price was not listed"
        );
    }

    function products_updateProductPrice(
        uint256 _productId,
        uint256 _newPrice
    ) public asActor {
        address _actor = _getActor();
        __userBefore(_actor);
        __productBefore(_productId);
        if (_newPrice == 0 || _newPrice == _productBefore.unitPrice) return; // test with a valid price that's diff from the old price
        if (_productBefore.productId == 0) return; // product not found
        if (_productBefore.sellerId != _userBefore.userId) return; // not the product owner
        products.updateProductPrice(_productId, _newPrice);
        __productAfter(_productId);
        t(_userBefore.account != admin, "the user is still admin");
        eq(_productAfter.unitPrice, _newPrice, "product price was not updated");
    }

    /**=======================
     * invariants
      ========================*/
    function products_onlyVerifiedUsersCanListProducts()
        public
        userUpdateGhosts(address(_getActor()))
        asActor
    {
        // address _actor = _getActor();
        // if (_actor == address(this)) return;
        // __userBefore(_actor);

        // if (_userBefore.verificationStatus != VerificationStatus.NotVerified) return;
        // only test normal users
        // if (_userBefore.verificationStatus == VerificationStatus.NotVerified) {
        // vm.prank(_actor);
        // if (
        //     msg.sender != address(this) &&
        //     _userBefore.verificationStatus == VerificationStatus.NotVerified
        // ) {
        try products.listProduct(1e8, "test-product", 30 days, 7 days) returns (
            uint256
        ) {
            // if (_userBefore.verificationStatus == VerificationStatus.NotVerified) {
            if (
                // msg.sender != address(this) &&
                _userBefore.verificationStatus == VerificationStatus.NotVerified
            ) {
                t(
                    false,
                    "unverified Users should not be allowed to list products"
                );
            }
            // } // should not reach here
        } catch {
            assert(true);
        }
        // }
        // } // only test unverified users

        // (string memory _errMsg, ) = _getRevertMsg(
        //     abi.encodeWithSelector(
        //         products.listProduct.selector,
        //         1e8,
        //         "test-product",
        //         30 days,
        //         7 days
        //     )
        // );
        // assert(
        //     keccak256(abi.encodePacked(_errMsg)) ==
        //         keccak256(
        //             abi.encodePacked(
        //                 "unauthorized address not allowed to list product"
        //             )
        //         ) ||
        //         keccak256(abi.encodePacked(_errMsg)) ==
        //         keccak256(
        //             abi.encodePacked("only verified sellers can list products")
        //         )
        // );
    }

    // function products_renounceOwnership() public asActor {
    //     products.renounceOwnership();
    // }

    // function products_transferOwnership(address newOwner) public asActor {
    //     products.transferOwnership(newOwner);
    // }

    // function products_updateProductPrice(address _account, uint256 _productId, uint256 _newPrice) public asActor {
    //     products.updateProductPrice(_account, _productId, _newPrice);
    // }

    // function products_upgradeToAndCall(address newImplementation, bytes memory data) public payable asActor {
    //     products.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }
}
