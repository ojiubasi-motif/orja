// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Setup} from "./Setup.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@src/Common.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Setup {
    struct Vars {
        uint256 __ignore__;
    }

    address[] internal _registeredActors;
    mapping(address => uint256) internal _actorIndex;

    Vars internal _before;
    Vars internal _after;
    // user data ghosts
    User internal _userBefore;
    User internal _userAfter;
    // products data ghosts
    Product internal _productBefore;
    Product internal _productAfter;
    Product[] internal _listedProducts;

    modifier updateGhosts() {
        __before();
        _;
        __after();
    }

    modifier userUpdateGhosts(address userAddr) {
        __userBefore(userAddr);
        _;
        __userAfter(userAddr);
    }

    modifier productUpdateGhosts(uint256 productId) {
        __productBefore(productId);
        _;
        __productAfter(productId);
    }

    function __before() internal {}

    function __after() internal {}

    function __productBefore(uint256 productId) internal {
        _productBefore = products.getProductData(productId);
    }

    function __productAfter(uint256 productId) internal {
        _productAfter = products.getProductData(productId);
    }

    function __fetchProducts() internal {
        // fetch the 1st 100 products
        _listedProducts = products.getProducts(0, 100);
    }

    function __userBefore(address userAddr) internal {
        _userBefore = trussUser.getUserData(userAddr);
    }

    function __userAfter(address userAddr) internal {
        _userAfter = trussUser.getUserData(userAddr);
    }

    modifier ensureActorIsResgistered() {
        __ensureActorIsResgistered();
        _;
    }

    function __updateRegStatus(address _user) internal {
        // User memory user = trussUser.getUserData(actor);
        // bool notUser = user.account == address(0);
        // if(notUser) {
        //     // isActorUser = false;
        //     trussUser.register("Recon",Strings.toHexString(uint160(actor), 20));
        _registeredActors.push(_user);
        _actorIndex[_user] = _registeredActors.length - 1;
        // }
    }

    function __ensureActorIsResgistered() internal {
        address actor = _getActor();
        // address[] memory actors = _getActors();
        // bool found = false;
        // for (uint256 i = 0; i < actors.length; i++) {
        //     if (actors[i] == actor) {
        //         found = true;
        //         break;
        //     }
        // }
        // require(found, string.concat("Actor not registered: ", Strings.toHexString(uint160(actor), 20)));
        User memory user = trussUser.getUserData(actor);
        // bool notUser = user.account == address(0);
        if (user.account == address(0)) {
            // isActorUser = false;
            trussUser.register(
                "Recon",
                Strings.toHexString(uint160(actor), 20)
            );
            __updateRegStatus(actor);
        }
        // else{
        //     _isRegistered = true;
        // }
        // else {
        //     isActorUser = true;
        // }
        // try trussUser.getUserData(actor) returns (User memory res) {

        //     if(res.account == address(0)) {
        //         isActorUser = false;
        //     } else {
        //         isActorUser = true;
        //     }
        // } catch {
        //     revert("TrussUser.isUser call failed");
        // }
    }
}
