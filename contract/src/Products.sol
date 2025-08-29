// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;


import {IProduct,IUser} from "./interfaces/IEcomm.sol";
import {Utils,ProductsUtils} from "./lib/Utils.sol";
import "./Common.sol";

contract Products is Base, IProduct {
    IUser userInterface;
    address userContract;

     using ProductsUtils for Product[];
    Product[] public products;

    mapping(uint256 => uint256) productIdToRecordIndex;
    

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function initialize(
        address _userContractAddress,
        address initialOwner
    )
        public
        // address _feedAddr //  address _adminDaoAddress
        initializer
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        
        require(_userContractAddress != address(0), "Invalid user contract address");
        userContract = _userContractAddress;

        userInterface = IUser(address(userContract));
    }

    function listProduct(
        // address _seller,
        uint256 _unitprice,
        string calldata _title,
        // ProductSpec calldata _spec,
        uint256 _waranteeDuration,
        // uint8[] calldata _categories,
        uint256 _expectedDeliveryTime
    ) external {
        User memory sellerData = userInterface.getUserData(msg.sender);
        _isCallerSeller(sellerData);
        uint256 id = Utils._generateProductId(_title, msg.sender);
        Product memory newProductData = Product({
            productId: id,
            sellerId: sellerData.userId,
            unitPrice: _unitprice, //price is in _protocol default decimal[USD_DECIMALS] i.e 8
            waranteeDuration: _waranteeDuration,
            title: _title,
            // features: _spec,
            // productCategories: _categories,
            whenToExpectDelivery: block.timestamp + _expectedDeliveryTime
        });
        products.push(newProductData);
        productIdToRecordIndex[id] = products.length - 1;
        emit ResgisteredAProduct(id, sellerData.userId);
    }

    function updateProductPrice(
        address _account,
        uint256 _productId,
        uint256 _newPrice
    ) external {
        _isCallerSeller(userInterface.getUserData(_account));
        Product storage productData = products[
            productIdToRecordIndex[_productId]
        ];
        require(productData.productId != 0, "Product not found");
        User memory userData = userInterface.getUserData(_account);
        require(
            userData.userId == productData.sellerId,
            "you're not the product owner"
        );
        // require(productData.productId == _productId, "Product ID mismatch");
        require(_newPrice > 0, "New price must be greater than zero");
        productData.unitPrice = _newPrice; //price is in _protocol default decimal[USD_DECIMALS]
        products[productIdToRecordIndex[_productId]] = productData;
        emit ProductpriceUpdate(_productId, userData.userId, _newPrice);
    }

    function getProductData(
        uint256 _productId
    ) external view override returns (Product memory) {
        Product memory _product = products[productIdToRecordIndex[_productId]];
        require(
            _product.productId != 0 && _product.productId == _productId,
            "Invalid product id"
        );
        return _product;
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
