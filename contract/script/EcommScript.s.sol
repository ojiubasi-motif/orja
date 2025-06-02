// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";

contract EcommScript is Script {

    uint256 private deployerPrivateKey;
    address private deployer;
    Ecommerce public ecomm;
    Escrow public escrow;

    function setUp() public {
       deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
       deployer = vm.addr(deployerPrivateKey);
    }

    function run() public {
        setUp();
        vm.startBroadcast(deployerPrivateKey);
        escrow = new Escrow();
        ecomm = new Ecommerce(address(escrow));
        escrow.setEcommercePlatform(address(ecomm));
        vm.stopBroadcast();
        console.log("Ecommerce contract deployed at:", address(ecomm));
        console.log("Escrow contract deployed at:", address(escrow));
        console.log("Deployer address:", deployer);
    }
}
