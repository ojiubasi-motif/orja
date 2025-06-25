// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";

contract DeployUUPS is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Step 1: Deploy implementations
        Ecommerce ecommerceImpl = new Ecommerce();
        Escrow escrowImpl = new Escrow();

        // Step 2: Encode initialize() calls
        bytes memory escrowInitData = abi.encodeWithSelector(
            Escrow.initialize.selector,
            deployer
        );

        ERC1967Proxy escrowProxy = new ERC1967Proxy(
            payable(address(escrowImpl)),
            escrowInitData
        );

        bytes memory ecommerceInitData = abi.encodeWithSelector(
            Ecommerce.initialize.selector,
            address(escrowProxy), // pass escrow proxy address
            deployer              // initial admin
        );

        ERC1967Proxy ecommerceProxy = new ERC1967Proxy(
            address(ecommerceImpl),
            ecommerceInitData
        );

        // Step 3: Wire them together
        Escrow(payable(address(escrowProxy))).setEcommercePlatform(address(ecommerceProxy));

        vm.stopBroadcast();

        console.log("Ecommerce Impl:", address(ecommerceImpl));
        console.log("Escrow Impl:", address(escrowImpl));
        console.log("Ecommerce Proxy:", address(ecommerceProxy));
        console.log("Escrow Proxy:", address(escrowProxy));
    }
}
