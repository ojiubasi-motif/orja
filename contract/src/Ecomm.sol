// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import "@custom-interfaces/IEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/AggregatorV3Interface.sol";

// import "forge-std/console.sol";

contract Ecommerce {
    // 0xDFAA030fFBeADF74ED00CED7cA3c1Af765E89f2b==verified
    // events
    event resgisteredAuser(uint256 indexed _userId);
    event accountOwnershipChanged(
        uint256 indexed _userId,
        address _changedBy,
        address _oldOwner,
        address _newOwner
    );
    event verifiedAuser(uint256 indexed _userId);
    event resgisteredAProduct(
        uint256 indexed _productId,
        uint256 indexed _sellerId
    );
    event productpriceUpdate(
        uint256 indexed _productId,
        uint256 indexed _sellerId,
        uint256 _newPrice
    );
    event successfulCheckout(
        uint256 indexed _userId,
        uint256 indexed _paymentRefence,
        uint256 _amountPaid
    );

    address owner;
    IEcomEscrow escrowInterface;
    IERC20 erc20Interface;
    AggregatorV3Interface internal priceFeed;
    //eth=== 0x694AA1769357215DE4FAC081bf1f309aDC325306
    //BTC=== 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
    // address adminDAOcontract;
    address payable escrowContract;
    uint constant USD_DECIMALS = 1e8; // 8 decimals for USD
    uint8 constant USD_PRECISION = 8;

    struct TokenDetails {
        string symbol;
        address tokenAddr;
    }

    // TokenDetails[] acceptedTokens;

    mapping(address => bool) private isRegistered; //is acc is registered
    mapping(address => bool) private isVerified; //is acc verified?
    mapping(address => uint256) private userIdToRecordIndex; //for easy fetching of user record from users array
    mapping(uint256 => uint256) productIdToRecordIndex;
    mapping(string => bool) isAccepted;
    mapping(string => Token) public tokenSymbolToDetails;

    struct Token {
        address feedAddr;
        address tokenAddr;
    }

    enum UserType {
        Buyer,
        Seller
    }
    enum VerificationStatus {
        NotVerified,
        Verified,
        Processing
    }
    enum OrderStatus {
        Processing,
        InDisput,
        Delivered,
        Canceled,
        Settled
    }
    // UserType userCategory;

    mapping(uint256 _buyerId => OrderItem[] _products) private cart; //userId to cart
    mapping(uint256 _buyerId => bool) private isCartProcessed; //userId to cart processed status
    // mapping(uint256 _sellerId => mapping(uint256 _paymentRef => int8 _productQty)) private userToproductQtyInCart;
    mapping(uint256 _sellerId => mapping(uint256 _paymentRef => OrderItem[] _allSellerProductsInCart))
        private _allSellerOrdersPerCart;
    // mapping(uint => uint) cartCheckoutTotal;
    mapping(uint256 _paymentReference => uint256 _amount)
        private _checkoutAmount;

    constructor(
        address _escrowAddress
    ) // address _feddAddr //  address _adminDaoAddress
    {
        require(msg.sender != address(0), "invalid owner address");
        owner = msg.sender;
        require(
            _escrowAddress != address(0) && msg.sender == owner,
            "Invalid ESCROW address and/or unauthorized contract owner"
        );
        escrowContract = payable(_escrowAddress);
        // priceFeed = AggregatorV3Interface(_feddAddr);
        escrowInterface = IEcomEscrow(address(escrowContract));
        // adminDAOcontract = _adminDaoAddress;
    }

    struct OrderItem {
        uint256 sellerId;
        uint256 productId;
        uint32 qty;
        uint256 unitPrice;
        OrderStatus orderStatus;
        uint256 _proposedDeliveryTime; // in seconds
        // uint256 _deliveryTime; // in seconds
    }

    // OrderItem[] private _allSellerOrdersPerCart;

    struct User {
        uint256 userId;
        string lastName;
        string firstName;
        address account;
        UserType _userType;
        VerificationStatus verificationStatus;
    }

    struct ProductSpec {
        uint256 productionDay;
        uint256 expiryDay;
        uint8 batchId;
    }
    // 0x71C7A02C326311b38Dbd7dB35139590b201c4cA4
    // 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8===0xd9145CCE52D386f254917e481eB44e9943F39138
    struct Product {
        uint256 productId;
        uint256 sellerId;
        uint256 unitPrice;
        uint256 waranteeDuration;
        // uint8[] productCategories;
        string title;
        // ProductSpec features;
        uint256 whenToExpectDelivery; // in seconds
    }

    struct Category {
        uint256 categoryId;
        uint256 productQty;
        string title;
    }

    Product[] public products;
    User[] users;

    function addTokenToAcceptedList(
        address _tokenAddress,
        string memory _symbol,
        address _feedAddress
    ) external onlyOwner {
        if (keccak256(bytes(_symbol)) == keccak256(bytes("ETH"))) {
            address ethAddr = address(uint160(uint256(keccak256("ETH")))); //calculate address to use for eth
            isAccepted["ETH"] = true;
            tokenSymbolToDetails["ETH"] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: ethAddr
            });
        } else {
            isAccepted[_symbol] = true;
            tokenSymbolToDetails[_symbol] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: _tokenAddress
            });
        }

        // acceptedTokens.push(TokenDetails(_symbol,_tokenAddress));
    }

    function delistToken(string memory _symbol) external onlyOwner {
        isAccepted[_symbol] = false;
        tokenSymbolToDetails[_symbol] = Token({
            feedAddr: address(0), // Set the feed address if needed
            tokenAddr: address(0)
        });
    }

    //    ====getters for private variables============
    function userCheckoutAmount(uint256 _payRef) public view returns (uint256) {
        return _checkoutAmount[_payRef];
    }

    function sellerOrdersPerCart(
        uint _sellerId,
        uint _paymentRef
    ) public view returns (OrderItem[] memory orderItem) {
        return _allSellerOrdersPerCart[_sellerId][_paymentRef];
    }

    //  ======public functions============
    function register(
        string calldata _lastName,
        string calldata _firstName,
        UserType _userType
    ) external {
        require(msg.sender != address(0), "Invalid address");
        require(
            !isRegistered[msg.sender],
            "Address Already assigned to a user"
        );
        isRegistered[msg.sender] = true;
        User memory newUser;
        uint256 userId = _generateUserId(_lastName, _firstName, msg.sender);
        newUser = User(
            userId,
            _lastName,
            _firstName,
            msg.sender,
            _userType,
            VerificationStatus.NotVerified
        );
        users.push(newUser);
        // uint dataindex = /;
        userIdToRecordIndex[msg.sender] = users.length - 1;
        emit resgisteredAuser(userId);
    }

    function verifySeller(address _account) external onlyOwner {
        User storage userData = users[userIdToRecordIndex[_account]];
        require(userData.account == _account, "account mismatch");
        require(
            !isVerified[userData.account],
            "this seller is already Verified!"
        );
        isVerified[userData.account] = true;
        userData.verificationStatus = VerificationStatus.Verified;
        emit verifiedAuser(userData.userId);
    }

    function getUsers(
        uint _start,
        uint _end
    ) external view onlyOwner returns (User[] memory) {
        // require(_start < _end, "Invalid range");
        require(_end < users.length, "End index out of bounds");
        require(
            _start <= _end && _end - _start <= 500,
            "Invalid range and/or range shouldn't be bigger than 500"
        );
        User[] memory fetchedUsers = new User[](
            _start == _end ? 1 : (_end - _start) + 1
        );

        for (uint i = 0; i < fetchedUsers.length; i++) {
            fetchedUsers[i] = users[i + _start];
        }
        // User[] memory users = new User[](_end - _start);
        return fetchedUsers;
    }

    function getCart(
        address _account
    ) external view onlyAuthorizedBuyer(_account) returns (OrderItem[] memory) {
        User memory userData = getUserData(_account);
        OrderItem[] memory cartItems = cart[userData.userId];
        require(cartItems.length > 0, "Cart is empty");
        return cartItems;
    }

    function getProducts(
        uint _start,
        uint _end
    ) external view returns (Product[] memory) {
        require(_end < products.length, "End index out of bounds");
        require(
            _start <= _end && _end - _start <= 500,
            "Invalid range and/or range shouldn't be bigger than 500"
        );
        Product[] memory fetchedProducts = new Product[](
            _start == _end ? 1 : (_end - _start) + 1
        );

        for (uint i = 0; i < fetchedProducts.length; i++) {
            fetchedProducts[i] = products[i + _start];
        }

        return fetchedProducts;
    }

    function listProduct(
        // address _seller,
        uint256 _unitprice,
        string calldata _title,
        // ProductSpec calldata _spec,
        uint256 _waranteeDuration,
        // uint8[] calldata _categories,
        uint256 _expectedDeliveryTime
    ) external onlyAuthorizedSellerAccount(msg.sender) {
        User memory sellerData = getUserData(msg.sender);
        uint256 id = _generateProductId(_title, msg.sender);
        Product memory newProductData = Product({
            productId: id,
            sellerId: sellerData.userId,
            unitPrice: _unitprice * USD_DECIMALS, // scale to USD
            waranteeDuration: _waranteeDuration,
            title: _title,
            // features: _spec,
            // productCategories: _categories,
            whenToExpectDelivery: block.timestamp + _expectedDeliveryTime
        });
        products.push(newProductData);
        productIdToRecordIndex[id] = products.length - 1;
        emit resgisteredAProduct(id, sellerData.userId);
    }

    function updateProductPrice(
        address _account,
        uint256 _productId,
        uint256 _newPrice
    ) external onlyAuthorizedSellerAccount(_account) {
        Product storage productData = products[
            productIdToRecordIndex[_productId]
        ];
        User memory userData = getUserData(_account);
        require(userData.userId == productData.sellerId, "Unauthorized seller");
        require(productData.productId == _productId, "Product ID mismatch");
        require(_newPrice > 0, "New price must be greater than zero");
        productData.unitPrice = _newPrice * USD_DECIMALS; //uint256(uint(_newPrice)); //_newPrice;
        products[productIdToRecordIndex[_productId]] = productData;
        emit productpriceUpdate(_productId, userData.userId, _newPrice);
    }

    function addProductToCart(
        uint256 _productId,
        uint32 _qty
    )
        public
        // address _account
        onlyAuthorizedBuyer(msg.sender)
    {
        Product memory product = getProductData(_productId);
        User memory user = getUserData(msg.sender);
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
            _proposedDeliveryTime: product.whenToExpectDelivery // assuming delivery time is 7 days from now
        });
        cart[user.userId].push(item);
        // calculateUserBill(user.userId); // calculate the total bill for the user
        // userToproductQtyInCart[user.userId][product.productId] = _qty;
    }

    function calculateUserBill(uint256 _userId) private returns (uint256) {
        OrderItem[] memory cartItems = cart[_userId];
        require(cartItems.length > 0, "Cart is empty for this user");
        Product memory productData;

        for (uint256 i = 0; i < cartItems.length; ++i) {
            OrderItem memory item = cartItems[i];
            // get the current product data
            productData = getProductData(item.productId);
            if (productData.productId == 0) {
                continue; // skip if product is not valid
            }
            if (productData.sellerId == 0) {
                continue; // skip if product seller is not valid
            }
            // int8 quantity = userToproductQtyInCart[userData.userId][productId];
            _checkoutAmount[_userId] += (productData.unitPrice *
                cartItems[i].qty);
        }
        return _checkoutAmount[_userId];
    }

    function getUserData(address _account) public view returns (User memory) {
        require(isRegistered[_account], "account not registered");
        User memory userData = users[userIdToRecordIndex[_account]];
        require(
            userData.account != address(0) && userData.account == _account,
            "Invalid user address or user not registered"
        );
        return userData;
    }

    function getProductData(
        uint256 _productId
    ) public view returns (Product memory) {
        Product memory product = products[productIdToRecordIndex[_productId]];
        require(
            product.productId != 0 && product.productId == _productId,
            "Invalid product id"
        );
        return product;
    }

    function checkOut(
        address _account,
        string memory _payToken
    )
        public
        payable
        onlyAuthorizedBuyer(_account)
        returns (bool _resp, uint _payref)
    {
        // isCartProcessed[
        //     users[userIdToRecordIndex[_account]].userId
        // ] = true; // set the cart processed status before checkout
        // require(isCartProcessed[users[userIdToRecordIndex[_account]].userId] == false, "Cart already processed, u can't checkout again");
        (_resp, _payref) = _checkOut(_account, _payToken);
    }

    // ======private and internal fns=============
    function _generateUserId(
        string calldata _lastName,
        string calldata _firstName,
        address _userAcc
    ) private view returns (uint32 id) {
        // uint256 id;
        id = uint32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _lastName,
                        _firstName,
                        _userAcc,
                        block.timestamp
                    )
                )
            )
        );
        // return id;
    }

    function _generateProductId(
        string calldata _productTitle,
        address _listedBy
    ) private view returns (uint64 id) {
        // uint256 id;
        id = uint64(
            uint256(
                keccak256(
                    abi.encodePacked(_productTitle, _listedBy, block.timestamp)
                )
            )
        );
        // return id;
    }

    function _generatePaymentRefence(
        address _account
    ) private view returns (uint64 ref) {
        ref = uint64(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _account,
                        block.timestamp,
                        users[userIdToRecordIndex[_account]].userId
                    )
                )
            )
        );
    }

    function _checkOut(
        address _account,
        string memory _paymentTokenSymbol
    ) private returns (bool payResponse, uint payRef) {
        User memory userData = getUserData(_account);
        // OrderItem[] memory cartItems = cart[userData.userId];
        // require(
        //     cartItems.length > 0,
        //     "Cart is empty for this user, add items to cart first"
        // );

        require(
            !isCartProcessed[userData.userId],
            "Cart already processed, u can't checkout again"
        );
        isCartProcessed[userData.userId] = true; // mark the cart as processed

        uint256 amountPayable = calculateUserBill(userData.userId);
        uint256 paymentRef = _generatePaymentRefence(_account);

        // _checkoutAmount[paymentRef] = amountPayable;
        if (keccak256(bytes(_paymentTokenSymbol)) == keccak256(bytes("ETH"))) {
            uint expectedEthValue = getUSDequivalence(amountPayable, "ETH");

            require(
                msg.value >= expectedEthValue,
                "insufficient amount of ETH"
            );

            _checkoutAmount[paymentRef] = 0;
            // amountPayable = 0; // reset the amount payable after checkout

            (payResponse, payRef) = escrowInterface.payForItems{
                value: expectedEthValue
            }(userData.userId, amountPayable, paymentRef);
            // _checkoutAmount[paymentRef] = 0; // store the amount payable for this payment reference
            require(payResponse, "payment via ETH failed, try again later");
            emit successfulCheckout(userData.userId, payRef, amountPayable);
        } else {
            require(
                isAccepted[_paymentTokenSymbol],
                "sorry, the selected token is not accepted"
            );
            require(
                tokenSymbolToDetails[_paymentTokenSymbol].feedAddr !=
                    address(0) &&
                    tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr !=
                    address(0),
                "please specify a valid token for payment"
            );

            uint totalValue = getUSDequivalence(
                amountPayable,
                _paymentTokenSymbol
            );
            // console.log(
            //     "total value to be paid in eth(or payment token) for the items in cart==>",
            //     totalValue
            // );
            require(
                totalValue > 0,
                "the amount payable is zero, please check that your payment token is valid"
            );
            erc20Interface = IERC20(
                tokenSymbolToDetails[_paymentTokenSymbol].tokenAddr
            );
            require(
                erc20Interface.balanceOf(msg.sender) >=
                    uint(_checkoutAmount[paymentRef]),
                "insufficient balance of selected payment token, please topup"
            );
            _checkoutAmount[userData.userId] = 0;
            erc20Interface.transferFrom(msg.sender, escrowContract, totalValue);
        }
    }

    function getUSDequivalence(
        uint _totalBill,
        string memory _paymentToken
    ) public returns (uint256) {
        require(
            isAccepted[_paymentToken],
            "the selected token is not accepted for payment"
        );
        require(
            tokenSymbolToDetails[_paymentToken].feedAddr != address(0),
            "please specify a valid token for payment"
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
        require(tokenPrice > 0, "Invalid price fetched from feed");
        uint8 feedDecimals = priceFeed.decimals();

        if (keccak256(bytes(_paymentToken)) == keccak256(bytes("ETH"))) {
            // tokenDecimals = 18; // ETH price feed typically has 18 decimals
            int feedAnswer = feedDecimals == USD_PRECISION
                ? tokenPrice
                : scaleToPrecision(tokenPrice, feedDecimals, USD_PRECISION);

            return (_totalBill * 1e18) / uint256(feedAnswer);
        } else {
            uint tokenDecimals;
            (bool success, bytes memory _returned) = tokenSymbolToDetails[
                _paymentToken
            ].tokenAddr.call(abi.encodeWithSignature("decimals()"));
            uint8 decodedPrecision = abi.decode(_returned, (uint8));
            require(
                decodedPrecision > 0,
                "Invalid token decimals fetched from token contract"
            );
            tokenDecimals = 10 ** decodedPrecision;

            int feedAnswer = feedDecimals == USD_PRECISION
                ? tokenPrice
                : scaleToPrecision(tokenPrice, feedDecimals, USD_PRECISION);

            return (_totalBill * tokenDecimals) / uint256(feedAnswer);
        }
    }

    function scaleToPrecision(
        int256 _value,
        uint8 _defaultDecimals,
        uint8 _desiredDecimals
    ) internal pure returns (int256) {
        if (_defaultDecimals < _desiredDecimals) {
            return
                _value *
                int256(10 ** uint256(_desiredDecimals - _defaultDecimals));
        } else if (_defaultDecimals > _desiredDecimals) {
            return
                _value /
                int256(10 ** uint256(_defaultDecimals - _desiredDecimals));
        }
        return _value;
    }

    // =====modifiers=========
    modifier onlyAuthorizedSellerAccount(address _account) {
        User memory userData = getUserData(_account);
        require(
            userData.account != address(0) && userData.account == msg.sender,
            "unauthorized address not allowed to list product"
        );
        require(
            userData._userType == UserType.Seller &&
                userData.verificationStatus == VerificationStatus.Verified,
            "only verified sellers can list products"
        );
        _;
    }

    modifier onlyAuthorizedBuyer(address _account) {
        User memory userData = getUserData(_account);
        require(
            (userData.account != address(0) &&
                userData.account == msg.sender) || msg.sender == escrowContract,
            "only the user or the escrow contract can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized owner");
        _;
    }
}
