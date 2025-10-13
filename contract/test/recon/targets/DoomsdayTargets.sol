// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
import {TrussUserTargets} from "./TrussUserTargets.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";
import "@src/Common.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

abstract contract DoomsdayTargets is BaseTargetFunctions, Properties {
    TrussUserTargets trussUserTargets;
    /// Makes a handler have no side effects
    /// The fuzzer will call this anyway, and because it reverts it will be removed from shrinking
    /// Replace the "withGhosts" with "stateless" to make the code clean
    modifier stateless() {
        _;
        revert("stateless");
    }

    function doomsday_verifyUserByNonAdmin_revert(
        address _sellerAcc
    ) public stateless asActor {
        if (address(_getActor()) != admin) {
            try trussUser.verifySeller(_sellerAcc) {
                assert(false); //should never reach this line
            } catch (bytes memory err) {
                bool expectedError = checkError(
                    err,
                    "only admin can call this function"
                ); // catches the specific revert we're interested in
                assert(expectedError);
            }
        }
    }

    function doomsday_addressMultipleReg_revert()
        public
        stateless
        asActor
        ensureActorIsResgistered
    {
        // if (_actorIndex[_getActor()] != 0) {
            try trussUser.register("John", "Doe") {
                assert(false); //should not reach here
            } catch (bytes memory err) {
                bool expectedError = checkError(
                    err,
                    "Address Already assigned to a user"
                ); // catches the specific revert we're interested in
                assert(expectedError);
                // }
            }
        // }
    }


}
