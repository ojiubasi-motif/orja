// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

// Your deps
import {Ecommerce} from "src/Ecomm.sol";
import {Escrow} from "src/Escrow.sol";
import {Products} from "src/Products.sol";
import {TrussUser} from "src/User.sol";
import "src/Common.sol";
// @me add more imports here
import {MockV3Aggregator} from "@feed/Mocks.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EchidnaTest {
    // @me add more contracts here
    Ecommerce ecommerce;
    TrussUser trussUser;
    Products products;
    Escrow escrow;

    // @me add more actors here
    address deployer = address(0xABCD);
    MockV3Aggregator public priceFeed;

    // address deployer;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    constructor() payable{
        // vm.deal(deployer, 100 ether);//deployer needs eth to deploy contracts

        // ecommerce = new Ecommerce(); // TODO: Add parameters here
        // escrow = new Escrow(); // TODO: Add parameters here
        // products = new Products(); // TODO: Add parameters here
        // trussUser = new TrussUser(); // TODO: Add parameters here
        // @me
        priceFeed = new MockV3Aggregator(8, 4461e8);
        // ====1========
        Escrow escrowImpl = new Escrow();
        Products productManagerImpl = new Products();
        TrussUser userManagerImpl = new TrussUser();
        Ecommerce orjaImpl = new Ecommerce();

        // ======2=======
        ERC1967Proxy userManager = new ERC1967Proxy(
            address(userManagerImpl),
            abi.encodeWithSelector(TrussUser.initialize.selector, address(this))
        );

        ERC1967Proxy escrowMngr = new ERC1967Proxy(
            address(escrowImpl),
            abi.encodeWithSelector(
                Escrow.initialize.selector,
                address(userManager),
                address(this)
            )
        );

        ERC1967Proxy productManager = new ERC1967Proxy(
            address(productManagerImpl),
            abi.encodeWithSelector(
                Products.initialize.selector,
                address(userManager),
                address(this)
            )
        );

        ERC1967Proxy orja = new ERC1967Proxy(
            address(orjaImpl),
            abi.encodeWithSelector(
                Ecommerce.initialize.selector,
                address(escrowMngr),
                address(userManager),
                address(productManager),
                address(this),//default admin
                address(priceFeed) //@test remove the address(priceFeed) b4 live deploy
            )
        );
        // ======3=======
        // wire them together
        Escrow(payable(address(escrowMngr))).setEcommercePlatform(
            address(orja)
        );

        ecommerce = Ecommerce(address(orja));
        trussUser = TrussUser(address(userManager));
        products = Products(address(productManager));
        escrow = Escrow(payable(address(escrowMngr)));

        // ===add some tokens to the accepted list====
        escrow.addTokenToAcceptedList(
            address(0),
            "ETH",
            address(0x694AA1769357215DE4FAC081bf1f309aDC325306)
        );
        // console.log("Eth==>", escrow.tokenSymbolToDetails["ETH"]);

        escrow.addTokenToAcceptedList(
            address(0xfCF7129A8a69a2BD7f2f300eFc352342D6c1638b),
            "USDC",
            address(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E)
        );

        // console.log("all contracts deployedsuccessfully...");
        // add actors
        // _addActor(address(0x1));
        // _addActor(address(0x2));
        // _addActor(address(0x3));
        // _addActor(address(0x4));
        // _addActor(deployer);

        // // credit all actors with 100 ETH
        // vm.deal(address(0x1), 100 ether);
        // vm.deal(address(0x2), 100 ether);
        // vm.deal(address(0x3), 100 ether);
        // vm.deal(address(0x4), 100 ether);
    }

    // function trussUser_oneAddrPerUser() public {
    //     if (trussUser.getUserData(msg.sender).account != address(0)) {
    //         (string memory _errMsg, ) = _getRevertMsg(
    //             abi.encodeWithSelector(
    //                 trussUser.register.selector,
    //                 "John",
    //                 "Doe"
    //             )
    //         );
    //         assert(
    //             keccak256(abi.encodePacked(_errMsg)) ==
    //                 keccak256(
    //                     abi.encodePacked("Address Already assigned to a user")
    //                 )
    //         );
    //     }
    // }
    function echidna_registeredUserIsUnverifiedByDefault() public {
        trussUser.register("John","Doe");
        User memory _user = trussUser.getUserData(msg.sender);
    assert(_user.account  == msg.sender && _user.verificationStatus == VerificationStatus.NotVerified);
    }
}
