// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/User.sol";

abstract contract TrussUserTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    // function trussUser_initialize(address initialOwner) public asActor {
    //     trussUser.initialize(initialOwner);
    // }

    function trussUser_register(
        string memory _lastName,
        string memory _firstName
    ) public asActor {
        trussUser.register(_lastName, _firstName);
    }

    // function trussUser_verifySeller(address _account)

    // =======clamped===========//__actorEthBalBefore
    function trussUser_register_clamped(uint8 _entropy) public {
        uint clamper = between(_entropy,1,4);
        _switchActor(clamper);
        trussUser_register("user-","sur-");
    }

    // function trussUser_renounceOwnership() public asActor {
    //     trussUser.renounceOwnership();
    // }

    // function trussUser_transferOwnership(address newOwner) public asActor {
    //     trussUser.transferOwnership(newOwner);
    // }

    // function trussUser_upgradeToAndCall(
    //     address newImplementation,
    //     bytes memory data
    // ) public payable asActor {
    //     trussUser.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }

    
}
