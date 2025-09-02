// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// @dev upgradability imports
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

enum UserType {
    Buyer,
    Seller
}

enum VerificationStatus {
    NotVerified,
    Verified,
    Processing
}

struct User {
    uint256 userId;
    string lastName;
    string firstName;
    address account;
    // UserType _userType;
    VerificationStatus verificationStatus;
}
enum OrderStatus {
    Processing,
    InDisput,
    Delivered,
    Canceled,
    Settled
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
struct Token {
    address feedAddr;
    address tokenAddr;
}
struct ProductSpec {
    uint256 productionDay;
    uint256 expiryDay;
    uint8 batchId;
}

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

abstract contract Base is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    //@test======for contract test on foundry local--
    

    event WithdrawSuccess(
        uint256 indexed _userId,
        string _tokenSymbol,
        uint256 indexed _payRef,
        uint256 _amount,
        uint256 indexed _date
    );
    event ProductOrderStatusUpdated(
        uint256 indexed _buyer,
        uint256 indexed _payref,
        uint256 indexed _itemId,
        bool _delivered
    );
    event CanceledDelivery(
        uint indexed _seller,
        uint indexed _ref,
        uint indexed _item
    );
    event ResgisteredAuser(uint256 indexed _userId);
    event AccountOwnershipChanged(
        uint256 indexed _userId,
        address _changedBy,
        address _oldOwner,
        address _newOwner
    );
    event VerifiedAuser(uint256 indexed _userId);
    event ResgisteredAProduct(
        uint256 indexed _productId,
        uint256 indexed _sellerId
    );
    event ProductpriceUpdate(
        uint256 indexed _productId,
        uint256 indexed _sellerId,
        uint256 _newPrice
    );
    event SuccessfulCheckout(
        uint256 indexed _userId,
        uint256 indexed _paymentRefence,
        string _currency,
        uint256 _amountPaid
    );

    function _isCallerSeller(User memory _user) internal view {
        // CommonLib.User memory userData = getUserData(_account);
        require(
            _user.account != address(0) && _user.account == msg.sender,
            "unauthorized address not allowed to list product"
        );
        require(
            // _user._userType == UserType.Seller &&
                _user.verificationStatus == VerificationStatus.Verified,
            "only verified sellers can list products"
        );
    }

    modifier onlyAuthorizedBuyerOrEscrow(address _account, address _escrow) {
        // CommonLib.User memory userData = getUserData(_account);
        require(
            (_account != address(0) && _account == msg.sender) ||
                msg.sender == _escrow,
            "only registered user or the escrow contract can call this function"
        );
        _;
    }

    // @dev deployed and verified contracts
    /*
    User Manager Imp: 0x6b72697e37a9E0d769FDF9D97208b74C0ec2133c
  product Impl: 0x982549A4Cd1061634ec29EEA33D3C5dFb57F8a0F
  Ecommerce Impl: 0x4Ef5e3a11e4FBaf4718B0E80ef65A19a1444F21D
  Escrow Impl: 0xbdF1Acf84592CAC5Cf7AaC23c71245a27cce2051
  User Manager proxy: 0x1DB6D8e2eE32aA66E8eACC63c1dC6F11f569cADc
  product proxy: 0xc6F33EE044E152c9961d42Ac3ed3F8f58412240d
  Ecommerce Proxy: 0x15bb847fb6a8446408E05eA0377474479e2FbF97
  Escrow Proxy: 0x1d3f2479e46674C42f87f631477BA58CD3FbAd00
    */
}
