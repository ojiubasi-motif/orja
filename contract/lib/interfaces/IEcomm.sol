// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.26;

interface IEcomm {
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
    struct User {
        uint256 userId;
        string lastName;
        string firstName;
        address account;
        UserType _userType;
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
        int256 unitPrice;
        OrderStatus orderStatus;
        uint256 _proposedDeliveryTime; // in seconds
        // uint256 _deliveryTime; // in seconds
    }
    // function cartCheckoutBill(uint _userId, uint _payRef) external;
    function userCheckoutAmount(uint256 _payRef) external view returns (uint256);
    
    function sellerOrdersPerCart(
        uint _sellerId,
        uint _paymentRef
    ) external view returns (OrderItem[] memory orderItem);

    function getUserAccount(
        address _account
    ) external view returns (User memory _userData);
    
    function getCart(
        address _account
    ) external view returns (OrderItem[] memory);
    
    function tokenSymbolToDetails(
        string memory _symbol
    ) external view returns (Token memory tokenDetails);
}