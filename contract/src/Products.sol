// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;


import {IProduct,IUser} from "./interfaces/IEcomm.sol";
import {Utils,ProductsUtils} from "./truss-lib/Utils.sol";
import "./Common.sol";
import  {Productsv1} from "./v1/Products.sol";

contract Products is Productsv1 {
    // IUser userInterface;
    // address userContract;

     using ProductsUtils for Product[];
    // Product[] public products;

    // mapping(uint256 => uint256) productIdToRecordIndex;
    
    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function initializev2(
        address _userContractAddress,
        address initialOwner
    )
        external
        // address _feedAddr //  address _adminDaoAddress
        reinitializer(2)
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        require(_userContractAddress != address(0), "Invalid user contract address");
        userContract = _userContractAddress;

        userInterface = IUser(address(userContract));
    }
    /**=========================
     * Fuzz related functions
    ============================*/
    function isProductListed(uint256 _productId) public view returns (bool) {
        if (products.length == 0) return false;
        // Product memory prod = products[productIdToRecordIndex[_productId]];
        return productIdToRecordIndex[_productId] > 0;
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
        uint256 id = Utils._generateProductId(_title, msg.sender);
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
        products.push(newProductData);
        productIdToRecordIndex[id] = products.length;
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
        Product storage productData = products[
            productIdToRecordIndex[_productId] - 1
        ];
        require(productData.productId == _productId, "Product not found");
        require(
            userData.userId == productData.sellerId,
            "you're not the product owner"
        );
        // require(productData.productId == _productId, "Product ID mismatch");
        require(_newPrice > 0, "New price must be greater than zero");
        productData.unitPrice = _newPrice; //price is in _protocol default decimal[USD_DECIMALS]
        products[productIdToRecordIndex[_productId] - 1] = productData;
        emit ProductpriceUpdate(_productId, userData.userId, _newPrice);
    }

    function getProductData(
        uint256 _productId
    ) external view override returns (Product memory) { 
        require(products.length > 0, "products array empty");
        Product memory _product = products[productIdToRecordIndex[_productId] - 1];
        // require(
        //     _product.productId != 0 && _product.productId == _productId,
        //     "Invalid product id"
        // );
        return productIdToRecordIndex[_productId] == 0 ? Product(0,0,0,0,"",0) : _product;
    }

    

    function getProducts(
        uint _start,
        uint _end
    ) external view returns (Product[] memory) {
        return products._fetchSomeProducts(_start, _end);
        
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
