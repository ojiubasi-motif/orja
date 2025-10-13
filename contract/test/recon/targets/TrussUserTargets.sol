// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";
import {BeforeAfter} from "../BeforeAfter.sol";
import {Properties} from "../Properties.sol";
// Chimera deps
import {vm} from "@chimera/Hevm.sol";

// Helpers
import {Panic} from "@recon/Panic.sol";

import "src/User.sol";
import "src/Common.sol";

abstract contract TrussUserTargets is BaseTargetFunctions, Properties {
    /// CUSTOM TARGET FUNCTIONS - Add your own target functions here ///

    /// AUTO GENERATED TARGET FUNCTIONS - WARNING: DO NOT DELETE OR MODIFY THIS LINE ///

    // function trussUser_initialize(address initialOwner) public asActor {
    //     trussUser.initialize(initialOwner);
    // }

    function trussUser_register() public asActor {
        address _actor = _getActor();
        // trussUser.register("Recon",Strings.toHexString(uint160(actor), 20));
        if (_registeredActors[_actorIndex[_actor]] == _actor) return;
        
        string memory _lastName = "fuzzer";
        string memory _firstName = Strings.toHexString(uint160(_actor), 20);
        trussUser.register(_lastName, _firstName);
        User memory _user = trussUser.getUserData(_actor);
        // if (_user.account == _actor) {
            __updateRegStatus(_actor);
        // }
        t(_user.account == _actor,"registered account should match actor");
        t(_user.verificationStatus == VerificationStatus.NotVerified,"user verification should be NotVerified");
        t(_user.userId != 0,"userId should not be zero");
    }

    // #1=truss state= one account(address) per user
    

    // #2=truss state= only admin can verify users
    // function trussUser_onlyAdminCanVerify(address _sellerAcc) public asActor {
    //     address _actor = _getActor();
    //     if (_sellerAcc == address(0)) return;//don't test zero address
    //     if(_actor == address(this)) return;//don't test admin

    //     __userBefore(_actor);
        
    //         trussUser.verifySeller(_sellerAcc);
    //         __userAfter(_actor);
            
    //         if(_userBefore.verificationStatus == VerificationStatus.NotVerified) {
    //             assert(_userAfter.verificationStatus == VerificationStatus.NotVerified);
    //         }
    //         assert(
    //             _userBefore.verificationStatus ==
    //                  _userAfter.verificationStatus
    //         );
           
    // }

    // function trussUser_renounceOwnership() public asActor {
    //     trussUser.renounceOwnership();
    // }

    // function trussUser_transferOwnership(address newOwner) public asActor {

    // }

    // function trussUser_renounceOwnership() public asActor {
    //     trussUser.renounceOwnership();
    // }

    // function trussUser_transferOwnership(address newOwner) public asActor {
    //     trussUser.transferOwnership(newOwner);
    // }

    // function trussUser_upgradeToAndCall(address newImplementation, bytes memory data) public payable asActor {
    //     trussUser.upgradeToAndCall{value: msg.value}(newImplementation, data);
    // }
    function adminVerifyUser(address _account) public asAdmin {
        if (_account == address(0)) return;
        __userBefore(_account);
        if(_userBefore.account == address(0) || _userBefore.verificationStatus == VerificationStatus.Verified) return;
        trussUser.verifySeller(_account);
        __userAfter(_account);
        t(
            _userBefore.verificationStatus ==
                VerificationStatus.NotVerified,"user verification should be NotVerified"
        );
        t(
            _userAfter.verificationStatus ==
                VerificationStatus.Verified,"user verification should be Verified"
        );
    }

    // function trussUser_adminVerifySeller(address _account) public asAdmin {
    //     address _actor = _getActor();
    //     if (_account == address(0)) return;
    //     __userBefore(_actor);
    //     trussUser.verifySeller(_account);
    //     __userAfter(_actor);
    //     assert(
    //         _userBefore.verificationStatus ==
    //             VerificationStatus.NotVerified
    //     );
    //     assert(
    //         _userAfter.verificationStatus ==
    //             VerificationStatus.Verified
    //     );
    // }
}
