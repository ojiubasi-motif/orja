// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

/** 
 * ====deployed and verified on base on 9-2-2025========
 * User Manager Imp: 0xc54Cb991a832B40Cb7BCF20a32AE58fbCc0ae937
  product Impl: 0xE325Aadd3286013510e05aEdEFeE49Aae8bB3687
  Ecommerce Impl: 0xaC0db7a863492e28de0057A59cf5b8dd7A4F6849
  Escrow Impl: 0x160b819F97F9a00BF6A39e390A7D93D329211752
  User Manager proxy: 0xE4b7Ff08bDA75541620356d283eb10E3DB44EeDB
  product proxy: 0x1fa790Bf376013277B8Aa7506D330c417A1dc155
  Ecommerce Proxy: 0x09EB12CbCDa3E5ad65874bc54330782fa8d51DD9
  Escrow Proxy: 0x2163fee47139C909ad093e4E0eE22A119B5Df206
*/

import "./ERC20Base.sol";
import "./Common.sol";
import {IShop, IUser} from "@custom-interfaces/IEcomm.sol";
import {IEcomEscrow} from "@custom-interfaces/IEscrow.sol";
import "@chainlink/AggregatorV3Interface.sol";
import "forge-std/console.sol";

contract Escrow is Base, ERC20Base {
    mapping(string => bool) public isAccepted;
    mapping(string => Token) public tokenSymbolToDetails;
    string[] public acceptedTokens;

    bool isEcommAndUserManagerProxySet;
    address public ecommercePlatform;
    address public userContract;
    // @test uncomment next line later in live deployment
    AggregatorV3Interface priceFeed;

    // IERC20 erc20Interface;

    IShop ecommInterface;
    IUser userInterface;

    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
        private userBalance;
    mapping(uint256 _paymentRef => string _symbol) public paymentRefToToken;
    mapping(uint256 _paymentRef => uint256 _tokenPrice)
        public tokenPriceAtcheckout;

    mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance))
        private withdrawableBalance;
    mapping(uint256 _payref => mapping(uint256 _product => bool _cancel)) letBuyerCancel;
    mapping(uint256 _payref => OrderItem[] _order) trxToCart;

    constructor() {
        _disableInitializers();
        // owner = msg.sender;
        // pricefeed = AggregatorV3Interface(_feedAddr);//remove before deployment to production
    }

    function initialize(
        address _userContractAddress,
        address initialOwner
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        require(
            _userContractAddress != address(0),
            "Invalid usermanager contract addresses set"
        );

        userContract = _userContractAddress;
        userInterface = IUser(userContract);
    }

    function setEcommercePlatform(
        address _ecommercePlatform
    ) external onlyOwner {
        require(
            !isEcommAndUserManagerProxySet,
            "Ecommerce and user-manager contract addresses have already been set"
        );
        require(
            _ecommercePlatform != address(0),
            "Invalid ecommerce contract addresses set"
        );
        isEcommAndUserManagerProxySet = true; //permanently sets the ecommerce platform address

        ecommercePlatform = _ecommercePlatform;
        ecommInterface = IShop(ecommercePlatform);

        //    priceFeed = AggregatorV3Interface(ecommInterface.getFeed()); //@test uncomment next line later in live deployment
        // userContract = _userContract;
    }

    // token utility functions=========
    function addTokenToAcceptedList(
        address _tokenAddress,
        string memory _symbol,
        address _feedAddress
    ) external onlyOwner {
        require(!isAccepted[_symbol], "Token already listed");
        //  acceptedTokens.push(_symbol);
        if (keccak256(bytes(_symbol)) == keccak256(bytes("ETH"))) {
            require(_feedAddress != address(0), "feedAddres address(0)");
            address ethAddr = address(uint160(uint256(keccak256("ETH")))); //calculate address to use for eth
            isAccepted["ETH"] = true;
            tokenSymbolToDetails["ETH"] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: ethAddr
            });
        } else {
            require(_tokenAddress != address(0), "tokenAddress address(0)");
            require(_feedAddress != address(0), "feedAddres address(0)");
            isAccepted[_symbol] = true;
            tokenSymbolToDetails[_symbol] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: _tokenAddress
            });
        }

        acceptedTokens.push(_symbol);
    }

    function delistToken(string memory _symbol) external onlyOwner {
        require(isAccepted[_symbol], "invalid Token symbol");
        isAccepted[_symbol] = false;
    }

    function getAcceptedTokens() external view returns (string[] memory) {
        return acceptedTokens;
    }

    function checkTokenStatusAndDetails(
        string memory _symbol
    ) external view returns (bool, Token memory) {
        return (isAccepted[_symbol], tokenSymbolToDetails[_symbol]);
    }

    function getWithdrawableBalance(
        uint256 _userId,
        uint256 _ref
    )
        public
        view
        isAuthorizedCaller(
            userInterface.getUserData(msg.sender).userId,
            _userId,
            msg.sender
        )
        returns (uint256)
    {
        return withdrawableBalance[_userId][_ref];
    }

    function getWalletBalance(
        uint256 _userId,
        uint256 _payRef
    )
        public
        view
        isAuthorizedCaller(
            userInterface.getUserData(msg.sender).userId,
            _userId,
            msg.sender
        )
        returns (uint256)
    {
        return userBalance[_userId][_payRef];
    }

    function payForItemsWithETH(
        uint _userId,
        uint _bill,
        bytes memory _feedData,
        uint _payRef
    ) external payable returns (bool, uint) {
        require(
            msg.sender == ecommercePlatform,
            "only ecommerce contract can interract with this function"
        );
        require(msg.value > 0, "Payment must be greater than zero");

        (string memory _symbol, uint8 _decimal, int256 _tokenPrice) = abi
            .decode(_feedData, (string, uint8, int256));
        require(_tokenPrice > 0, "Invalid price fetched from feed");

        uint EthvalueInUsd = (msg.value * uint(_tokenPrice)) / 1e18; // Assuming pricefeed returns price in 8 decimals
        uint diff = EthvalueInUsd > _bill
            ? EthvalueInUsd - _bill
            : _bill - EthvalueInUsd;
        require(
            diff <= 10 ** (_decimal - 2), // 1e6(0.01USD) if decimal==8 etc...
            "too much difference between payment and calculated checkout amount, try again"
        );
        require(
            userBalance[_userId][_payRef] == 0,
            "Payment has already been made with this reference"
        );
        trxToCart[_payRef] = ecommInterface.getCart(_userId);
        // Logic to handle payment
        userBalance[_userId][_payRef] += msg.value;
        paymentRefToToken[_payRef] = _symbol;
        tokenPriceAtcheckout[_payRef] = uint(_tokenPrice);
        // For example, transfer funds to the seller
        console.log("user cart balance==>", userBalance[_userId][_payRef]);
        // and emit an event for the transaction
        return (true, _payRef);
    }

    function payForItemsWithUsd(
        uint _userId,
        uint bill,
        string memory _paymentTokenSymbol,
        uint _payRef
    ) external returns (bool, uint) {
        require(
            msg.sender == ecommercePlatform,
            "only ecommerce contract can interract with this function"
        );
        // require(msg.value > 0, "Payment must be greater than zero");
        // @test uncomment next line b4 live deploy
        // priceFeed = AggregatorV3Interface(
        //     tokenSymbolToDetails[_paymentTokenSymbol].feedAddr
        // );
        uint8 UsdDecimals = priceFeed.decimals();
        (
            ,
            /* uint80 roundId */ int256 tokenPrice /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        require(tokenPrice > 0, "Invalid price fetched from feed");

        uint256 allowedDiff = 10 ** (UsdDecimals - 3); //i.e 0.001 USDT, USDC, BUSD
        uint256 diff = UsdDecimals - uint256(tokenPrice); //ideally usd ==> decimals * 1, i.e 1usdt = $1
        require(
            diff <= allowedDiff,
            "sorry, onchain value of USD is too low at this time, please try again or use Eth to pay"
        );
        require(
            userBalance[_userId][_payRef] == 0,
            "Payment has already been made with this reference"
        );
        trxToCart[_payRef] = ecommInterface.getCart(_userId);
        // Logic to handle payment
        userBalance[_userId][_payRef] += bill;
        paymentRefToToken[_payRef] = _paymentTokenSymbol;
        // For example, transfer funds to the seller
        // and emit an event for the transaction
        return (true, _payRef);
    }

    /// @dev this function is only meant for the buyer
    function updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _isDelivered
    ) external {
        _updateDeliveryStatus(_payRef, _productId, _isDelivered);
    }

    /// @dev this function is only meant for the seller
    function sellerCancelDelivery(
        uint _payRef,
        uint _productId // uint256 _buyerId
    ) external {
        require(
            trxToCart[_payRef].length > 0,
            "payment reference is not valid"
        );
        User memory sellerData = userInterface.getUserData(msg.sender);
        for (uint i = 0; i < trxToCart[_payRef].length; i++) {
            if (trxToCart[_payRef][i].productId == _productId) {
                require(
                    trxToCart[_payRef][i].sellerId == sellerData.userId,
                    "only seller of product can order for cancellation"
                );
                require(
                    trxToCart[_payRef][i].orderStatus == OrderStatus.Processing,
                    "Order has already been processed"
                );
                letBuyerCancel[_payRef][trxToCart[_payRef][i].productId] = true;
                emit CanceledDelivery(sellerData.userId, _payRef, _productId);
                break;
            } else
                require(
                    i != trxToCart[_payRef].length - 1, //last item has been searched and product not found
                    "Product not found in cart"
                );
        }
    }

    function _trussFee(uint _amount) internal pure returns (uint) {
        return (_amount * 1000) - (_amount * 999); //0.1% fee
    }

    function _updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _isDelivered
    ) internal {
        // !!!! define a library for enums...
        User memory buyer = userInterface.getUserData(msg.sender);
        require(msg.sender == buyer.account, "unathorized caller");
        OrderItem[] memory allCartItems = ecommInterface.getCart(buyer.userId);

        // Logic to update delivery status
        for (uint i = 0; i < allCartItems.length; i++) {
            if (allCartItems[i].productId == _productId) {
                require(
                    allCartItems[i].sellerId != buyer.userId,
                    "malicious action detected, seller cannot confirm delivery of their own product"
                );
                require(
                    allCartItems[i].orderStatus == OrderStatus.Processing,
                    "Order already delivered or not in processing state"
                );
                // cartItem = allCartItems[i];

                uint256 _bal; // total amount for the item
                if (
                    keccak256(bytes(paymentRefToToken[_payRef])) ==
                    keccak256(bytes("ETH"))
                ) {
                    //if payment token is eth, convert value from usd to eth equivalence as at checkout
                    uint256 _costOfItem = uint256(allCartItems[i].unitPrice) *
                        allCartItems[i].qty;
                    _bal =
                        (_costOfItem * 1e18) /
                        uint256(tokenPriceAtcheckout[_payRef]);
                } else {
                    //if paytoken was a stablecoin, then no need to convert
                    _bal =
                        uint256(allCartItems[i].unitPrice) *
                        allCartItems[i].qty;
                }
                uint256 _balAfterFee = _bal - _trussFee(_bal);
                // execute the delivery confirmation logic
                if (_isDelivered) {
                    allCartItems[i].orderStatus = OrderStatus.Delivered;
                    userBalance[buyer.userId][_payRef] -= _bal; // deduct it from the buyer balance
                    // userBalance[allCartItems[i].sellerId][_payRef] += _bal; //add it to the seller balance

                    withdrawableBalance[allCartItems[i].sellerId][
                        _payRef
                    ] += _balAfterFee; // add it to the seller withdrawable balance
                } else {
                    require(
                        allCartItems[i]._proposedDeliveryTime + 60 seconds <
                            block.timestamp ||
                            letBuyerCancel[_payRef][_productId],
                        "please wait for delivery time to expire or contact seller to cancel order"
                    );
                    //seller could not deliver
                    allCartItems[i].orderStatus = OrderStatus.Canceled;
                    userBalance[buyer.userId][_payRef] -= _bal; //remove from balance of the buyer
                    withdrawableBalance[buyer.userId][_payRef] += _balAfterFee; //add to buyer withdrawable balance
                    // emit DeliveryPending(_userId, _payRef);
                }
                emit ProductOrderStatusUpdated(
                    buyer.userId,
                    _payRef,
                    _productId,
                    _isDelivered
                );
                break;
            } else
                require(
                    i != allCartItems.length - 1, //last item has been searched and product not found
                    "Product not found in cart"
                );
        }
        // @dev calculate the coin equivalence if payment token isn't a stable coin
    }

    function withdrawFunds(uint256 _payRef, uint256 _amount) external {
        User memory user = userInterface.getUserData(msg.sender);
        require(msg.sender == user.account, "not a registered user"); //@dig is this not tautology?
        uint256 withdrawable = withdrawableBalance[user.userId][_payRef];
        require(withdrawable >= _amount, "No funds available for withdrawal");
        // do proper accounting before withdrawal
        console.log(
            "withdrawing amount in escrow==>",
            withdrawable,
            "amount==>",
            _amount
        );
        withdrawableBalance[user.userId][_payRef] -= _amount;
        // userBalance[user.userId][_payRef] -= _amount;
        // @dev do not delete listed token data, you may only disable its usage with bool
        string memory _token = _checkWithdrawToken(_payRef);

        if (keccak256(bytes(_token)) == keccak256(bytes("ETH"))) {
            // @dev calculate the amount of eth to send...
            payable(msg.sender).transfer(_amount);
        } else {
            // token is other erc20 token
            erc20 = IERC20(tokenSymbolToDetails[_token].tokenAddr);
            safeWithdrawFromEscrow(erc20, msg.sender, _amount);
        }
        emit WithdrawSuccess(
            user.userId,
            _token,
            _payRef,
            _amount,
            block.timestamp
        );
    }

    function _checkWithdrawToken(
        uint256 _payRef
    ) private view returns (string memory) {
        string memory _token = paymentRefToToken[_payRef];
        return _token;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    event DeliveryConfirmed(uint indexed userId, uint indexed payRef);
    event DeliveryPending(uint indexed userId, uint indexed payRef);
    event PaymentReceived(
        uint indexed userId,
        uint indexed payRef,
        uint amount
    );

    modifier isCorrectFundsSent(
        uint _userId,
        uint _payRef,
        uint _amount
    ) {
        uint escrowBalBefore = address(this).balance;
        uint userBalBefore = userBalance[_userId][_payRef]; // Assuming 0 is the payment reference for the user
        _;
        uint escrowBalAfter = address(this).balance;
        uint userBalAfter = userBalance[_userId][_payRef];

        require(
            userBalAfter - userBalBefore == _amount,
            "Incorrect funds sent to escrow"
        );
    }

    modifier isAuthorizedCaller(
        uint256 _callerId,
        uint256 _userId,
        address _account
    ) {
        require(
            _callerId == _userId ||
                _account == ecommercePlatform ||
                _account == address(this),
            "unauthorized caller not allowed"
        );
        _;
    }

    receive() external payable {}
}
