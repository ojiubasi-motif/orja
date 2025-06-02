// SPDX-License-Identifier: MIT
pragma solidity >=0.8.26;

import "@custom-interfaces/IEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/AggregatorV3Interface.sol";

contract Ecommerce {
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
        int256 _newPrice
    );
    event successfulCheckout(
        uint256 indexed _userId,
        uint256 indexed _paymentRefence
    );

    address owner;
    IEcomEscrow escrowInterface;
    IERC20 erc20Interface;
    AggregatorV3Interface internal priceFeed;
    //eth=== 0x694AA1769357215DE4FAC081bf1f309aDC325306
    //BTC=== 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
    // address adminDAOcontract;
    address payable escrowContract;

    struct TokenDetails {
        string symbol;
        address tokenAddr;
    }

    // TokenDetails[] acceptedTokens;

    mapping(address => bool) private isRegistered; //is acc is registered
    mapping(address => bool) private isVerified; //is acc verified?
    mapping(address => uint256) private userIdToRecordIndex; //for easy fetching of user record from users array
    mapping(uint256 => uint256) productIdToRecordIndex;
    mapping(address => bool) isAccepted;
    mapping(string => address) tokenSymbolToAddress;

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

    mapping(uint256 => uint256[]) private cart; //userId to cart
    mapping(uint256 => mapping(uint256 => int8)) private userToproductQtyInCart;
    mapping(uint256 => mapping(uint256 => OrderItem[]))
        private _allSellerOrdersPerCart;
    // mapping(uint => uint) cartCheckoutTotal;
    mapping(uint256 => int256) private _checkoutAmount;

    constructor(address _escrowAddress) //  address _adminDaoAddress
    {
        require(msg.sender != address(0), "invalid owner address");
        owner = msg.sender;
        require(
            _escrowAddress != address(0) && msg.sender == owner,
            "Invalid ESCROW address and/or unauthorized contract owner"
        );
        escrowContract = payable(_escrowAddress);
        escrowInterface = IEcomEscrow(address(escrowContract));
        // adminDAOcontract = _adminDaoAddress;
    }

    struct OrderItem {
        uint256 productId;
        int8 qty;
        int256 unitPrice;
        OrderStatus orderStatus;
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
        int256 unitPrice;
        uint256 waranteeDuration;
        uint8[] productCategories;
        string title;
        ProductSpec features;
    }

    struct Category {
        uint256 categoryId;
        uint256 productQty;
        string title;
    }

    Product[] products;
    User[] users;

    function addTokenToAcceptedList(
        address _tokenAddress,
        string memory _symbol
    ) external onlyOwner {
        isAccepted[_tokenAddress] = true;
        tokenSymbolToAddress[_symbol] = _tokenAddress;

        // acceptedTokens.push(TokenDetails(_symbol,_tokenAddress));
    }

    function delistToken(address _tokenAddress) external onlyOwner {
        isAccepted[_tokenAddress] = false;
    }

    //     function isTokenAccepted(address tokenAddr) public view returns (bool){
    //         return isAccepted[tokenAddr];
    //     }
    // }

    //    ====getters for private variables============
    function userCheckoutAmount(uint256 _userId) public view returns (int256) {
        return _checkoutAmount[_userId];
    }

    // function sellerToOrder(uint256 _sellerId, uint256 _paymentRef)
    //     public
    //     view
    //     returns (OrderItem memory orderItem)
    // {
    //     return _sellerToOrder[_sellerId][_paymentRef];
    // }
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

    // function changeAccountOwnership(uint256 _userId, address _newOwner)
    //     external
    // {
    //     require(msg.sender != address(0), "Invalid address");
    //     User memory userData = users[userIdToRecordIndex[_userId]];
    //     require(
    //         msg.sender == userData.account || msg.sender == adminDAOcontract,
    //         "unauthorized address not allowed to change ownership"
    //     );
    //     // if(msg.sender == userData.account)
    //     address oldOwnwer = userData.account;
    //     // change the owner||||||
    //     userData.account = _newOwner;
    //     users[userIdToRecordIndex[_userId]] = userData;
    //     emit accountOwnershipChanged(
    //         _userId,
    //         msg.sender,
    //         oldOwnwer,
    //         userData.account
    //     );
    // }
    function verifySeller(address _account) external onlyOwner {
        User storage userData = users[userIdToRecordIndex[_account]];
        require(
            !isVerified[userData.account],
            "this seller is already Verified!"
        );
        isVerified[userData.account] = true;
        userData.verificationStatus = VerificationStatus.Verified;
        emit verifiedAuser(userData.userId);
    }

    function getUserAccount(
        address _account
    ) public view returns (User memory _userData) {
        User memory userData = users[userIdToRecordIndex[_account]];
        _userData = userData;
    }

    function getUsers(uint _start, uint _end) external view onlyOwner returns (User[] memory) {
        // require(_start < _end, "Invalid range");
        require(_end < users.length, "End index out of bounds");
        require(_start < _end && _end - _start <= 500, "Invalid range and/or range shouldn't be bigger than 500");
        User[] memory fetchedUsers = new User[](_end - _start);

        for(uint i = 0; i < fetchedUsers.length; i++) {
            fetchedUsers[i] = users[i + _start];
        }
        // User[] memory users = new User[](_end - _start);
        return fetchedUsers;
    }

    function getProducts(uint _start, uint _end) external view returns (Product[] memory) {
        
        require(_end < products.length, "End index out of bounds");
        require(_start < _end && _end - _start <= 500, "Invalid range and/or range shouldn't be bigger than 500");
        Product[] memory fetchedProducts = new Product[](_end - _start);

        for(uint i = 0; i < fetchedProducts.length; i++) {
            fetchedProducts[i] = products[i + _start];
        }
        
        return fetchedProducts;
    }

    // function setAdminContractAddress(address _daoContract) external {
    //     require(_daoContract != address(0), "Invalid Address");
    //     adminDAOcontract = _daoContract;
    //     //require(_daoContract.code.length > 0,"Invalid DAO Contract Address");
    // }

    function listProduct(
        address _seller,
        int256 _unitprice,
        string calldata _title,
        ProductSpec calldata _spec,
        uint256 _waranteeDuration,
        uint8[] calldata _categories
    ) external onlyAuthorizedSellerAccount(msg.sender) {
        User memory sellerData = getUserData(_seller);
        uint256 id = _generateProductId(_title, msg.sender);
        Product memory newProductData = Product({
            productId: id,
            sellerId: sellerData.userId,
            unitPrice: _unitprice,
            waranteeDuration: _waranteeDuration,
            title: _title,
            features: _spec,
            productCategories: _categories
        });
        products.push(newProductData);
        productIdToRecordIndex[id] = products.length - 1;
        emit resgisteredAProduct(id, sellerData.userId);
    }

    function updateProductPrice(
        address _account,
        uint256 _productId,
        int256 _newPrice
    ) external onlyAuthorizedSellerAccount(_account) {
        Product storage productData = products[
            productIdToRecordIndex[_productId]
        ];
        User memory userData = getUserData(_account);
        productData.unitPrice = _newPrice;
        products[productIdToRecordIndex[_productId]] = productData;
        emit productpriceUpdate(_productId, userData.userId, _newPrice);
    }

    function addProductToCart(
        uint256 _productId,
        int8 _qty,
        address _account
    ) public onlyAuthorizedBuyer(_account) {
        Product memory product = getProductData(_productId);
        User memory user = getUserData(_account);
        cart[user.userId].push(product.productId);
        userToproductQtyInCart[user.userId][product.productId] = _qty;
    }

    function getUserData(address _account) public view returns (User memory) {
        User memory userData = users[userIdToRecordIndex[_account]];
        require(
            userData.account != address(0) && userData.account == msg.sender,
            "Invalid user id"
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
    ) public onlyAuthorizedBuyer(_account) {
        _checkOut(_account, _payToken);
    }

    // ======private and internal fns=============
    function _generateUserId(
        string calldata _lastName,
        string calldata _firstName,
        address _userAcc
    ) private view returns (uint32 id) {
        // uint256 id;
        id = uint32(uint256(
            keccak256(
                abi.encodePacked(
                    _lastName,
                    _firstName,
                    _userAcc,
                    block.timestamp
                )
            )
        ));
        // return id;
    }

    function _generateProductId(
        string calldata _productTitle,
        address _listedBy
    ) private view returns (uint64 id) {
        // uint256 id;
        id = uint64(uint256(
            keccak256(
                abi.encodePacked(_productTitle, _listedBy, block.timestamp)
            )
        ));
        // return id;
    }

    function _generatePaymentRefence(
        address _account
    ) private view returns (uint64 ref) {
        ref = uint64(uint256(
            keccak256(
                abi.encodePacked(
                    _account,
                    block.timestamp,
                    users[userIdToRecordIndex[_account]].userId
                )
            )
        ));
    }

    function _calculateProductPrice(
        uint256 _productId,
        int8 _qty
    ) internal view returns (int256) {
        return getProductData(_productId).unitPrice * _qty;
    }

    function _checkOut(
        address _account,
        string memory _paymentTokenSymbol
    ) private {
        User memory userData= getUserData(_account);
        uint256[] memory cartItems = cart[userData.userId];
        int256 amountPayable;
        uint256 paymentRef = _generatePaymentRefence(_account);
        Product memory product;
        // ✅ Predefine the length of memory array
        // OrderItem[] memory _sellerToOrders = new OrderItem[](cartItems.length);

        for (uint256 i = 0; i < cartItems.length; ++i) {
            uint256 productId = cartItems[i];
            product = getProductData(productId);
            if(product.sellerId == 0) {
                continue; // skip if product is not valid
            }
            int8 quantity = userToproductQtyInCart[userData.userId][productId];
            amountPayable += product.unitPrice * quantity;

            // ✅ Use index-based assignment
            _allSellerOrdersPerCart[product.sellerId][paymentRef].push(
                OrderItem({
                    productId: product.productId,
                    qty: quantity,
                    unitPrice: product.unitPrice,
                    orderStatus: OrderStatus.Processing
                })
            );
        }
        //  = _sellerToOrders;
        _checkoutAmount[userData.userId] = amountPayable;
        if (msg.value > 0) {
            // pay with native currency(ETH)
            // ==let's check the latest eth price in USD...
            priceFeed = AggregatorV3Interface(
                0x694AA1769357215DE4FAC081bf1f309aDC325306
            );
            (, /* uint80 roundId */ int256 answer, , , ) = /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
            int expectedEthValue = (_checkoutAmount[userData.userId] * 1e18) / answer;
            require(
                msg.value >= uint(expectedEthValue),
                "insufficient amount of ETH"
            );

            escrowInterface.payForItems{value: msg.value}(userData.userId, paymentRef);
        } else {
            // pay with stablecoins or other tokens...USDC USDT BUSD LINK
            require(
                tokenSymbolToAddress[_paymentTokenSymbol] != address(0),
                "please specify a valid token for payment"
            );
            require(
                isAccepted[tokenSymbolToAddress[_paymentTokenSymbol]] == true,
                "sorry, the selected token is not accepted"
            );
            //====this is where u verify from chainlink the value of the token selected
            //  and check if it's >= _checkoutAmount before you continue...===========

            address tokenAddr = tokenSymbolToAddress[_paymentTokenSymbol];
            erc20Interface = IERC20(tokenAddr);
            require(
                erc20Interface.balanceOf(msg.sender) >=
                    uint(_checkoutAmount[userData.userId]),
                "you don't have enough of the token to pay for your order, please topup"
            );
            erc20Interface.transferFrom(
                msg.sender,
                escrowContract,
                uint(_checkoutAmount[userData.userId])
            );
        }

        _checkoutAmount[userData.userId] = 0;

        emit successfulCheckout(userData.userId, paymentRef);
    }

    // function compareStrings(string _input) public returns(bool){
    //      return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    // }
    // =======escrow function============
    // function _safeSendETH(uint256 _userId) internal {
    //     require(
    //         uint(_checkoutAmount[_userId]) <= msg.value,
    //         "Insufficient funds sent"
    //     );

    //     (bool success, ) = escrowContract.call{
    //         value: uint(_checkoutAmount[_userId])
    //     }("");
    //     _checkoutAmount[_userId] = 0;
    //     require(success, "ETH transfer failed");
    // }

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
            userData.account != address(0) && userData.account == msg.sender,
            "unauthorized buyer"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender != address(0) && msg.sender == owner,
            "unauthorized owner"
        );
        _;
    }
}
