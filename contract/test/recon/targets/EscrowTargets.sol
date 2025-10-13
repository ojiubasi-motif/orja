// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/Escrow.sol";

abstract contract EscrowTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///
    function escrow_admin_withdrawFunds(
        uint256 _payRef,
        uint256 _amount
    ) public asDeployer {
        escrow.withdrawFunds(_payRef, _amount);
    }

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    function escrow_addTokenToAcceptedList(
        address _tokenAddress,
        string memory _symbol,
        address _feedAddress
    ) public asDeployer {
        escrow.addTokenToAcceptedList(_tokenAddress, _symbol, _feedAddress);
    }

    function escrow_delistToken(string memory _symbol) public asDeployer {
        escrow.delistToken(_symbol);
    }

    // function escrow_initialize(
    //     address _userContractAddress,
    //     address initialOwner
    // ) public asActor {
    //     escrow.initialize(_userContractAddress, initialOwner);
    // }

    function escrow_payForItemsWithETH(
        uint256 _userId,
        uint256 _bill,
        bytes memory _feedData,
        uint256 _payRef
    ) public payable asActor {
        escrow.payForItemsWithETH{value: msg.value}(
            _userId,
            _bill,
            _feedData,
            _payRef
        );
    }

    function escrow_payForItemsWithUsd(
        uint256 _userId,
        uint256 bill,
        string memory _paymentTokenSymbol,
        uint256 _payRef
    ) public asActor {
        escrow.payForItemsWithUsd(_userId, bill, _paymentTokenSymbol, _payRef);
    }

    // function escrow_renounceOwnership() public asActor {
    //     escrow.renounceOwnership();
    // }

    function escrow_sellerCancelDelivery(
        uint256 _payRef,
        uint256 _productId
    ) public asActor {
        escrow.sellerCancelDelivery(_payRef, _productId);
    }

    function escrow_setEcommercePlatform(
        address _ecommercePlatform
    ) public asActor {
        escrow.setEcommercePlatform(_ecommercePlatform);
    }

    // function escrow_transferOwnership(address newOwner) public asActor {
    //     escrow.transferOwnership(newOwner);
    // }

    function escrow_updateDeliveryStatus(
        uint256 _payRef,
        uint256 _productId,
        bool _isDelivered
    ) public asActor {
        escrow.updateDeliveryStatus(_payRef, _productId, _isDelivered);
    }

    // function escrow_upgradeToAndCall(
    //     address newImplementation,
    //     bytes memory data
    // ) public payable asActor {
    //     escrow.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }

    function escrow_withdrawFunds(
        uint256 _payRef,
        uint256 _amount
    ) public asActor {
        escrow.withdrawFunds(_payRef, _amount);
    }
}
