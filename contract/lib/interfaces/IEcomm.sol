// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.26;

interface IEcomm {
    // function cartCheckoutBill(uint _userId, uint _payRef) external;
    function userCheckoutAmount(uint256 _userId) external view returns (uint256);
}