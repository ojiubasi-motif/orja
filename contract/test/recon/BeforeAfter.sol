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
    uint256 internal _escrowEthBalBefore;
    uint256 internal _escrowEthBalAfter;
    uint256 internal _actorEthBalBefore;
    uint256 internal _actorEthBalAfter;
    // string public _checkoutTokenSymbol;

    enum OpType {
        ADD,
        EDIT,
        REG
    }
    OpType internal currentOperation;

    Vars internal _before;
    Vars internal _after;
    // user data ghosts
    User internal _userBefore;
    User internal _userAfter;
    // products data ghosts
    Product internal _productBefore;
    Product internal _productAfter;
    Product[] internal _listedProducts;

    // modifier updateTokenSymbol(string memory symb) {
    //     __updateSymbol(symb);
    //     _;
    // }
    modifier updateGhosts() {
        __before();
        _;
        __after();
    }

    modifier updateGhostsWithOp(OpType op, uint256 id) {
        currentOperation = op;
        __productBefore(id);
        _;
        __productAfter(id);
    }

    modifier userUpdateGhosts(address userAddr) {
        __userBefore(userAddr);
        _;
        __userAfter(userAddr);
    }

    modifier actorEthBal(){
        // address _actor = _getActor();
        __actorEthBalBefore();
        _;
        // __actorEthBalAfter(_actor);
    }

    modifier productUpdateGhosts(uint256 productId) {
        __productBefore(productId);
        _;
        __productAfter(productId);
    }

    modifier updateProductsList() {
        _;
        __fetchProducts();
    }
    modifier fetchProductsList() {
        __fetchProducts();
        _;
    }
    modifier trackEscrowEthBalBefore() {
        __getEscrowEthBalBefore();
        _;
        // __getEscrowEthBalAfter();
    }
    // function __updateSymbol(string memory symbol) internal {
    //     _checkoutTokenSymbol = symbol;
    // }
    function __actorEthBalBefore() internal {
        address actor = _getActor();
        _actorEthBalBefore = actor.balance;
    }
    // function __actorEthBalAfter() internal {
    //     _actorEthBalAfter = address(_getActor()).balance;
    // }

    function __after() internal {}
    function __before() internal {}

    function __getEscrowEthBalBefore() internal {
        _escrowEthBalBefore = address(escrow).balance;
    }
    function __getEscrowEthBalAfter() internal  {
        _escrowEthBalAfter = address(escrow).balance;
    }
    function __productBefore(uint256 productId) internal {
        _productBefore = products.getProductData(productId);
    }

    function __productAfter(uint256 productId) internal {
        _productAfter = products.getProductData(productId);
    }

    function __fetchProducts() internal {
        // fetch the 1st 100 products
        _listedProducts = products.getProducts(0, 99);
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
        
    }
}
