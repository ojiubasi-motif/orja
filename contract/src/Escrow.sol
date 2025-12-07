// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@src/ERC20Base.sol";
import "@src/Common.sol";
import {IShop, IUser} from "@custom-interfaces/IEcomm.sol";
import {IEcomEscrow} from "@custom-interfaces/IEscrow.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@chainlink/AggregatorV3Interface.sol";
import "forge-std/console.sol";
import {Utils} from "@src/truss-lib/Utils.sol";

/** 
 * ====deployed and verified on base on 9-2-2025========
 * User Manager Imp: 0xc54Cb991a832B40Cb7BCF20a32AE58fbCc0ae937
  product Impl: 0xE325Aadd3286013510e05aEdEFeE49Aae8bB3687
  Ecommerce Impl: 0xaC0db7a863492e28de0057A59cf5b8dd7A4F6849
  Escrow Impl: 0x160b819F97F9a00BF6A39e390A7D93D329211752
  ++++++++++++++++++++++ proxies ++++++++++++++++++++++++
  User Manager proxy: 0xE4b7Ff08bDA75541620356d283eb10E3DB44EeDB
  product proxy: 0x1fa790Bf376013277B8Aa7506D330c417A1dc155
  Ecommerce Proxy: 0x09EB12CbCDa3E5ad65874bc54330782fa8d51DD9
  Escrow Proxy: 0x2163fee47139C909ad093e4E0eE22A119B5Df206
  ===================v2 implementation=====================
  User Manager Imp: 0x30440C5aF95d28F5c4E03186228a6328Fb8a3c09
  product Impl: 0x67498A61A5aDF49B2EfE41f23Aec9EbfAA85776c
  Ecommerce Impl: 0x8F01EcE5027fF19c18C7bafB843A7e89a60f079B
  Escrow Impl: 0x86912C9Bc3F9569b14873BABe65DA20f6B1A9e61
  ===================v4 implementations ===================
  User Manager Imp: 0x96B2BE7E046De733b0BeE99B06425d731f75e466
  product Impl: 0xBa91fC4c7ED73E314A305b17996b479b160580F1
  Ecommerce Impl: 0x210D29a612Ee63283A3e20D06bF49eb735444765
  Escrow Impl: 0xA3b6e4FE5F083CBef97B046B3Eb5A502763FC108
  
*/

import "@src/v1/Escrow.sol";

contract Escrow is Base, ERC20Base {
    IShop ecommInterface;
    IUser userInterface;
    bytes32 private constant ESCROW_STORAGE_SLOT =
        keccak256("erc7575.escrow.storage");

    struct EscrowStorage {
        bool isEcommAndUserManagerProxySet;
        address ecommercePlatform;
        address userContract;
        mapping(string => bool) isAccepted;
        mapping(string => Token) tokenSymbolToDetails;
        string[] acceptedTokens;
        mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance)) userBalance;
        mapping(uint256 _paymentRef => string _symbol) paymentRefToToken;
        mapping(uint256 _paymentRef => uint256 _tokenPrice) tokenPriceAtcheckout;
        mapping(uint256 _userId => mapping(uint256 _paymentRef => uint256 _balance)) withdrawableBalance;
        mapping(uint256 _payref => mapping(uint256 _product => bool _cancel)) letBuyerCancel;
        mapping(uint256 _payref => OrderItem[] _order) trxToCart;
    }

    constructor() {
        _disableInitializers();
    }

    function _getEscrowStorage()
        private
        pure
        returns (EscrowStorage storage $)
    {
        bytes32 slot = ESCROW_STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }

    // @dep uncomment next fnc
    function initializev2(
        address _userContractAddress,
        address initialOwner
    )
        external
        // initializer
        reinitializer(4)
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        require(
            _userContractAddress != address(0),
            "Invalid usermanager contract addresses set"
        );
        EscrowStorage storage $ = _getEscrowStorage();
        $.userContract = _userContractAddress;
        userInterface = IUser($.userContract);
    }

    // function initialize(
    //     address _escrowAddress,
    //     address _userContract,
    //     address _productContract,
    //     address initialOwner,
    //     address _feedAddr // @test uncomment next line later in live deployment
    // )
    //     external
    //     // address _feedAddr //  address _adminDaoAddress
    //     initializer
    // {
    //     __Ownable_init(initialOwner);
    //     __UUPSUpgradeable_init();
    //     require(_escrowAddress != address(0), "Invalid ESCROW address");
    //     require(_userContract != address(0), "Invalid user contract address");
    //     require(_productContract!= address(0), "Invalid product contract address");

    //     escrowContract = payable(_escrowAddress);
    //     userContract = _userContract;
    //     productContract = _productContract;
    //     // @test======remove later local---
    //     priceFeed = AggregatorV3Interface(_feedAddr);
    //     escrowInterface = IEcomEscrow(address(escrowContract));
    //     userInterface = IUser(address(userContract));
    //     productInterface = IProduct(address(productContract));
    //     // adminDAOcontract = _adminDaoAddress;
    // }
    function setEcommercePlatform(
        address _ecommercePlatform
    ) external onlyOwner {
        EscrowStorage storage $ = _getEscrowStorage();
        require(
            !$.isEcommAndUserManagerProxySet,
            "Ecommerce and user-manager contract addresses have already been set"
        );
        require(
            _ecommercePlatform != address(0),
            "Invalid ecommerce contract addresses set"
        );

        $.isEcommAndUserManagerProxySet = true; //permanently sets the ecommerce platform address

        $.ecommercePlatform = _ecommercePlatform;
        ecommInterface = IShop($.ecommercePlatform);

        // priceFeed = AggregatorV3Interface(ecommInterface.getFeed()); //@test comment this line later in live deployment
        // userContract = _userContract;
    }

    // token utility functions=========
    function addTokenToAcceptedList(
        address _feedAddress,
        string memory _symbol,
        address _tokenAddress
    ) external onlyOwner {
        EscrowStorage storage $ = _getEscrowStorage();
        require(!$.isAccepted[_symbol], "Token already listed");
        //  acceptedTokens.push(_symbol);
        if (keccak256(bytes(_symbol)) == keccak256(bytes("ETH"))) {
            require(_feedAddress != address(0), "feedAddres address(0)");
            address ethAddr = address(uint160(uint256(keccak256("ETH")))); //calculate address to use for eth
            $.isAccepted["ETH"] = true;
            $.tokenSymbolToDetails["ETH"] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: ethAddr
            });
        } else {
            require(_tokenAddress != address(0), "tokenAddress address(0)");
            require(_feedAddress != address(0), "feedAddres address(0)");
            $.isAccepted[_symbol] = true;
            $.tokenSymbolToDetails[_symbol] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: _tokenAddress
            });
        }

        $.acceptedTokens.push(_symbol);
    }

    function delistToken(string memory _symbol) external onlyOwner {
        EscrowStorage storage $ = _getEscrowStorage();

        require($.isAccepted[_symbol], "invalid Token symbol");
        $.isAccepted[_symbol] = false;
    }

    function getAcceptedTokens() external view returns (string[] memory) {
        EscrowStorage storage $ = _getEscrowStorage();
        return $.acceptedTokens;
    }

    function checkTokenStatusAndDetails(
        string memory _symbol
    ) external view returns (bool, Token memory) {
        EscrowStorage storage $ = _getEscrowStorage();
        return ($.isAccepted[_symbol], $.tokenSymbolToDetails[_symbol]);
    }

    function getWithdrawableBalance(
        uint256 _userId,
        uint256 _ref
    ) public view isAuthorizedCaller(_userId, msg.sender) returns (uint256) {
        // uint256 fetchedUserId = userInterface.getUserData(msg.sender).userId;
        EscrowStorage storage $ = _getEscrowStorage();
        return $.withdrawableBalance[_userId][_ref];
    }

    function fetchUserId(address _account) internal view returns (uint256) {
        return userInterface.getUserData(msg.sender).userId;
    }

    function getWalletBalance(
        uint256 _userId,
        uint256 _payRef
    )
        public
        view
        isAuthorizedCaller(
            // userInterface.getUserData(msg.sender).userId,
            _userId,
            msg.sender
        )
        returns (uint256)
    {
        EscrowStorage storage $ = _getEscrowStorage();
        return $.userBalance[_userId][_payRef];
    }

    function payForItemsWithETH(
        uint _userId,
        uint _bill,
        bytes memory _feedData,
        uint _payRef
    ) external payable returns (bool, uint) {
        EscrowStorage storage $ = _getEscrowStorage();
        require(
            msg.sender == $.ecommercePlatform,
            "only ecommerce contract can interract with this function"
        );
        require(msg.value > 0, "Payment must be greater than zero");

        (string memory _symbol, int256 _tokenPrice) = Utils.confirmValueSent(_bill,msg.value,_feedData);
        // uint diff = EthvalueInUsd >= _bill
        //     ? EthvalueInUsd - _bill
        //     : _bill - EthvalueInUsd;
        // require(
        //     diff <= 10 ** (_decimal - 2), // 1e6(0.01USD) if decimal==8 etc...
        //     "too much difference between payment and calculated checkout amount, try again"
        // );
        require(
            $.userBalance[_userId][_payRef] == 0,
            "Payment has already been made with this reference"
        );
        $.trxToCart[_payRef] = ecommInterface.getOrder(_userId, _payRef);
        // Logic to handle payment
        $.userBalance[_userId][_payRef] += msg.value;
        $.paymentRefToToken[_payRef] = _symbol;
        $.tokenPriceAtcheckout[_payRef] = uint(_tokenPrice);
        // For example, transfer funds to the seller
        console.log("user cart balance==>", $.userBalance[_userId][_payRef]);
        // and emit an event for the transaction
        return (true, _payRef);
    }

    function payForItemsWithERC20(
        uint _userId,
        uint _checkoutAmount,
        uint _tokenAmountSent,
        string memory _paymentTokenSymbol,
        uint _payRef,
        bytes memory _feedData
    ) external returns (bool, uint) {
        EscrowStorage storage $ = _getEscrowStorage();
        require(
            msg.sender == $.ecommercePlatform,
            "only ecommerce contract can interract with this function"
        );

        (
            string memory _symbol,
            uint8 _decimal,
            int256 _tokenPrice,
            address _tokenAddr
        ) = abi.decode(_feedData, (string, uint8, int256, address));
        require(_tokenPrice > 0, "Invalid price fetched from feed");
        require(
            $.tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr == _tokenAddr,
            "mismatched token symbol and address"
        );
        erc20 = IERC20($.tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr);
        require(erc20.decimals() > 0, "Invalid token decimals");
        (bool success, uint256 _tokenVal) = Math.tryMul(
            _tokenAmountSent,
            uint(_tokenPrice)
        );
        require(
            success,
            "escrow overflow calculating token value sent in feedprice"
        );
        uint tokenValueInUsd = Math.ceilDiv(_tokenVal, 10 ** erc20.decimals()); // Assuming pricefeed returns price in 8 decimals
        require(
            tokenValueInUsd >= _checkoutAmount,
            "Insufficient token sent for payment"
        );
        // uint diff = tokenValueInUsd >= _checkoutAmount
        //     ? tokenValueInUsd - _checkoutAmount
        //     : _checkoutAmount - tokenValueInUsd;
        // uint256 allowedDiff = 10 ** (_decimal - 3); //i.e 0.001 for stablecoins like USDT, USDC, BUSD
        // uint256 diff = _decimal - uint256(_tokenPrice); //ideally usd ==> decimals * 1, i.e 1usdt = $1
        // require(
        //     diff <= 10 ** (_decimal - 3),//i.e 0.001 for stablecoins like USDT, USDC, BUSD
        //     "sorry, onchain value of USD is too low at this time, please try again or use Eth to pay"
        // );
        require(
            $.userBalance[_userId][_payRef] == 0,
            "Payment has already been made with this reference"
        );
        $.trxToCart[_payRef] = ecommInterface.getOrder(_userId, _payRef);
        // Logic to handle payment
        $.userBalance[_userId][_payRef] += _tokenAmountSent;
        $.paymentRefToToken[_payRef] = _paymentTokenSymbol;
        $.tokenPriceAtcheckout[_payRef] = uint(_tokenPrice);
        // For example, transfer funds to the seller
        // and emit an event for the transaction
        return (true, _payRef);
    }

    /// @dev this function is only meant for the buyer
    function updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        uint _qty,
        bool _isDelivered
    ) external {
        _updateDeliveryStatus(_payRef, _productId, _qty, _isDelivered);
    }

    /// @dev this function is only meant for the seller
    function sellerCancelDelivery(
        uint _payRef,
        uint _productId // uint256 _buyerId
    ) external {
        EscrowStorage storage $ = _getEscrowStorage();
        require(
            $.trxToCart[_payRef].length > 0,
            "payment reference is not valid"
        );
        User memory sellerData = userInterface.getUserData(msg.sender);
        for (uint i = 0; i < $.trxToCart[_payRef].length; i++) {
            if ($.trxToCart[_payRef][i].productId == _productId) {
                require(
                    $.trxToCart[_payRef][i].sellerId == sellerData.userId,
                    "only seller of product can order for cancellation"
                );
                require(
                    $.trxToCart[_payRef][i].orderStatus ==
                        OrderStatus.Processing,
                    "Order has already been processed"
                );
                $.letBuyerCancel[_payRef][
                    $.trxToCart[_payRef][i].productId
                ] = true;
                emit CanceledDelivery(sellerData.userId, _payRef, _productId);
                break;
            } else
                require(
                    i != $.trxToCart[_payRef].length - 1, //last item has been searched and product not found
                    "Product not found in cart"
                );
        }
    }

    function _trussFee(uint _amount) internal pure returns (uint) {
        uint256 bps = 0.01e18; //1%
        (bool _resp, uint answr) = Math.tryMul(_amount, bps);
        require(_resp && answr > 0, "overflow calculating with bps");
        return Math.ceilDiv(answr, 1e18); //1% fee
    }

    function _updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        uint _qty,
        bool _isDelivered
    ) internal {
        // !!!! define a library for enums...
        User memory buyer = userInterface.getUserData(msg.sender);
        require(msg.sender == buyer.account, "unathorized caller");
        OrderItem[] memory allCartItems = ecommInterface.getOrder(
            buyer.userId,
            _payRef
        );
        require(allCartItems.length > 0, "no order found for this");
        EscrowStorage storage $ = _getEscrowStorage();

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
                if (!_isDelivered) {
                    require(
                        allCartItems[i]._proposedDeliveryTime + 60 seconds <
                            block.timestamp ||
                            $.letBuyerCancel[_payRef][_productId],
                        "please wait for delivery time to expire or contact seller to cancel order"
                    );
                }
                // cartItem = allCartItems[i];
                (bool success, uint _costOfItem) = Math.tryMul(
                    uint256(allCartItems[i].unitPrice),
                    _qty
                );
                require(success, "overflow calculating cost of delivered item");
                uint256 _scaledCostOfItem;
                uint256 _bal; // total amount for the item

                if (
                    keccak256(bytes($.paymentRefToToken[_payRef])) ==
                    keccak256(bytes("ETH"))
                ) {
                    (bool _resp, uint _scaled) = Math.tryMul(_costOfItem, 1e18);
                    require(_resp, "overflow scaling cost of delivered item");
                    _scaledCostOfItem = _scaled;
                } else {
                    erc20 = IERC20(
                        $
                            .tokenSymbolToDetails[$.paymentRefToToken[_payRef]]
                            .tokenAddr
                    );
                    uint8 tokenDecimals = erc20.decimals();
                    require(tokenDecimals > 0, "Invalid token decimals");
                    uint256 precision = 10 ** tokenDecimals;
                    (bool _resp, uint _scaled) = Math.tryMul(
                        _costOfItem,
                        precision
                    );
                    require(_resp, "overflow scaling cost of delivered item");
                    _scaledCostOfItem = _scaled;
                }
                require(
                    _scaledCostOfItem > 0,
                    "Invalid cost of delivered item"
                );
                _bal = Math.ceilDiv(
                    _scaledCostOfItem,
                    uint256($.tokenPriceAtcheckout[_payRef])
                );
                uint256 _fee = _trussFee(_bal);
                // uint256 _balAfterFee = _bal - _fee;
                (bool _subResp, uint256 _balAfterFee) = Math.trySub(_bal, _fee);
                require(_subResp, "overflow trying to subtract");
                // execute the delivery confirmation logic
                if (_isDelivered) {
                    allCartItems[i].orderStatus = OrderStatus.Delivered;
                    $.userBalance[buyer.userId][_payRef] -= _bal; // deduct it from the buyer balance
                    // userBalance[allCartItems[i].sellerId][_payRef] += _bal; //add it to the seller balance

                    $.withdrawableBalance[allCartItems[i].sellerId][
                            _payRef
                        ] += _balAfterFee; // add _balAfterFee to the seller withdrawable balance after deducting truss fee
                } else {
                    //seller could not deliver
                    allCartItems[i].orderStatus = OrderStatus.Canceled;
                    // console.log("user bal before update",userBalance[buyer.userId][_payRef]);
                    // console.log("withdrawable bal after update",_bal);
                    $.userBalance[buyer.userId][_payRef] -= _bal; //remove from balance of the buyer
                    $.withdrawableBalance[buyer.userId][_payRef] += _bal; //add _bal(not _balAfterFee) to buyer withdrawable balance since sale was not a success
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
                    "Product not found in order"
                );
        }
        // @dev calculate the coin equivalence if payment token isn't a stable coin
    }

    function withdrawFunds(uint256 _payRef, uint256 _amount) external {
        User memory user = userInterface.getUserData(msg.sender);
        require(msg.sender == user.account, "not a registered user"); //@dig is this not tautology?
        EscrowStorage storage $ = _getEscrowStorage();
        uint256 withdrawable = $.withdrawableBalance[user.userId][_payRef];
        require(withdrawable >= _amount, "No funds available for withdrawal");
        // do proper accounting before withdrawal
        // console.log(
        //     "withdrawing amount in escrow==>",
        //     withdrawable,
        //     "amount==>",
        //     _amount
        // );
        $.withdrawableBalance[user.userId][_payRef] -= _amount;
        // userBalance[user.userId][_payRef] -= _amount;
        // @dev do not delete listed token data, you may only disable its usage with bool
        string memory _token = _checkWithdrawToken(_payRef);

        if (keccak256(bytes(_token)) == keccak256(bytes("ETH"))) {
            // @dev calculate the amount of eth to send...
            // payable(msg.sender).transfer(_amount);
            (bool ok, ) = payable(msg.sender).call{value: _amount}("");
            require(ok, "ETH transfer failed");
        } else {
            // token is other erc20 token
            erc20 = IERC20($.tokenSymbolToDetails[_token].tokenAddr);
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
        EscrowStorage storage $ = _getEscrowStorage();
        string memory _token = $.paymentRefToToken[_payRef];
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
        EscrowStorage storage $ = _getEscrowStorage();
        uint userBalBefore = $.userBalance[_userId][_payRef]; // Assuming 0 is the payment reference for the user
        _;
        uint escrowBalAfter = address(this).balance;
        uint userBalAfter = $.userBalance[_userId][_payRef];

        require(
            userBalAfter - userBalBefore == _amount,
            "Incorrect funds sent to escrow"
        );
    }

    modifier isAuthorizedCaller(
        // uint256 _callerId,
        uint256 _userId,
        address _account
    ) {
        uint fetchedId = fetchUserId(_account);
        EscrowStorage storage $ = _getEscrowStorage();
        require(
            fetchedId == _userId ||
                _account == $.ecommercePlatform ||
                _account == address(this),
            "unauthorized caller not allowed"
        );
        _;
    }

    receive() external payable {}
}
