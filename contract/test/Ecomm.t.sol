// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test} from "forge-std/Test.sol";
// import "../src/Common.sol";
// import {Ecommerce} from "../src/Ecomm.sol";
// import {Escrow} from "../src/Escrow.sol";
// import {TrussUser} from "../src/User.sol";
// import "forge-std/console.sol";
// import {MockV3Aggregator} from "./Mocks.sol";

// // import {OrderLib} from "@library/OrderManager.sol";

// contract EcommTest is Test, Base {
//     MockV3Aggregator public priceFeed;
//     Ecommerce public orja;
//     TrussUser public userManager;
//     Escrow public escrow;
//     // =========for sepolia deployed contracts========
//     // address constant deployer = address(0x5E1A7C6f994cb18d331c72EAc68768c6e2965ac6);
//     // address constant ecomAddr = address(0xfb472d475D8E86814d4E364A4DB1aFD68E9aF474);
//     // address constant escrowAddr = address(0xcd2Ab703fE6C5622F0CEb3ba0798B279a57B83df);

//     address seller1 ;
//     address buyer1 ;
//     address deployer = makeAddr("deployer");

//     function setUp() public {
        
//         vm.deal(deployer, 100 ether);
//         vm.deal(seller1, 100 ether);
//         vm.deal(buyer1, 100 ether);
//         vm.startPrank(deployer);//this is the current deployer
//         // priceFeed = new MockV3Aggregator(8,2518e8);
//         escrow = new Escrow();
//         orja = new Ecommerce(
//             // address(escrow)
//             );
//         userManager = new TrussUser();
//         escrow.setEcommercePlatform(address(orja), address(userManager));
//         vm.stopPrank();
//         // orja.addTokenToAcceptedList(
//         //     address(0),
//         //     "ETH",
//         //     address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
//         // );
//         // orja.addTokenToAcceptedList(
//         //     address(0xfCF7129A8a69a2BD7f2f300eFc352342D6c1638b),
//         //     "USDC",
//         //     address(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E)
//         // );
        

//         // ============== sepolia fork setup ==============
//         // Pass the escrow address as needed
//         // // vm.createSelectFork("sepolia");
//         // orja = Ecommerce(ecomAddr);
//         // escrow = Escrow(payable (escrowAddr));
//         seller1 = makeAddr("seller1");
//         buyer1 = makeAddr("buyer1");
//         // vm.prank(deployer);
//         // escrow.setEcommercePlatform(ecomAddr);
        
//     }

//     function registerAndVerifySeller() public {
//         // Test user registration
//         // uint256 userId = 1;
//         string memory lastName = "Doe";
//         string memory firstName = "John";
//         // uint256 userType = 1;
//         // address account = address(0x1234567890123456789012345678901234567890);
//         vm.prank(seller1);
//         userManager.register(lastName, firstName, UserType.Seller);
//         vm.prank(deployer);
//         userManager.verifySeller(seller1);
//         // vm.stopPrank();
//     }

//     function testRegisterAndVerifySeller() public {
//         registerAndVerifySeller();
//         User memory sellerData = userManager.getUserData(seller1);
//         console.log("registered seller id==>", sellerData.userId);

//         assertEq(uint8(sellerData._userType), uint8(UserType.Seller));
//         assertEq(
//             uint8(sellerData.verificationStatus),
//             uint8(VerificationStatus.Verified)
//         );
//     }

//     function listProduct() public {
//         registerAndVerifySeller();
//         // Test product listing
//         vm.startPrank(seller1);
//         // vm.prank(seller1);
//         orja.listProduct(50, "gucci pant", 300 days, 7 days);
//         orja.listProduct(350, "louise vuitton", 14 days, 7 days);
//         orja.listProduct(600, "prada", 3 days, 7 days);
//         vm.stopPrank();
//     }

//     function testListProducts() public {
//         listProduct();
//         Product[] memory products = orja.getProducts(0, 2);
//         // Product memory listedProduct = orja.getProductData(products[0].productId);
//         console.log("number of Listed Products==>", products.length);
//         console.log("name of Listed Products 4==>", products[2].title);
//         assertEq(products[1].unitPrice, 350);
//         assertEq(products[2].title, "prada");
//     }

//     function testBuyShopping() public {
//         listProduct();
//         // Test product purchase
//         vm.deal(buyer1, 10 ether);
//         vm.startPrank(buyer1);
//         userManager.register("Doe", "Jane", UserType.Buyer);
//         Product[] memory products = orja.getProducts(0, 2);
//         orja.addProductToCart(products[0].productId, 2);
//         orja.addProductToCart(products[1].productId, 6);
//         console.log("ecommercePlatform==>", escrow.ecommercePlatform());

//         orja.checkOutWithNative{value: 2 ether}("ETH");
//         // @dev==>check the escrow balance after checkout
//         vm.stopPrank();
//         // Ecommerce.Order[] memory orders = orja.getOrders(buyer1, 0, 5);
//         // console.log("payref==>", payref);
//         // vm.expectEmit();
//         // emit orja.
//         // assertEq(resp, true);
//         // assertLeDecimal(actual, expected, 2);
//         // assertEq(orders[1].productId, 2);
//     }

//      // needed to receive ETH
//     receive() external payable {}
// }
