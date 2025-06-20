// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";
import "forge-std/console.sol";
import {MockV3Aggregator} from "./Mocks.sol";

// import {OrderLib} from "@library/OrderManager.sol";

contract EcommTest is Test {
    MockV3Aggregator public priceFeed;
    Ecommerce public orja;
    Escrow public escrow;
    address constant deployer = address(0x5E1A7C6f994cb18d331c72EAc68768c6e2965ac6);
    address constant ecomAddr = address(0x5E3d3cc318Bd4A760Fb24fF7C851aFeF06CE2E25);
    address constant escrowAddr = address(0x61e7772709496451501DCd30a3D2422aA2Fdcb35);
    address seller1 ;
    address buyer1 ;
    // address deployer = makeAddr("deployer");

    function setUp() public {
        
        vm.deal(deployer, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(buyer1, 100 ether);
        vm.startPrank(deployer);
        // priceFeed = new MockV3Aggregator(8,2518e8);
        escrow = new Escrow();
        orja = new Ecommerce(address(escrow));
        escrow.setEcommercePlatform(address(orja));
        // orja.addTokenToAcceptedList(
        //     address(0),
        //     "ETH",
        //     address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        // );
        // orja.addTokenToAcceptedList(
        //     address(0xfCF7129A8a69a2BD7f2f300eFc352342D6c1638b),
        //     "USDC",
        //     address(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E)
        // );
        

        // ============== sepolia fork setup ==============
        // Pass the escrow address as needed
        // // vm.createSelectFork("sepolia");
        orja = Ecommerce(ecomAddr);
        escrow = Escrow(payable (escrowAddr));
        seller1 = makeAddr("seller1");
        buyer1 = makeAddr("buyer1");
        // vm.prank(deployer);
        escrow.setEcommercePlatform(ecomAddr);
        vm.stopPrank();
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
        assertEq(
            uint8(sellerData.verificationStatus),
            uint8(Ecommerce.VerificationStatus.Verified)
        );
    }

    function listProduct() public {
        registerAndVerifySeller();
        // Test product listing
        vm.startPrank(seller1);
        // vm.prank(seller1);
        orja.listProduct(50, "gucci pant", 300 days, 7 days);
        orja.listProduct(350, "louise vuitton", 14 days, 7 days);
        orja.listProduct(600, "prada", 3 days, 7 days);
        vm.stopPrank();
    }

    function testListProducts() public {
        listProduct();
        Ecommerce.Product[] memory products = orja.getProducts(0, 2);
        // Ecommerce.Product memory listedProduct = orja.getProductData(products[0].productId);
        console.log("number of Listed Products==>", products.length);
        console.log("name of Listed Products 4==>", products[2].title);
        assertEq(products[1].unitPrice, 350);
        assertEq(products[2].title, "prada");
    }

    function testBuyShopping() public {
        listProduct();
        // Test product purchase
        vm.deal(buyer1, 10 ether);
        vm.startPrank(buyer1);
        orja.register("Doe", "Jane", Ecommerce.UserType.Buyer);
        Ecommerce.Product[] memory products = orja.getProducts(0, 2);
        orja.addProductToCart(products[0].productId, 2);
        orja.addProductToCart(products[1].productId, 6);
        console.log("ecommercePlatform==>", escrow.ecommercePlatform());

        (bool resp, uint payref) = orja.checkOut{value: 2 ether}(buyer1, "ETH");
        vm.stopPrank();
        // Ecommerce.Order[] memory orders = orja.getOrders(buyer1, 0, 5);
        // console.log("payref==>", payref);
        assertEq(resp, true);
        // assertLeDecimal(actual, expected, 2);
        // assertEq(orders[1].productId, 2);
    }

     // needed to receive ETH
    receive() external payable {}
}
