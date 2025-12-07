// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// import "forge-std/Script.sol";
// import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// // import {Ecommerce} from "../src/Ecomm.sol";
// // import {Escrow} from "../src/Escrow.sol";
// import {TrussUser} from "../src/User.sol";
// // import {Products} from "../src/Products.sol";

// contract DeployUUPS is Script {
//     function run() external {
//         uint256 deployerKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
//         address deployer = vm.addr(deployerKey);

//         vm.startBroadcast(deployerKey);

//         // Step 1: Deploy implementations
//         // Ecommerce ecommerceImpl = new Ecommerce();
//         // Escrow escrowImpl = new Escrow();
//         TrussUser userManagerImpl = new TrussUser();
//         // Products productsImpl = new Products();

//         // address trussProxy;
//         address userProxy = 0xE4b7Ff08bDA75541620356d283eb10E3DB44EeDB;
//         // address productProxy = 0x1fa790Bf376013277B8Aa7506D330c417A1dc155;
//         // address ecommerceProxy = 0x09EB12CbCDa3E5ad65874bc54330782fa8d51DD9;
//         // address escrowProxy = 0x2163fee47139C909ad093e4E0eE22A119B5Df206;
//         // Step 2: Encode initialize() calls
//         bytes memory userManagerInitData = abi.encodeWithSelector(
//             TrussUser.initializev2.selector,
//             deployer
//         );

//         TrussUser(userProxy).upgradeToAndCall(
//             address(userManagerImpl),
//             userManagerInitData
//         );
//         // ERC1967Proxy userManagerProxy = new ERC1967Proxy(
//         //     address(userManagerImpl),
//         //     userManagerInitData
//         // );

//         // bytes memory escrowInitData = abi.encodeWithSelector(
//         //     Escrow.initializev2.selector,
//         //     address(userProxy), // pass userManager
//         //     deployer
//         // );
//         // Escrow(payable(escrowProxy)).upgradeToAndCall(
//         //     payable(address(escrowImpl)),
//         //     escrowInitData
//         // );
//         // ERC1967Proxy escrowProxy = new ERC1967Proxy(
//         //     payable(address(escrowImpl)),
//         //     escrowInitData
//         // );

//         // bytes memory productInitData = abi.encodeWithSelector(
//         //     Products.initializev2.selector,
//         //     address(userProxy), // pass userManager
//         //     deployer
//         // );
//         // Products(productProxy).upgradeToAndCall(
//         //     address(productsImpl),
//         //     productInitData
//         // );

//         // ERC1967Proxy productProxy = new ERC1967Proxy(
//         //     address(productsImpl),
//         //     productInitData
//         // );

//         // bytes memory ecommerceInitData = abi.encodeWithSelector(
//         //     Ecommerce.initializev2.selector,
//         //     address(escrowProxy), // pass escrow proxy address cos the initialize fn requires it as param also
//         //     address(userProxy), // pass userManager
//         //     address(productProxy), // pass product proxy address
//         //     deployer // initial admin
//         // );

//         // Ecommerce(ecommerceProxy).upgradeToAndCall(
//         //     address(ecommerceImpl),
//         //     ecommerceInitData
//         // );
//         // ERC1967Proxy ecommerceProxy = new ERC1967Proxy(
//         //     address(ecommerceImpl),
//         //     ecommerceInitData
//         // );

//         // Step 3: Wire them(Escrow and Ecommerce) together
//         // Escrow(payable(address(escrowProxy))).setEcommercePlatform(
//         //     address(ecommerceProxy)
//         // );

//         // let's list Eth as accepted token
//         // Escrow(payable(address(escrowProxy))).addTokenToAcceptedList(
//         //     address(0),
//         //     "ETH",
//         //     0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1 // chainlik feed address or sepolia-base eth
//         // );

//         vm.stopBroadcast();
//         console.log("User Manager Imp:", address(userManagerImpl));
//         // console.log("product Impl:", address(productsImpl));
//         // console.log("Ecommerce Impl:", address(ecommerceImpl));
//         // console.log("Escrow Impl:", address(escrowImpl));

//         console.log("User Manager proxy:", address(userProxy));
//         // console.log("product proxy:", address(productProxy));
//         // console.log("Ecommerce Proxy:", address(ecommerceProxy));
//         // console.log("Escrow Proxy:", address(escrowProxy));
//     }
// }
