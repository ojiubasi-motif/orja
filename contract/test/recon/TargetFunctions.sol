// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

// Targets
// NOTE: Always import and apply them in alphabetical order, so much easier to debug!
import { AdminTargets } from "./targets/AdminTargets.sol";
import { DoomsdayTargets } from "./targets/DoomsdayTargets.sol";
import { EcommerceTargets } from "./targets/EcommerceTargets.sol";
import { EscrowTargets } from "./targets/EscrowTargets.sol";
import { ManagersTargets } from "./targets/ManagersTargets.sol";
import { ProductsTargets } from "./targets/ProductsTargets.sol";
import { TrussUserTargets } from "./targets/TrussUserTargets.sol";
// @me add more imports here
import {PriceFeedTargets} from "./targets/PriceFeedTargets.sol";

abstract contract TargetFunctions is
    AdminTargets,
    DoomsdayTargets,
    // EcommerceTargets,
    // EscrowTargets,
    ManagersTargets,
    ProductsTargets,
    TrussUserTargets,
    PriceFeedTargets
{
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///


    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///
}
