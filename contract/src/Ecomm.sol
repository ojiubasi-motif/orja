// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import "@custom-interfaces/IEscrow.sol";
import "./Common.sol";
import "./ERC20Base.sol";
import "@chainlink/AggregatorV3Interface.sol";
import {IUser, IShop, IProduct} from "./interfaces/IEcomm.sol";
import {Utils, ProductsUtils} from "./lib/Utils.sol";

// import "forge-std/console.sol";

contract Ecommerce is
    IShop,
    Base,
    ERC20Base
{
    IEcomEscrow escrowInterface;
    IUser userInterface;
    IProduct productInterface;
    //
    // AggregatorV3Interface internal priceFeed;

    address payable escrowContract;
    address userContract;
    address productContract;

    uint constant USD_PRECISION = 1e8; //
    uint8 constant USD_DECIMALS = 8;

    mapping(uint256 _payRef => mapping(string _token => uint256 _checkoutRate)) checkoutTokenRate;
    // TokenDetails[] acceptedTokens;

    //for easy fetching of user record from users array
    
    mapping(uint256 _paymentReference => uint256 _amount)
        private _checkoutAmount;
    mapping(uint256 _buyerId => OrderItem[] _products) private cart; //userId to cart
    mapping(uint256 _buyerId => bool) private isCartProcessed; //userId to cart processed status

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
        // require(msg.sender != address(0), "invalid owner address");
        // owner = msg.sender;
        // require(
        //     _escrowAddress != address(0) && msg.sender == owner,
        //     "Invalid ESCROW address and/or unauthorized contract owner"
        // );
        // escrowContract = payable(_escrowAddress);
        // // priceFeed = AggregatorV3Interface(_feddAddr);
        // escrowInterface = IEcomEscrow(address(escrowContract));
        // adminDAOcontract = _adminDaoAddress;
    }

    function initialize(
        address _escrowAddress,
        address _userContract,
        address _productContract,
        address initialOwner
    )
        public
        // address _feedAddr //  address _adminDaoAddress
        initializer
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        require(_escrowAddress != address(0), "Invalid ESCROW address");
        require(_userContract != address(0), "Invalid user contract address");
        require(_productContract!= address(0), "Invalid product contract address");

        escrowContract = payable(_escrowAddress);
        userContract = _userContract;
        productContract = _productContract;
        // priceFeed = AggregatorV3Interface(_feedAddr);
        escrowInterface = IEcomEscrow(address(escrowContract));
        userInterface = IUser(address(userContract));
        productInterface = IProduct(address(productContract));
        // adminDAOcontract = _adminDaoAddress;
    }

    //    ====getters for private variables============
    // function userCheckoutAmount(uint256 _payRef) public view returns (uint256) {
    //     return _checkoutAmount[_payRef];
    // }

    //  ======public functions============

    function getCart(
        uint256 _userId
    )
        external
        view
        override
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            escrowContract
        )
        returns (OrderItem[] memory)
    {
        // User memory userData = userInterface.getUserData(_account);
        OrderItem[] memory cartItems = cart[_userId];
        require(cartItems.length > 0, "Cart is empty");
        return cartItems;
    }

    

    // @dig try to use encoded data and private function to update multiple product details once
   
    function addProductToCart(
        uint256 _productId,
        uint32 _qty
    )
        public
        // address _account
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            escrowContract
        )
    {
        Product memory product = productInterface.getProductData(_productId);
        User memory user = userInterface.getUserData(msg.sender);
        require(
            !isCartProcessed[user.userId],
            "Cart already being processed, u can't add more items"
        );
        OrderItem memory item = OrderItem({
            sellerId: product.sellerId,
            productId: product.productId,
            qty: _qty,
            unitPrice: product.unitPrice,
            orderStatus: OrderStatus.Processing,
            _proposedDeliveryTime: product.whenToExpectDelivery // in miliseconds
        });
        cart[user.userId].push(item);
        // calculateUserBill(user.userId); // calculate the total bill for the user
        // userToproductQtyInCart[user.userId][product.productId] = _qty;
    }
    // @dig is there a need to add-to-cart when checkout isn't assured? make it private
    // @dig zk tech could be used to augment this process too.

    function calculateUserBill(uint256 _userId) private returns (uint256) {
        OrderItem[] memory cartItems = cart[_userId];
        require(cartItems.length > 0, "Cart is empty for this user");
         Product memory productData;
        uint256 cumm = 0;
        for (uint256 i = 0; i < cartItems.length; ++i) {
            productData = productInterface.getProductData(cartItems[i].productId);
            if (productData.productId == 0) {
                continue; // skip if product is not valid
            }
            if (productData.sellerId == 0) {
                continue; // skip if product seller is not valid
            }
            // int8 quantity = userToproductQtyInCart[userData.userId][productId];
            cumm += (productData.unitPrice * cartItems[i].qty);
        }
        _checkoutAmount[_userId] = cumm;

        return _checkoutAmount[_userId];
    }


    function checkOutWithNative(
        // address _account,
        string memory _payToken
    )
        public
        payable
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            escrowContract
        )
    // returns (bool _resp, uint _payref)
    {
        _checkOutWithNative(msg.sender, _payToken);
    }

    function checkOutWithUSD(
        // address msg.sender,
        string memory _payToken
    )
        public
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            escrowContract
        )
    {
        _checkOutWithUsd(msg.sender, _payToken);
    }

    // ======private and internal fns=============

    function _generatePaymentRefence(
        address _account
    ) private view returns (uint64 ref) {
        // @dig find a better way to generate random value
        ref = uint64(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _account,
                        block.timestamp,
                        userInterface.getUserData(_account).userId
                        // userInterface.users[userInterface.userIdToRecordIndex[_account]].userId
                    )
                )
            )
        );
    }

    function _checkOutWithNative(
        address _account,
        string memory _paymentTokenSymbol
    ) private {
        User memory userData = userInterface.getUserData(_account);

        require(!isCartProcessed[userData.userId], "Cart already processed");
        isCartProcessed[userData.userId] = true; // mark the cart as processed

        uint256 amountPayable = calculateUserBill(userData.userId);
        uint256 paymentRef = _generatePaymentRefence(_account);

        // _checkoutAmount[paymentRef] = amountPayable;
        if (keccak256(bytes(_paymentTokenSymbol)) == keccak256(bytes("ETH"))) {
            (
                uint expectedEthValue,
                bytes memory feedData
            ) = _getTokenEquivalence(amountPayable, "ETH");

            require(
                msg.value >= expectedEthValue,
                "insufficient amount of ETH"
            );

            _checkoutAmount[userData.userId] = 0;
            // amountPayable = 0; // reset the amount payable after checkout

            (bool payResponse, uint payRef) = escrowInterface
                .payForItemsWithETH{value: expectedEthValue}(
                userData.userId,
                expectedEthValue,
                feedData,
                paymentRef
            );
            // _checkoutAmount[paymentRef] = 0; // store the amount payable for this payment reference
            require(payResponse, "payment via ETH failed, try again later");
            emit SuccessfulCheckout(
                userData.userId,
                payRef,
                _paymentTokenSymbol,
                expectedEthValue
            );
        }
    }

    function _checkOutWithUsd(
        address _account,
        string memory _paymentTokenSymbol
    ) private {
        User memory userData = userInterface.getUserData(_account);

        require(!isCartProcessed[userData.userId], "Cart already processed");
        isCartProcessed[userData.userId] = true; // mark the cart as processed

        uint256 amountPayable = calculateUserBill(userData.userId);
        uint256 paymentRef = _generatePaymentRefence(_account);

        require(isAccepted[_paymentTokenSymbol], "invalid token");
        require(
            tokenSymbolToDetails[_paymentTokenSymbol].feedAddr != address(0) &&
                tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr !=
                address(0),
            "please specify a valid token for payment"
        );

        require(
            amountPayable > 0,
            "the amount payable is zero, please check that cart isn't empty or that your payment token is valid"
        );
        // @dev inherit the erc20 interface if u want; although u reduce codesize just using the function u want
        erc20 = IERC20(tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr);
        require(
            erc20.balanceOf(msg.sender) >= amountPayable,
            "insufficient balance of selected payment token, please topup"
        );
        _checkoutAmount[userData.userId] = 0; //clear checkoutamount
        // @dev use safetransferfrom, this will revert if not succesful(especially for weird erc20), since it does low-level call under the hood
        safeDepositToEscrow(erc20, msg.sender, escrowContract, amountPayable);

        (bool payResponse, uint payRef) = escrowInterface.payForItemsWithUsd(
            userData.userId,
            amountPayable,
            _paymentTokenSymbol,
            paymentRef
        );
        require(payResponse, "payment via USD failed, try again");
        emit SuccessfulCheckout(
            userData.userId,
            payRef,
            _paymentTokenSymbol,
            amountPayable
        );
        // @dev==> you have to modify states in escrow and/or ecomm for the user checkout
    }


    function _getTokenEquivalence(
        uint _totalBill,
        string memory _paymentToken
    ) private returns (uint256, bytes memory) {
        require(isAccepted[_paymentToken], "invalid token");
        require(
            tokenSymbolToDetails[_paymentToken].feedAddr != address(0),
            "invalid Token addr"
        );
        // ======for contract test sake---
        AggregatorV3Interface feed = AggregatorV3Interface(
            tokenSymbolToDetails[_paymentToken].feedAddr //priceFeed address
        );
        (
            ,
            /* uint80 roundId */ int256 tokenPrice /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = feed.latestRoundData();

        uint8 feedDecimals = feed.decimals();

        if (keccak256(bytes(_paymentToken)) == keccak256(bytes("ETH"))) {
            (uint256 _ethVal, bytes memory _callData) = Utils
                ._getEthEquivalence(
                    _totalBill,
                    feedDecimals,
                    USD_DECIMALS,
                    uint(tokenPrice)
                );
            return (_ethVal, _callData);
        } else {
            (uint256 _tokenVal, bytes memory _callData) = Utils
                ._getTokenEquivalence(
                    _totalBill,
                    _paymentToken,
                    tokenSymbolToDetails[_paymentToken].tokenAddr,
                    feedDecimals,
                    USD_DECIMALS,
                    uint(tokenPrice)
                );
            return (_tokenVal, _callData);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
