// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import "@custom-interfaces/IEscrow.sol";
import "@src/Common.sol";
// import {OrderItem} from  "@src/Common.sol";
import "@src/ERC20Base.sol";
import "@chainlink/AggregatorV3Interface.sol";
import {IUser, IShop, IProduct} from "@src/interfaces/IEcomm.sol";
import {Utils, ProductsUtils} from "@src/truss-lib/Utils.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";

// import "forge-std/console.sol";

contract Ecommerce is IShop, Base, ERC20Base {
    IEcomEscrow escrowInterface;
    IUser userInterface;
    IProduct productInterface;

    bytes32 private constant ECOMM_STORAGE_SLOT = keccak256("erc7575.ecomm.storage");


    uint constant USD_PRECISION = 1e8; //
    uint8 constant USD_DECIMALS = 8;

    struct EcommStorage {
        address payable escrowContract;
        address userContract;
        address productContract;
        mapping(uint256 _payRef => mapping(string _token => uint256 _checkoutRate)) checkoutTokenRate;
        mapping(uint256 _paymentReference => uint256 _amount) _checkoutAmount;
        mapping(uint256 _buyerId => mapping(uint256 _payRef => OrderItem[] _products)) order;
        uint256 _refCounter;
    }

    // address payable escrowContract;
    // address userContract;
    // address productContract;

    // uint constant USD_PRECISION = 1e8; //
    // uint8 constant USD_DECIMALS = 8;

    // mapping(uint256 _payRef => mapping(string _token => uint256 _checkoutRate)) checkoutTokenRate;
    // TokenDetails[] acceptedTokens;
    // mapping(uint256 _payRef => mapping(string _token => uint256 _checkoutRate)) checkoutTokenRate;

    //for easy fetching of user record from users array

    // mapping(uint256 _paymentReference => uint256 _amount)
    //     private _checkoutAmount;
    

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    // function initializev2(
    //     address _escrowAddress,
    //     address _userContract,
    //     address _productContract,
    //     address initialOwner
    //     address _feedAddr // @test uncomment next line later in live deployment
    // )
    //     external
    //     // address _feedAddr //  address _adminDaoAddress
    //     reinitializer(2)
    //     // override
    // {
    //     __Ownable_init(initialOwner);
    //     __UUPSUpgradeable_init();
    //     require(_escrowAddress != address(0), "Invalid ESCROW address");
    //     require(_userContract != address(0), "Invalid user contract address");
    //     require(
    //         _productContract != address(0),
    //         "Invalid product contract address"
    //     );

    //     escrowContract = payable(_escrowAddress);
    //     userContract = _userContract;
    //     productContract = _productContract;
    //     // @test======remove later local---
    //     // priceFeed = AggregatorV3Interface(_feedAddr);
    //     escrowInterface = IEcomEscrow(address(escrowContract));
    //     userInterface = IUser(address(userContract));
    //     productInterface = IProduct(address(productContract));
    //     // adminDAOcontract = _adminDaoAddress;
    // }
    // @dep --remove dis fnc
    function _getEcommStorage() private pure returns(EcommStorage storage $) {
         bytes32 slot = ECOMM_STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }

    function initializev2(
        address _escrowAddress,
        address _userContract,
        address _productContract,
        address initialOwner
    )
        external
        reinitializer(4)

        // initializer
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        require(_escrowAddress != address(0), "Invalid ESCROW address");
        require(_userContract != address(0), "Invalid user contract address");
        require(
            _productContract != address(0),
            "Invalid product contract address"
        );

        EcommStorage storage $ = _getEcommStorage();

        $.escrowContract = payable(_escrowAddress);
        $.userContract = _userContract;
        $.productContract = _productContract;
        // @test======remove later local---
        // priceFeed = AggregatorV3Interface(_feedAddr);
        escrowInterface = IEcomEscrow(address($.escrowContract));
        userInterface = IUser(address($.userContract));
        productInterface = IProduct(address($.productContract));
        // adminDAOcontract = _adminDaoAddress;
    }

    //    ====getters for private variables============
    // function userCheckoutAmount(uint256 _payRef) public view returns (uint256) {
    //     return _checkoutAmount[_payRef];
    // }

    //  ======public functions============

    function getOrder(
        uint256 _userId,
        uint256 _payRef
    )
        external
        view
        override
        returns (
            // onlyAuthorizedBuyerOrEscrow(
            //     userInterface.getUserData(msg.sender).account,
            //     escrowContract
            // )
            OrderItem[] memory
        )
    {
        EcommStorage storage $ = _getEcommStorage();
        // User memory userData = userInterface.getUserData(_account);
        OrderItem[] memory cartItems = $.order[_userId][_payRef];
        require(cartItems.length > 0, "Order is empty");
        return cartItems;
    }

    // @test remove later
    // function getFeed() external view override returns (address) {
    //     return address(priceFeed);
    // }

    // @dig try to use encoded data and private function to update multiple product details once

    function addProductToCart(
        uint256 _productId,
        uint32 _qty
    )
        private
        view
        returns (
            // override
            // address _account
            // onlyAuthorizedBuyerOrEscrow(
            //     userInterface.getUserData(msg.sender).account,
            //     escrowContract
            // )
            OrderItem memory
        )
    {
        Product memory product = productInterface.getProductData(_productId);
        // require(product.sellerId != 0, "product seller not valid");
        if (product.sellerId != 0) {
            return
                OrderItem({
                    sellerId: product.sellerId,
                    productId: product.productId,
                    qty: _qty,
                    unitPrice: product.unitPrice,
                    orderStatus: OrderStatus.Processing,
                    _proposedDeliveryTime: product.whenToExpectDelivery // in miliseconds
                });
        }

        //    return item;
        // calculateUserBill(user.userId); // calculate the total bill for the user
        // userToproductQtyInCart[user.userId][product.productId] = _qty;
    }

    function previewCheckoutBill(
        OrderItem[] memory _order
    ) public pure returns (uint256) {
        // Product memory productData;
        uint256 cumm = 0;
        for (uint256 i = 0; i < _order.length; ++i) {
            if (_order[i].sellerId == 0) {
                continue; // skip if product seller is not valid
            }
            (bool _resp, uint256 _cost) = Math.tryMul(
                _order[i].unitPrice,
                _order[i].qty
            );
            require(
                _resp,
                "overflow calculating product cost, reduce the qty of some items"
            );
            // int8 quantity = userToproductQtyInCart[userData.userId][productId];
            (bool _cummRes, uint256 answr) = Math.tryAdd(cumm, _cost);
            require(_cummRes, "overflow calculating aggregated cost");
            cumm = answr;
        }
        return cumm;
    }

    // @dig is there a need to add-to-cart when checkout isn't assured? make it private
    // @dig zk tech could be used to augment this process too.
    function calculateUserBill(
        uint256 _userId,
        uint256 _payRef
    ) private returns (uint256) {
        EcommStorage storage $ = _getEcommStorage();
        OrderItem[] memory cartItems = $.order[_userId][_payRef];
        require(cartItems.length > 0, "Cart is empty for this user");
        uint256 cumm = previewCheckoutBill(cartItems);
        $._checkoutAmount[_userId] = cumm;

        return $._checkoutAmount[_userId];
    }

    function checkOutWithETH(
        // address _account,
        OrderSpec[] memory _order
    )
        external
        payable
        // string memory _payToken
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            _getEcommStorage().escrowContract
        )
        returns (bool _resp, uint _payref)
    {
        (_resp, _payref) = _checkOutWithETH(_order, msg.sender);
    }

    function previewCheckoutAmount(
        uint256 _total,
        string memory _paymentToken
    ) public returns (uint256) {
        (uint256 _tokenVal, bytes memory _data) = _getTokenEquivalence(
            _total,
            _paymentToken
        );
        return _tokenVal;
    }

    function checkOutWithERC20(
        // address msg.sender,
        OrderSpec[] memory _order,
        string memory _payToken
    )
        public
        onlyAuthorizedBuyerOrEscrow(
            userInterface.getUserData(msg.sender).account,
            _getEcommStorage().escrowContract
        )
    {
        _checkOutWithERC20(_order, msg.sender, _payToken);
    }

    // ======private and internal fns=============

    function _generatePaymentRefence(
        address _account
    ) private returns (uint64 ref) {
        // @dig find a better way to generate random value
        EcommStorage storage $ = _getEcommStorage();
        $._refCounter++;
        ref = uint64(
            uint256(
                keccak256(
                    abi.encodePacked(
                        $._refCounter,
                        block.prevrandao,
                        blockhash(block.number - 1),
                        _account,
                        block.timestamp,
                        gasleft()
                    )
                )
            )
        );
        // ref = uint64(
        //     uint256(
        //         keccak256(
        //             abi.encodePacked(
        //                 _account,
        //                 block.timestamp,
        //                 userInterface.getUserData(_account).userId
        //                 // userInterface.users[userInterface.userIdToRecordIndex[_account]].userId
        //             )
        //         )
        //     )
        // );
    }

    function _checkOutWithETH(
        OrderSpec[] memory _order,
        address _account
    )
        private
        returns (
            // string memory _paymentTokenSymbol
            bool,
            uint
        )
    {
        EcommStorage storage $ = _getEcommStorage();
        User memory userData = userInterface.getUserData(_account);
        require(userData.account != address(0), "user account not found");
        // require(!isCartProcessed[userData.userId], "Cart already processed");
        // isCartProcessed[userData.userId] = true; // mark the cart as processed

        uint256 paymentRef = _generatePaymentRefence(_account);

        for (uint i = 0; i < _order.length; i++) {
            if (!productInterface.isProductListed(_order[i].prodId)) {
                continue; // skip if product is not listed; prevents reverts in addProductToCart()
            }
            OrderItem memory _orderItem = addProductToCart(
                _order[i].prodId,
                _order[i].qty
            );
            $.order[userData.userId][paymentRef].push(_orderItem);
        }
        uint256 amountPayable = calculateUserBill(userData.userId, paymentRef);
        // order[userData.userId][paymentRef] = cart[userData.userId];
        // delete cart[userData.userId]; // clear the cart
        // _checkoutAmount[paymentRef] = amountPayable;
        // if (keccak256(bytes(_paymentTokenSymbol)) == keccak256(bytes("ETH"))) {
        (uint expectedEthValue, bytes memory feedData) = _getTokenEquivalence(
            amountPayable,
            "ETH"
        );

        require(msg.value >= expectedEthValue, "insufficient amount of ETH");

        $._checkoutAmount[userData.userId] = 0;
        // amountPayable = 0; // reset the amount payable after checkout
        // console.log("expectedEthValue==>", expectedEthValue);
        (bool payResponse, uint payRef) = escrowInterface.payForItemsWithETH{
            value: expectedEthValue
        }(userData.userId, amountPayable, feedData, paymentRef);
        // _checkoutAmount[paymentRef] = 0; // store the amount payable for this payment reference
        require(payResponse, "payment via ETH failed, try again later");
        emit SuccessfulCheckout(
            userData.userId,
            payRef,
            "ETH",
            expectedEthValue
        );
        return (true, payRef);
    }

    function _checkOutWithERC20(
        OrderSpec[] memory _order,
        address _account,
        string memory _paymentTokenSymbol
    ) private {
        User memory userData = userInterface.getUserData(_account);
        require(userData.account != address(0), "user account not found");
        // require(!isCartProcessed[userData.userId], "Cart already processed");
        // isCartProcessed[userData.userId] = true; // mark the cart as processed

        uint256 paymentRef = _generatePaymentRefence(_account);
        EcommStorage storage $ = _getEcommStorage();

        for (uint i = 0; i < _order.length; i++) {
            OrderItem memory _orderItem = addProductToCart(
                _order[i].prodId,
                _order[i].qty
            );
            $.order[userData.userId][paymentRef].push(_orderItem);
        }
        uint256 amountPayableInUSD = calculateUserBill(
            userData.userId,
            paymentRef
        );

        require(
            escrowInterface.isAccepted(_paymentTokenSymbol),
            "invalid token"
        );
        require(
            escrowInterface
                .tokenSymbolToDetails(_paymentTokenSymbol)
                .feedAddr !=
                address(0) &&
                escrowInterface
                    .tokenSymbolToDetails(_paymentTokenSymbol)
                    .tokenAddr !=
                address(0),
            "please specify a valid token for payment"
        );

        require(
            amountPayableInUSD > 0,
            "the amount payable is zero, please check that cart isn't empty or that your payment token is valid"
        );
        // @dev inherit the erc20 interface if u want; although u reduce codesize just using the function u want
        erc20 = IERC20(
            escrowInterface.tokenSymbolToDetails(_paymentTokenSymbol).tokenAddr
        );
        (uint expectedTokenValue, bytes memory feedData) = _getTokenEquivalence(
            amountPayableInUSD,
            _paymentTokenSymbol
        );
        require(
            erc20.balanceOf(msg.sender) >= expectedTokenValue,
            "insufficient balance of selected payment token, please topup"
        );

        // require(
        //     msg.value >= expectedUSDValue,
        //     "insufficient amount of ETH"
        // );
        $._checkoutAmount[userData.userId] = 0; //clear checkoutamount
        // @dev use safetransferfrom, this will revert if not succesful(especially for weird erc20), since it does low-level call under the hood
        require(
            $.escrowContract != address(0),
            "invalid escrow contract address"
        );
        bool _resp = safeDepositToEscrow(
            erc20,
            msg.sender,
            $.escrowContract,
            expectedTokenValue
        );
        require(_resp, "token transfer to escrow failed, try again");

        (bool payResponse, uint payRef) = escrowInterface.payForItemsWithERC20(
            userData.userId,
            amountPayableInUSD,
            expectedTokenValue,
            _paymentTokenSymbol,
            paymentRef,
            feedData
        );
        require(payResponse, "payment via erc20 token failed, try again");
        emit SuccessfulCheckout(
            userData.userId,
            payRef,
            _paymentTokenSymbol,
            expectedTokenValue
        );
        // @dev==> you have to modify states in escrow and/or ecomm for the user checkout
    }

    function getTokenEquivalence(
        uint _totalBill,
        string memory _paymentToken
    ) public returns (uint256, bytes memory) {
        (uint256 _tokenVal, bytes memory _callData) = _getTokenEquivalence(
            _totalBill,
            _paymentToken
        );
        return (_tokenVal, _callData);
    }

    function _getTokenEquivalence(
        uint _totalBill,
        string memory _paymentToken
    ) private returns (uint256, bytes memory) {
        // console.log("payment token==>", _paymentToken);
        // console.log(
        //     "is eth accepted?",
        //     escrowInterface.isAccepted(_paymentToken)
        // );
        require(
            escrowInterface.isAccepted(_paymentToken),
            "token not accepted for payment"
        );
        require(
            escrowInterface.tokenSymbolToDetails(_paymentToken).feedAddr !=
                address(0),
            "invalid Token addr"
        );
        // @test======for contract test on foundry local---comment next line

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            escrowInterface.tokenSymbolToDetails(_paymentToken).feedAddr //priceFeed address
        );
        (
            ,
            /* uint80 roundId */ int256 tokenPrice /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();

        uint8 feedDecimals = priceFeed.decimals();
        require(tokenPrice > 0, "invalid token price from price feed");

        if (keccak256(bytes(_paymentToken)) == keccak256(bytes("ETH"))) {
            (uint256 _ethVal, bytes memory _callData) = Utils
                .getEthEquivalence(
                    _totalBill,
                    feedDecimals,
                    USD_DECIMALS,
                    uint(tokenPrice)
                );
            return (_ethVal, _callData);
        } else {
            (uint256 _tokenVal, bytes memory _callData) = Utils
                .getTokenEquivalence(
                    _totalBill,
                    _paymentToken,
                    escrowInterface
                        .tokenSymbolToDetails(_paymentToken)
                        .tokenAddr,
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
