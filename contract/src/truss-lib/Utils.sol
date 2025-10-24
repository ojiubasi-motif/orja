// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/AggregatorV3Interface.sol";
import {Product, OrderItem} from "../Common.sol";
import "forge-std/console.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IProduct as ProductContract} from "../interfaces/IEcomm.sol";

library Utils {
    // function _calculateTotalBill(
    //     ProductContract productMngr, // pass the contract reference
    //     OrderItem[] memory _order
    // ) internal returns (uint256) {
    //     Product memory productData;
    //     uint256 cumm = 0;
    //     for (uint256 i = 0; i < _order.length; ++i) {
    //         productData = productMngr.getProductData(_order[i].productId);
    //         if (productData.productId == 0) {
    //             continue; // skip if product is not valid
    //         }
    //         if (productData.sellerId == 0) {
    //             continue; // skip if product seller is not valid
    //         }
    //         // int8 quantity = userToproductQtyInCart[userData.userId][productId];
    //         cumm += (productData.unitPrice * _order[i].qty);
    //     }
    //     return cumm;
    // }
    
    function previewCheckoutBill(OrderItem[] memory _order) public pure returns (uint256) {
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
            require(_resp, "overflow calculating product cost, reduce the qty of some items");
            // int8 quantity = userToproductQtyInCart[userData.userId][productId];
            (bool _cummRes, uint256 answr) = Math.tryAdd(cumm, _cost);
            require(_cummRes, "overflow calculating aggregated cost");
            cumm = answr;
        }
        return cumm;
    }

    function _scaleToPrecision(
        int256 _value,
        uint8 _defaultDecimals,
        uint8 _desiredDecimals
    ) internal pure returns (int256) {
        if (_defaultDecimals < _desiredDecimals) {
            (bool success, uint256 scaledValue) = Math.tryMul(
                uint256(_value),
                10 ** uint256(_desiredDecimals - _defaultDecimals)
            );
            require(success, "Multiplication overflow in scaling to precision");
            return int256(scaledValue);
                // _value *
                // int256(10 ** uint256(_desiredDecimals - _defaultDecimals));
        } else if (_defaultDecimals > _desiredDecimals) {
            return
            int256(Math.ceilDiv(uint256(_value), 10 ** uint256(_defaultDecimals - _desiredDecimals)));
                // _value /
                // int256(10 ** uint256(_defaultDecimals - _desiredDecimals));
        }
        return _value; //if _desiredDecimals == _defaultDecimals
    }

    function _generateProductId(
        string calldata _productTitle,
        address _listedBy
    ) internal view returns (uint64 id) {
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

    // function checkUserBill()
    function _getEthEquivalence(
        uint _totalBill,
        uint8 _feedDecimals,
        uint8 _defaultDecimals,
        uint256 _tokenPrice
    ) internal pure returns (uint256, bytes memory) {
        require(_tokenPrice > 0, "Invalid price fetched from feed");
        require(
            _feedDecimals > 0,
            "Invalid feed decimals fetched from price feed"
        );

        int feedAnswer = _feedDecimals == _defaultDecimals
            ? int(_tokenPrice)
            : _scaleToPrecision(
                int(_tokenPrice),
                _feedDecimals,
                _defaultDecimals
            );
        // console.log("feedAnswer sh==>", feedAnswer);
        // console.log("feeddecimal sh==>", _feedDecimals);
        bytes memory feedData = abi.encode("ETH", _feedDecimals, feedAnswer);

        (bool success, uint256 scaledTotalBill) = Math.tryMul(
            _totalBill,
            1e18
        );
        require(success, "overflow calculating totalBill in eth equivalence");

        return (Math.ceilDiv(scaledTotalBill, uint256(feedAnswer)), feedData); //return the equivalent amount of token in its smallest unit
        // }

        // return ((_totalBill * 1e18) / uint256(feedAnswer), feedData); //return the equivalent amount of eth in wei
    }

    function _getTokenEquivalence(
        uint _totalBill,
        string memory _tokenSymbol,
        address tokenAddr,
        uint8 _feedDecimals,
        uint8 _defaultDecimals,
        uint256 _tokenPrice
    ) internal returns (uint256, bytes memory) {
        require(_tokenPrice > 0, "Invalid price fetched from feed");
        require(
            _feedDecimals > 0,
            "Invalid feed decimals fetched from price feed"
        );
        // else {
        uint256 tokenPrecision;
        (, bytes memory _returned) = tokenAddr.call(
            abi.encodeWithSignature("decimals()")
        );
        uint8 decodedDecimals = abi.decode(_returned, (uint8));
        require(
            decodedDecimals > 0,
            "Invalid token decimals fetched from token contract"
        );
        tokenPrecision = 10 ** decodedDecimals;
        // @dev ensure protocol precision(USD_PRECISION) is same with the pricefeed precision(10**8 for usd)
        int feedAnswer = _feedDecimals == _defaultDecimals
            ? int(_tokenPrice)
            : _scaleToPrecision(
                int(_tokenPrice),
                _feedDecimals,
                _defaultDecimals
            );

        bytes memory feedData = abi.encode(
            _tokenSymbol,
            _feedDecimals,
            feedAnswer,
            tokenAddr
        );
        (bool success, uint256 scaledTotalBill) = Math.tryMul(
            _totalBill,
            tokenPrecision
        );
        require(success, "overflow calculating totalBill in token equivalence");

        return (Math.ceilDiv(scaledTotalBill, uint256(feedAnswer)), feedData); //return the equivalent amount of token in its smallest unit
        // }
    }
}

library ProductsUtils {
    function _fetchSomeProducts(
        Product[] memory _products,
        uint _start,
        uint _end
    ) internal pure returns (Product[] memory) {
        // require(_end < _products.length, "End index out of bounds");
        require(
            _start <= _end && _end - _start <= 100,
            "Invalid range and/or range shouldn't be bigger than 100"
        );
        //  require(_end < products.length, "End index out of bounds");
        // require(
        //     _start <= _end && _end - _start <= 100,
        //     "Invalid range and/or range shouldn't be bigger than 100"
        // )
        if(_products.length <= 100){
            _end = _products.length - 1;
        }
        Product[] memory fetchedProducts = new Product[](
            _start == _end ? 1 : (_end - _start) + 1
        );

        for (uint i = 0; i < fetchedProducts.length; i++) {
            fetchedProducts[i] = _products[i + _start];
        }

        return fetchedProducts;
    }
}