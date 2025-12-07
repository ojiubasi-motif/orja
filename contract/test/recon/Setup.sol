// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

// Chimera deps
import {BaseSetup} from "@chimera/BaseSetup.sol";
import {vm} from "@chimera/Hevm.sol";
import "forge-std/console.sol";

// Managers
import {ActorManager} from "@recon/ActorManager.sol";
import {AssetManager} from "@recon/AssetManager.sol";
import {MockERC20} from "@recon/MockERC20.sol";

// Helpers
import {Utils} from "@recon/Utils.sol";

// Your deps
import {Ecommerce} from "src/Ecomm.sol";
import {Escrow} from "src/Escrow.sol";
import {Products} from "src/Products.sol";
import {TrussUser} from "src/User.sol";
// @me add more imports here..
import {MockV3Aggregator1} from "./MockFeed.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//@dig this is for other targetsContracts that might use it to convert address to string
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract Setup is BaseSetup, ActorManager, AssetManager, Utils {
    // Ecommerce ecommerce;
    // Escrow escrow;
    // Products products;
    // TrussUser trussUser;

    // @me add more contracts here
    Ecommerce ecommerce;
    TrussUser trussUser;
    Products products;
    Escrow escrow;

    // @me add more actors here
    // address deployer = address(0xABCD);
    // MockV3Aggregator feed1;
    // MockV3Aggregator  feed2;
    // MockV3Aggregator  feed3;
    MockV3Aggregator1 ETHfeed;
    // MockV3Aggregator1 feedA;

    // mapping(string => MockV3Aggregator1)  tokenToFeed;
    address admin;

    // address deployer;

    /// === Setup === ///
    /// This contains all calls to be performed in the tester constructor, both for Echidna and Foundry
    function setup() internal virtual override // asDeployer
    {
        // // ======1========
        // Escrow escrowImpl = new Escrow();
        // Products productManagerImpl = new Products();
        // TrussUser userManagerImpl = new TrussUser();
        // Ecommerce orjaImpl = new Ecommerce();

        // // ETHfeed = new MockV3Aggregator1(8, 4141e8);

        // // ======2=======
        // ERC1967Proxy userManager = new ERC1967Proxy(
        //     address(userManagerImpl),
        //     abi.encodeWithSelector(TrussUser.initialize.selector, address(this))
        // );

        // ERC1967Proxy escrowMngr = new ERC1967Proxy(
        //     address(escrowImpl),
        //     abi.encodeWithSelector(
        //         Escrow.initialize.selector,
        //         address(userManager),
        //         address(this)
        //     )
        // );

        // ERC1967Proxy productManager = new ERC1967Proxy(
        //     address(productManagerImpl),
        //     abi.encodeWithSelector(
        //         Products.initialize.selector,
        //         address(userManager),
        //         address(this)
        //     )
        // );

        // ERC1967Proxy orja = new ERC1967Proxy(
        //     address(orjaImpl),
        //     abi.encodeWithSelector(
        //         Ecommerce.initialize.selector,
        //         address(escrowMngr),
        //         address(userManager),
        //         address(productManager),
        //         address(this)
        //         // address(priceFeed) //@test remove the address(priceFeed) b4 live deploy
        //     )
        // );

        // ecommerce = Ecommerce(address(orja));
        // trussUser = TrussUser(address(userManager));
        // products = Products(address(productManager));
        // escrow = Escrow(payable(address(escrowMngr)));

        // // ======3=======
        // // wire them together
        // escrow.setEcommercePlatform(address(orja));
        // // ===add some tokens to the accepted list====
        // // ====================
        // //  _newAsset(18);
        // // string memory symbol1 = MockERC20(address(tokenA)).symbol();
        // // feedA = new MockV3Aggregator1(10, 510e10);
        // ETHfeed = new MockV3Aggregator1(8, 4141e8);
        // escrow.addTokenToAcceptedList(address(ETHfeed), "ETH", address(0)); //tokeAddr, symb, fedAddr

        // admin = address(this);
        // //  for a smooth testing, setup some basic important things
        // _addActor(address(0x1));
        // _addActor(address(0x2));
        // _addActor(address(0x3));
        // _addActor(address(0x4));

        // // _setupAssetsAndApprovals();
        // vm.deal(address(0x1), 100 ether);
        // vm.deal(address(0x2), 100 ether);
        // vm.deal(address(0x3), 100 ether);
        // vm.deal(address(0x4), 100 ether);
    }

    function _initSettings() internal {
        // any settings that needs to be set after deployment can be done here
        trussUser.register("Admin", "Owner");
        trussUser.verifySeller(address(this));
        products.listProduct(1e8, "test-product", 30 days, 7 days);
        products.listProduct(2e8, "test-product-2", 300 days, 1 days);
    }

    function _addTokensToAcceptedList() internal {
        // address [] memory assets = _getAssets();
        // escrow.addTokenToAcceptedList(
        //     address(feedA),
        //     "mockA",
        //     assets[0]
        // );
        //
        escrow.addTokenToAcceptedList(address(ETHfeed), "ETH", address(0)); //tokeAddr, symb, fedAddr
    }

    function _setupAssetsAndApprovals() internal {
        _newAsset(18);
        address[] memory actors = _getActors();
        uint256 amount = type(uint88).max;
        // console.log("actors==>", actors[1]);
        // Process each asset separately to reduce stack depth
        for (
            uint256 assetIndex = 0;
            assetIndex < _getAssets().length;
            assetIndex++
        ) {
            address asset = _getAssets()[assetIndex];

            // Mint to actors
            for (uint256 i = 0; i < actors.length; i++) {
                vm.prank(actors[i]);
                MockERC20(asset).mint(actors[i], amount);
                // console.log("actors current bal==>", MockERC20(asset).balanceOf(actors[i]));
            }

            // Approve to morpho
            for (uint256 i = 0; i < actors.length; i++) {
                vm.prank(actors[i]);
                MockERC20(asset).approve(address(ecommerce), type(uint88).max);
            }
        }
    }

    // function addTokensToAcceptedList() internal {
    //     // address[] memory activeActors = _getActors();
    //     // vm.deal(deployer, 100 ether);//deployer needs eth to deploy contracts
    //     // address asset1 = _newAsset(9);
    //     // address asset2 = _newAsset(22);
    //     // address asset3 = _newAsset(6);
    //     // _finalizeAssetDeployment(activeActors, activeActors, 1000 ether); //mint and approve the assets to all actors
    //     // @me
    //     // string memory symbol1 = MockERC20(address(asset1)).symbol();
    //     // string memory symbol2 = MockERC20(address(asset2)).symbol();
    //     // string memory symbol3 = MockERC20(address(asset3)).symbol();

    //     // address[] memory assets = _getAssets();
    //     // feeds
    //     feed1 = new MockV3Aggregator(23e8, 8, "M1");
    //     // feed2 = new MockV3Aggregator(233e9, 9, symbol2);
    //     // feed3 = new MockV3Aggregator(3e12, 12, symbol3);
    //     ETHfeed = new MockV3Aggregator(4141e8, 8, "ETH");

    //     tokenToFeed["M1"] = feed1;
    //     // tokenToFeed[symbol2] = feed2;
    //     // tokenToFeed[symbol3] = feed3;
    //     tokenToFeed["ETH"] = ETHfeed;
    //     escrow.addTokenToAcceptedList(address(0x0), "ETH", address(ETHfeed));
    //     escrow.addTokenToAcceptedList(address(0x278), "M1", address(feed1));
    //     // escrow.addTokenToAcceptedList(address(asset2), symbol2, address(feed2));
    //     // escrow.addTokenToAcceptedList(address(asset3), symbol3, address(feed3));
    // }

    // function _registerActorAsUser(address _actor) private {
    //     trussUser.register("Recon",Strings.toHexString(uint160(_actor), 20));
    // }
    /// === MODIFIERS === ///
    /// Prank admin and actor
    // @me
    // modifier asDeployer() {
    //     vm.prank(deployer);
    //     _;
    // }

    modifier asAdmin() {
        vm.prank(address(this));
        _;
    }

    modifier asActor() {
        vm.prank(address(_getActor()));
        _;
        // vm.stopPrank();
    }
}
