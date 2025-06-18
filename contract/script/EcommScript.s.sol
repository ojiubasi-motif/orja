// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";

contract EcommScript is Script {

    uint256 private deployerPrivateKey;
    uint private sellerKey;
    address private deployer;
    address seller;
    // =============
    address constant ecomAddr = address(0xb16D26703699433DD30a5a2132F0766Ebf74f8Fd);
    address constant escrowAddr = address(0xe37262d65642CcE70323289fa93e213Db8d2e901);
    // =============
    Ecommerce public ecomm;
    Escrow public escrow;

    function setUp() public {
       deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
       deployer = vm.addr(deployerPrivateKey);
       sellerKey = vm.envUint("SELLER_KEY");
       seller = vm.addr(sellerKey);

    }

    function deployContracts() public returns (Ecommerce, Escrow) {
        vm.startBroadcast(deployerPrivateKey);
        escrow = new Escrow();
        ecomm = new Ecommerce(address(escrow));
        escrow.setEcommercePlatform(address(ecomm));
        vm.stopBroadcast();
        return (ecomm, escrow);
    }

    function registerAndVerifySeller(
        string memory lastName,
        string memory firstName
        // address seller
    ) public {
        vm.broadcast(sellerKey);
        ecomm.register(lastName, firstName, Ecommerce.UserType.Seller);
        vm.broadcast(deployerPrivateKey);
        ecomm.verifySeller(seller);
        // vm.stopBroadcast();
    }
    function listProduct(
        string memory productName,
        int256 price
        // string memory description
    ) public {
        vm.broadcast(sellerKey);
        ecomm.listProduct(price, productName, 365 days, 7 days);
    }
     

    function run() public {
        setUp();
        (ecomm, escrow) = deployContracts();
        registerAndVerifySeller("Doe", "John");
        listProduct("Laptop", 1.5 ether);
        listProduct("Smartphone", 0.8 ether);
        console.log("Ecommerce contract deployed at:", address(ecomm));
        console.log("Escrow contract deployed at:", address(escrow));
        console.log("Deployer address:", deployer);
    }
}