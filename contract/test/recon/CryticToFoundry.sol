// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

import "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "./TargetFunctions.sol";

import "@src/Common.sol";

// forge test --match-contract CryticToFoundry -vv
contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        setup();

        targetContract(address(this));
    }

    // forge test --match-test test_crytic -vvv
    function test_crytic() public {
        // TODO: add failing property tests here for debugging
        _switchActor(1);
        trussUser_register("test-user1", "sur1");

        _switchActor(2);
        trussUser_register("seller1", "surSeller1");

        trussAdmin_verifySeller(address(0x2));

        _switchActor(2);
        products_listProduct(1, "prod1", 2, 0);

        OrderSpec[] memory specs = new OrderSpec[](1);
        specs[0] = OrderSpec({prodId: 17394314813901784864, qty: 10});

        products_getProducts(0,100);

        _switchActor(1);
        this.ecommerce_checkOutWithETH{value: 5 ether}(specs);

        _switchActor(1);
        ecommerce_checkOutWithERC20(specs, "mockA");

        vm.warp(block.timestamp + 61 seconds);

        _switchActor(1);
        escrow_updateDeliveryStatus(13821033653655238596, 17394314813901784864, 10, false);
        _switchActor(1);
        escrow_updateDeliveryStatus(9990528946214242477, 17394314813901784864, 10, true);

        _switchActor(1);
        escrow_withdrawFunds(13821033653655238596, 24148756);
        _switchActor(2);
        uint256 sellerBal = escrow_getWithdrawableBal(1736036535, 9990528946214242477);
         _switchActor(2);
         escrow_withdrawFunds(9990528946214242477, sellerBal);
    }
}
