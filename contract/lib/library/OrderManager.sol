// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderLib {
    // enum Status {
    //     Pending,
    //     Shipped,
    //     Delivered,
    //     Cancelled
    // }

    // struct Order {
    //     address buyer;
    //     uint256 amount;
    //     Status status;
    // }
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

    // function isDelivered(Order memory order) internal pure returns (bool) {
    //     return order.status == Status.Delivered;
    // }
}
