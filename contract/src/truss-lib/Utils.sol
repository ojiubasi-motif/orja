// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@chainlink/AggregatorV3Interface.sol";
import {Product, OrderItem} from "@src/Common.sol";
import "forge-std/console.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IProduct as ProductContract} from "@custom-interfaces/IEcomm.sol";

library Utils {
    
    function previewCheckoutBill(OrderItem[] memory _order) external pure returns (uint256) {
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

    function scaleToPrecision(
        int256 _value,
        uint8 _defaultDecimals,
        uint8 _desiredDecimals
    ) public pure returns (int256) {
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

    function generateProductId(
        uint256 _refCounter,
        string calldata _productTitle,
        address _listedBy
    ) external view returns (uint64 id) {
        // uint256 id;
        id = uint64(
            uint256(
                keccak256(
                    abi.encodePacked(_refCounter, _productTitle, _listedBy, block.timestamp)
                )
            )
        );
        // return id;
    }

    // function checkUserBill()
    function getEthEquivalence(
        uint _totalBill,
        uint8 _feedDecimals,
        uint8 _defaultDecimals,
        uint256 _tokenPrice
    ) external pure returns (uint256, bytes memory) {
        require(_tokenPrice > 0, "Invalid price fetched from feed");
        require(
            _feedDecimals > 0,
            "Invalid feed decimals fetched from price feed"
        );

        int feedAnswer = _feedDecimals == _defaultDecimals
            ? int(_tokenPrice)
            : scaleToPrecision(
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

    function getTokenEquivalence(
        uint _totalBill,
        string memory _tokenSymbol,
        address tokenAddr,
        uint8 _feedDecimals,
        uint8 _defaultDecimals,
        uint256 _tokenPrice
    ) external returns (uint256, bytes memory) {
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
            : scaleToPrecision(
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

    function confirmValueSent(uint256 _bill, uint _valueSent, bytes memory _feedData) external pure returns(string memory symbol, int256 _price){
        (string memory _symbol, uint8 _decimal, int256 _tokenPrice) = abi
            .decode(_feedData, (string, uint8, int256));
        require(_tokenPrice > 0, "Invalid price fetched from feed");

        (bool success, uint256 _ethVal) = Math.tryMul(
            _valueSent,
            uint(_tokenPrice)
        );
        require(success, "escrow overflow calculating eth value in usd");
        uint EthvalueInUsd = Math.ceilDiv(_ethVal, 1e18); // Assuming pricefeed returns price in 8 decimals
        // console.log("EthvalueInUsd==>", EthvalueInUsd);
        // console.log("_bill==>", _bill);
        require(EthvalueInUsd >= _bill, "Insufficient ETH sent for payment");
        return (_symbol, _tokenPrice);
    }
}

library ProductsUtils {
    function _fetchSomeProducts(
        Product[] memory _products,
        uint _start,
        uint _end
    ) internal pure returns (Product[] memory) {
        // require(_end < _products.length, "_end index is out of bounds");
        require(
            _start <= _end && _end - _start <= 100,
            "you cannot fetch more than 100 products at once, and  start must not be greater than end"
        );
        uint256 _lastIndex = _end > _products.length - 1 ? _products.length - 1 : _end;
        uint256 _startIndex = _start > _lastIndex ? _lastIndex : _start;
        if(_products.length <= 100){
            _lastIndex = _products.length - 1;
            _startIndex = _startIndex <= _lastIndex ? _startIndex : _lastIndex;
        }
        Product[] memory fetchedProducts = new Product[](
            _startIndex == _lastIndex ? 1 : (_lastIndex - _startIndex) + 1
        );

        for (uint i = 0; i < fetchedProducts.length; i++) {
            fetchedProducts[i] = _products[i + _startIndex];
        }

        return fetchedProducts;
    }
}