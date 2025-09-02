// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/Vm.sol"; // for
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import  "../src/Common.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";
import {TrussUser} from "../src/User.sol";
import {Products} from "../src/Products.sol";
import {MockV3Aggregator} from "./Mocks.sol";

// import {OrderLib} from "@library/OrderManager.sol";

contract EcommTest is Test {
    MockV3Aggregator public priceFeed;

    Ecommerce trussProxy;
    TrussUser userProxy;
    Products productProxy;
    Escrow escrowProxy;

    // =========for sepolia deployed contracts========

    address seller1 = makeAddr("seller1");
    address buyer1 = makeAddr("buyer1");
    address deployer = makeAddr("deployer");

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(seller1, 100 ether);
        vm.deal(buyer1, 100 ether);

        vm.startPrank(deployer); //this is the current deployer
        priceFeed = new MockV3Aggregator(8, 4461e8);
        // ====1========
        Escrow escrowImpl = new Escrow();
        Products productManagerImpl = new Products();
        TrussUser userManagerImpl = new TrussUser();
        Ecommerce orjaImpl = new Ecommerce();
        // ======2=======
        ERC1967Proxy userManager = new ERC1967Proxy(
            address(userManagerImpl),
            abi.encodeWithSelector(TrussUser.initialize.selector, deployer)
        );

        ERC1967Proxy escrow = new ERC1967Proxy(
            payable(address(escrowImpl)),
            abi.encodeWithSelector(
                Escrow.initialize.selector,
                address(userManager),
                deployer
            )
        );

        ERC1967Proxy productManager = new ERC1967Proxy(
            address(productManagerImpl),
            abi.encodeWithSelector(
                Products.initialize.selector,
                address(userManager),
                deployer
            )
        );

        ERC1967Proxy orja = new ERC1967Proxy(
            address(orjaImpl),
            abi.encodeWithSelector(
                Ecommerce.initialize.selector,
                address(escrow),
                address(userManager),
                address(productManager),
                deployer
                // address(priceFeed) //@test remove the address(priceFeed) b4 live deploy
            )
        );
        // ======3=======
        // wire them together
        Escrow(payable(address(escrow))).setEcommercePlatform(address(orja));

        trussProxy = Ecommerce(address(orja));
        userProxy = TrussUser(address(userManager));
        productProxy = Products(address(productManager));
        escrowProxy = Escrow(payable(address(escrow)));

        // ===add some tokens to the accepted list====
        escrowProxy.addTokenToAcceptedList(
            address(0),
            "ETH",
            address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        );
        // console.log("Eth==>", escrowProxy.tokenSymbolToDetails["ETH"]);
        escrowProxy.addTokenToAcceptedList(
            address(0xfCF7129A8a69a2BD7f2f300eFc352342D6c1638b),
            "USDC",
            address(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E)
        );
        vm.stopPrank();
        // console.log("accepted tokens1==>", escrowProxy.getAcceptedTokens()[0]);
        // console.log("accepted tokens2==>", escrowProxy.getAcceptedTokens()[1]);
        // string[] memory tokens = escrowProxy.getAcceptedTokens();
        // console.log("listed tokens==>", tokens);
        // ============== sepolia fork setup ==============
        // Pass the escrow address as needed
        // // vm.createSelectFork("sepolia");
        // orja = Ecommerce(ecomAddr);
        // escrow = Escrow(payable (escrowAddr));

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
        userProxy.register(lastName, firstName);
        vm.prank(deployer);
        userProxy.verifySeller(seller1);
        // vm.stopPrank();
    }

    function testRegisterAndVerifySeller() public {
        registerAndVerifySeller();
        User memory sellerData = userProxy.getUserData(seller1);
        console.log("registered seller id==>", sellerData.userId);
        
        // assertEq(uint8(sellerData._userType), uint8(UserType.Seller));
        assertEq(
            uint8(sellerData.verificationStatus),
            uint8(VerificationStatus.Verified)
        );
    }

    function listProduct() public {
        registerAndVerifySeller();
        // Test product listing
        vm.startPrank(seller1);
        // vm.prank(seller1);
        productProxy.listProduct(50, "gucci pant", 300 days, 7 days);
        productProxy.listProduct(350, "louise vuitton", 14 days, 7 days);
        productProxy.listProduct(600, "prada", 3 days, 7 days);
        vm.stopPrank();
    }

    function testListProducts() public {
        listProduct();
        Product[] memory products = productProxy.getProducts(0, 2);
        // Product memory listedProduct = orja.getProductData(products[0].productId);
        console.log("number of Listed Products==>", products.length);
        console.log("name of Listed Products 4==>", products[2].title);
        assertEq(products[1].unitPrice, 350);
        assertEq(products[2].title, "prada");
    }

    function shop()
        public
        returns (
            uint _escrowBalB4,
            uint _payref,
            string memory _tk,
            uint256 _amount,
            uint256 _buyerId
        )
    {
        // Setup: Register and verify a seller, list products
        listProduct();
        // Test product purchase
        vm.deal(buyer1, 10 ether);
        vm.startPrank(buyer1);
        userProxy.register("Doe", "Jane");
        // User memory buyer1Data = userProxy.getUserData(buyer1);

        Product[] memory products = productProxy.getProducts(0, 2);

        trussProxy.addProductToCart(products[0].productId, 2);
        trussProxy.addProductToCart(products[1].productId, 6);

        _escrowBalB4 = address(escrowProxy).balance;
        //step1= Start recording logs
        vm.recordLogs();

        trussProxy.checkOutWithNative{value: 2 ether}("ETH");
        //step2= Fetch recorded logs
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // @dev==>check the escrow balance after checkout
        vm.stopPrank();

        for (uint256 i = 0; i < entries.length; i++) {
            // Match the event signature
            if (
                entries[i].topics[0] ==
                keccak256("SuccessfulCheckout(uint256,uint256,string,uint256)")
            ) {
                // 1 First topic is the signature
                // 2 Second topic (topics[1]) is the indexed 'userId' (uint256)
                _buyerId = uint256(entries[i].topics[1]);
                // 3rd is the indexed value paymentRef (uint256)
                _payref = uint256(entries[i].topics[2]);

                // Non-indexed data (token symbol and amount) are ABI-encoded in data
                (_tk, _amount) = abi.decode(entries[i].data, (string, uint256));
            }
        }
    }

    function testShoping() public {
        (
            uint escrowBalB4,
            uint _payref,
            string memory _symbol,
            uint amount,
            uint256 buyer1Id
        ) = shop();
        uint escrowBalAfter = address(escrowProxy).balance;
        vm.prank(address(escrowProxy));
        uint userEscrowBal = escrowProxy.getWalletBalance(buyer1Id, _payref);
        assertEq(_symbol, "ETH");
        assertEq(amount, userEscrowBal);
        assertEq(escrowBalAfter, escrowBalB4 + userEscrowBal);
    }

    function updateDeliveryStatus(uint _productId, uint _payref, bool _isDelivered) public {
        // vm.prank(buyer1);
        escrowProxy.updateDeliveryStatus(_payref, _productId, _isDelivered);
    }

    function withdrawFunds(uint256 _payRef, uint256 _amount) public {
        // vm.prank(buyer1);
        escrowProxy.withdrawFunds(_payRef, _amount);
    }

    function testUpdateAndWithdraw () public {
        (
            uint escrowBalB4,
            uint _payref,
            string memory _symbol,
            uint amount,
            uint256 buyer1Id
        ) = shop();
        
        //update product status to delivered
        uint balB4 = buyer1.balance;
        uint escrowBalB4Withdraw = address(escrowProxy).balance;

        vm.startPrank(buyer1);
        OrderItem[] memory cartItems = trussProxy.getCart(buyer1Id);
        vm.warp(block.timestamp + 7 days + 61 seconds); //fast forward time by 7 days + 61 seconds==there's grace of 60secs in the contract
        updateDeliveryStatus(cartItems[0].productId, _payref, false);
        updateDeliveryStatus(cartItems[1].productId, _payref, true);
        uint userWithdrawableBalB4 = escrowProxy.getWithdrawableBalance(buyer1Id, _payref);
        // uint userWalletBalb4 = buyer1.balance;
        console.log("user withdrawable bal b4==>", userWithdrawableBalB4);
        console.log("total amount==>", amount);
        withdrawFunds(_payref, userWithdrawableBalB4);//withdraw everything withdrawable
        vm.expectRevert(bytes("No funds available for withdrawal"));
        withdrawFunds(_payref, amount - userWithdrawableBalB4);//try to withdraw funds that are not withdrawable
        uint userEscrowBalAfter = escrowProxy.getWalletBalance(buyer1Id, _payref);
        uint userWithdrawableBalAfter = escrowProxy.getWithdrawableBalance(buyer1Id, _payref);
        vm.stopPrank();

        vm.startPrank(seller1);
        uint sellerBalB4 = seller1.balance;
        uint seller1Id = userProxy.getUserData(seller1).userId;
        uint sellerWithdrawableBalB4 = escrowProxy.getWithdrawableBalance(seller1Id, _payref);
        escrowProxy.withdrawFunds(_payref,sellerWithdrawableBalB4);//seller withdraws his own withdrawable balance
        vm.stopPrank();

        uint escrowBalAfterWithdraw = address(escrowProxy).balance;
        
        assertEq(seller1.balance, sellerWithdrawableBalB4 + sellerBalB4);
            console.log("escrow bal after taking %==>", escrowBalAfterWithdraw);
            console.log("user escrow bal after update and withdraw==>", userEscrowBalAfter);
            console.log("user withdrawable after update and withdraw==>", userWithdrawableBalAfter);

        assertEq(buyer1.balance, balB4 + userWithdrawableBalB4);
        // assertEq(userEscrowBalAfter, 0);
        assertEq(escrowProxy.getWalletBalance(seller1Id, _payref), 0);
        assertEq(escrowBalAfterWithdraw + (buyer1.balance - balB4) + (seller1.balance - sellerBalB4),  amount);
    }

    // needed to receive ETH
    receive() external payable {}
}
