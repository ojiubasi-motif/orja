// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;


// import "@src/v1/Products.sol";
// import { OrderItem} from "@src/Common.sol";

import {IProduct, IUser} from "@src/interfaces/IEcomm.sol";
import {Utils, ProductsUtils} from "@src/truss-lib/Utils.sol";
import "@src/Common.sol";


contract Products is Base, IProduct {
    IUser userInterface;
    using ProductsUtils for Product[];
    bytes32 private constant PRODUCT_STORAGE_SLOT = keccak256("erc7575.product.storage");

    struct ProductStorage {
        uint256 _refCounter;
        address userContract;
        Product[] products;
        mapping(uint256 => uint256) productIdToRecordIndex;
    }

    //  using ProductsUtils for Product[];
    // Product[] public products;

    // mapping(uint256 => uint256) productIdToRecordIndex;
    
    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function _getProductStorage() private pure returns(ProductStorage storage $) {
         bytes32 slot = PRODUCT_STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }

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
        
        require(_userContractAddress != address(0), "Invalid user contract address");
        ProductStorage storage $ = _getProductStorage();
        $.userContract = _userContractAddress;

        userInterface = IUser(address($.userContract));
    }
    /**=========================
     * Fuzz related functions
    ============================*/
    function isProductListed(uint256 _productId) public view returns (bool) {
        ProductStorage storage $ = _getProductStorage();
        if ($.products.length == 0) return false;
        // Product memory prod = products[productIdToRecordIndex[_productId]];
        return $.productIdToRecordIndex[_productId] > 0;
    }

    function listProduct(
        // address _seller,
        uint256 _unitprice,
        string calldata _title,
        // ProductSpec calldata _spec,
        uint256 _waranteeDuration,
        // uint8[] calldata _categories,
        uint256 _expectedDeliveryTime
    ) external returns (uint256 _productId) {
        require(_unitprice > 0, "Price must be greater than zero");
        User memory sellerData = userInterface.getUserData(msg.sender);
        _isCallerSeller(sellerData);
        ProductStorage storage $ = _getProductStorage();
        $._refCounter++;
        uint256 id = Utils.generateProductId($._refCounter,_title, msg.sender);
        Product memory newProductData = Product({
            productId: id,
            sellerId: sellerData.userId,
            unitPrice: _unitprice, //just to avoid loss of precision, price is multiplied by 1e8
            waranteeDuration: _waranteeDuration,
            title: _title,
            // features: _spec,
            // productCategories: _categories,
            whenToExpectDelivery: block.timestamp + _expectedDeliveryTime
        });
        $.products.push(newProductData);
        $.productIdToRecordIndex[id] = $.products.length;
        emit ResgisteredAProduct(id, sellerData.userId);
        return id;
    }

    function updateProductPrice(
        // address _account,
        uint256 _productId,
        uint256 _newPrice
    ) external {
        User memory userData = userInterface.getUserData(msg.sender);
        _isCallerSeller(userData);
        ProductStorage storage $ = _getProductStorage();
        Product storage productData = $.products[
            $.productIdToRecordIndex[_productId] - 1
        ];
        require(productData.productId == _productId, "Product not found");
        require(
            userData.userId == productData.sellerId,
            "you're not the product owner"
        );
        // require(productData.productId == _productId, "Product ID mismatch");
        require(_newPrice > 0, "New price must be greater than zero");
        productData.unitPrice = _newPrice; //price is in _protocol default decimal[USD_DECIMALS]
        $.products[$.productIdToRecordIndex[_productId] - 1] = productData;
        emit ProductpriceUpdate(_productId, userData.userId, _newPrice);
    }

    // function isProductListed

    function getProductData(
        uint256 _productId
    ) external view override returns (Product memory) { 
        ProductStorage storage $ = _getProductStorage();
        require($.products.length > 0, "products array empty");
        Product memory _product = $.products[$.productIdToRecordIndex[_productId] - 1];
        // require(
        //     _product.productId != 0 && _product.productId == _productId,
        //     "Invalid product id"
        // );
        return $.productIdToRecordIndex[_productId] == 0 ? Product(0,0,0,0,"",0) : _product;
    }

    function getProducts(
        uint _start,
        uint _end
    ) external view returns (Product[] memory) {
        ProductStorage storage $ = _getProductStorage();
        require($.products.length > 0, "products array empty");
        return $.products._fetchSomeProducts(_start, _end);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
