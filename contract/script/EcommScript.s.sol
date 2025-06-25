// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";
// ==upgradeable imports==\
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
contract EcommScript is Script {

    uint256 private deployerPrivateKey;
    uint private sellerKey;
    address private deployer;
    address seller;
    // =============
    // address  ecomAddr;
    // //  = address(0xb16D26703699433DD30a5a2132F0766Ebf74f8Fd);
    // address  escrowAddr;
    //  = address(0xe37262d65642CcE70323289fa93e213Db8d2e901);
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
        ecomm = new Ecommerce(
            // address(escrow)
            );///===change to price feed address if needed
        escrow.setEcommercePlatform(address(ecomm));
        ecomm.addTokenToAcceptedList(address(0),"ETH",address(0x694AA1769357215DE4FAC081bf1f309aDC325306));
        ecomm.addTokenToAcceptedList(address(0xfCF7129A8a69a2BD7f2f300eFc352342D6c1638b),"USDC",address(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E));
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
        uint256 price
        // string memory description
    ) public {
        vm.broadcast(sellerKey);
        ecomm.listProduct(price, productName, 365 days, 7 days);
    }
     

    function run() public {
        setUp();
        (ecomm, escrow) = deployContracts();
        registerAndVerifySeller("Doe", "John");
        // listProduct("speaker", 500);
        // listProduct("Smartphone", 800);
        console.log("Ecommerce contract deployed at:", address(ecomm));
        console.log("Escrow contract deployed at:", address(escrow));
        console.log("Deployer address:", deployer);
    }
}

contract DeployEcommScript is Script {

     uint256 private deployerPrivateKey;
    // uint private sellerKey;
    address private deployer;
    // address seller;
   
    Ecommerce public ecomm;
    Escrow public escrow;

    address escrowAddr;
    address ecommAddr;

    function setUp() public {
       deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
       deployer = vm.addr(deployerPrivateKey);
       // sellerKey = vm.envUint("SELLER_KEY");
    }

    function deployEscrow() private {
        // setUp();
        vm.startBroadcast(deployerPrivateKey);
        escrow = new Escrow();
        escrowAddr = address(escrow);
        vm.stopBroadcast();
        // _escrowAddr = address(escrow);
    }

    function deployEcomm() private {
        vm.startBroadcast(deployerPrivateKey);
        ecomm = new Ecommerce();
        ecommAddr = address(ecomm);
        vm.stopBroadcast();
        // _ecomAddr = address(ecomm);
    }

    function run() public {
        setUp();
        deployEscrow();
        deployEcomm();
        address ecommImpl = ecommAddr;
        address escrowImpl = escrowAddr;
       
        vm.startBroadcast(deployerPrivateKey);
         // ===deploy escrow proxy===
        bytes memory escrowData = abi.encodeWithSelector(
            Escrow(payable(escrowImpl)).initialize.selector,
            deployer // Initial owner/admin of the contract
        );
        ERC1967Proxy escrowProxy = new ERC1967Proxy(escrowImpl, escrowData);

        // ====deploy ecomm proxy===
        bytes memory ecommData = abi.encodeWithSelector(
            Ecommerce(ecommImpl).initialize.selector,
            address(escrowProxy), // Pass the escrow proxy address to the Ecommerce contract
            deployer // Initial owner/admin of the contract
        );
        ERC1967Proxy ecommProxy = new ERC1967Proxy(ecommImpl, ecommData);

        // Set the ecommerce platform address in the escrow contract
        Escrow escrowContract = Escrow(payable(escrowProxy));
        escrowContract.setEcommercePlatform(address(ecommProxy));

        vm.stopBroadcast();
        
    }
}   