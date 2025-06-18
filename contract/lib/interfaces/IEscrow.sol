// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.26;

interface IEcomEscrow {
    function payForItems(uint _userId, uint _payRef) external payable returns (bool, uint);
    function updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _delivered
    ) external ;
}