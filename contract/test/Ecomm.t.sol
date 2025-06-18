// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";
import "forge-std/console.sol";
// import {OrderLib} from "@library/OrderManager.sol";

contract EcommTest is Test {
    Ecommerce public orja;
    Escrow public escrow;
    address constant deployer = address(0x5E1A7C6f994cb18d331c72EAc68768c6e2965ac6);
    address constant ecomAddr = address(0xdC323Dc11d6a099342048D3153C38Ab8358D521D);
    address constant escrowAddr = address(0xE7E1dD095BcC04c42f9D76E1c9Df906BA4D5Abc7);
    address seller1;
    address buyer1;

    function setUp() public {
        // counter = new Counter();
        // counter.setNumber(0);
        vm.deal(deployer, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(buyer1, 100 ether);
        // vm.createSelectFork("sepolia");
        orja = Ecommerce(ecomAddr);
        escrow = Escrow(escrowAddr);
        seller1 = makeAddr("seller1");
        buyer1 = makeAddr("buyer1");
        // vm.prank(deployer);
        // escrow.setEcommercePlatform(ecomAddr);
    }

    function registerAndVerifySeller() public {
        // Test user registration
        // uint256 userId = 1;
        string memory lastName = "Doe";
        string memory firstName = "John";
        // uint256 userType = 1;
        // address account = address(0x1234567890123456789012345678901234567890);
        vm.prank(seller1);
        orja.register(lastName, firstName, Ecommerce.UserType.Seller);
        vm.prank(deployer);
        orja.verifySeller(seller1);
        // vm.stopPrank();
       

    }
    function testRegisterAndVerifySeller() public {
        registerAndVerifySeller();
        Ecommerce.User memory sellerData = orja.getUserData(seller1);
        console.log("registered seller id==>", sellerData.userId);

        assertEq(uint8(sellerData._userType), uint8(Ecommerce.UserType.Seller));
        assertEq(uint8(sellerData.verificationStatus), uint8(Ecommerce.VerificationStatus.Verified));
    }
    function listProduct() public {
        registerAndVerifySeller();
        // Test product listing
        vm.startPrank(seller1);
        // vm.prank(seller1);
        orja.listProduct(1 ether, "gucci pant", 300 days, 7 days);
        orja.listProduct(0.1 ether, "louise vuitton", 14 days, 7 days);
        orja.listProduct(0.001 ether, "prada", 3 days, 7 days);
        vm.stopPrank();
       
    }
    function testListProducts() public {
        listProduct();
         Ecommerce.Product[] memory products = orja.getProducts(0,5);
        // Ecommerce.Product memory listedProduct = orja.getProductData(products[0].productId);
        console.log("number of Listed Products==>", products.length);
        console.log("name of Listed Products 4==>", products[4].title);
        assertEq(products[2].unitPrice, 1 ether);
        assertEq(products[3].title, "louise vuitton");
    }

    function testBuyShopping() public {
        listProduct();
        // Test product purchase
        vm.deal(buyer1, 100 ether);
        vm.startPrank(buyer1);
        orja.register("Doe", "Jane", Ecommerce.UserType.Buyer);
        Ecommerce.Product[] memory products = orja.getProducts(0,4);
        orja.addProductToCart(products[3].productId, 2);
        orja.addProductToCart(products[2].productId, 3);

        (bool resp, uint payref) =  orja.checkOut{
            value:0.8 ether
        }(buyer1, "ETH");
        vm.stopPrank();
        // Ecommerce.Order[] memory orders = orja.getOrders(buyer1, 0, 5);
        console.log("payref==>", payref);
        assertEq(resp, true);
        // assertEq(orders[1].productId, 2);
    }

}