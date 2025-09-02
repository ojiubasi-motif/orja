// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";
import {TrussUser} from "../src/User.sol";
import {Products} from "../src/Products.sol";   

contract DeployUUPS is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Step 1: Deploy implementations
        Ecommerce ecommerceImpl = new Ecommerce();
        Escrow escrowImpl = new Escrow();
        TrussUser userManagerImpl = new TrussUser(); 
        Products productsImpl = new Products();

        // Step 2: Encode initialize() calls
        bytes memory userManagerInitData = abi.encodeWithSelector(
            TrussUser.initialize.selector,
            deployer
        );

        ERC1967Proxy userManagerProxy = new ERC1967Proxy(
            address(userManagerImpl),
            userManagerInitData
        );

        bytes memory escrowInitData = abi.encodeWithSelector(
            Escrow.initialize.selector,
            address(userManagerProxy), // pass userManager
            deployer
        );

        ERC1967Proxy escrowProxy = new ERC1967Proxy(
            payable(address(escrowImpl)),
            escrowInitData
        );

        
        bytes memory productInitData = abi.encodeWithSelector(
            Products.initialize.selector,
            address(userManagerProxy), // pass userManager
            deployer
        );

        ERC1967Proxy productProxy = new ERC1967Proxy(
            address(productsImpl),
            productInitData
        );

        bytes memory ecommerceInitData = abi.encodeWithSelector(
            Ecommerce.initialize.selector,
            address(escrowProxy), // pass escrow proxy address cos the initialize fn requires it as param also
            address(userManagerProxy), // pass userManager 
            address(productProxy), // pass product proxy address 
            deployer              // initial admin
        );

        ERC1967Proxy ecommerceProxy = new ERC1967Proxy(
            address(ecommerceImpl),
            ecommerceInitData
        );

        // Step 3: Wire them(Escrow and Ecommerce) together
        Escrow(payable(address(escrowProxy))).setEcommercePlatform(address(ecommerceProxy));

        // let's list Eth as accepted token
        Escrow(payable(address(escrowProxy))).addTokenToAcceptedList(
            address(0),
            "ETH",
            0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1 // chainlik feed address or sepolia-base eth
        );

        vm.stopBroadcast();
        console.log("User Manager Imp:", address(userManagerImpl));
        console.log("product Impl:", address(productsImpl));
        console.log("Ecommerce Impl:", address(ecommerceImpl));
        console.log("Escrow Impl:", address(escrowImpl));


        console.log("User Manager proxy:", address(userManagerProxy));
        console.log("product proxy:", address(productProxy));
        console.log("Ecommerce Proxy:", address(ecommerceProxy));
        console.log("Escrow Proxy:", address(escrowProxy));
    }
}
