// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

abstract contract AdminTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
    function trussAdmin_verifySeller(address _account) public asAdmin {
        trussUser.verifySeller(_account);
    }
    // ===clamped====//__actorEthBalBefore
    function trussAdmin_verifySeller_clamped() public {
        address[] memory allActors = _getActors();
        for(uint i=1; i < allActors.length; i++){
            trussAdmin_verifySeller(allActors[i]);
        }
    }

}
