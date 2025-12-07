// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.26;

import {Token} from "@src/Common.sol";

interface IEcomEscrow  {
    function payForItemsWithETH(uint _userId,uint _bill, bytes memory _feedData, uint _payRef) external payable returns (bool, uint);
    function payForItemsWithERC20(uint _userId,uint _bill,uint _tokenAmountSent, string memory _paymentTokenSymbol, uint _payRef, bytes memory _feedData) external returns (bool, uint);
    function updateDeliveryStatus(
        uint _payRef,
        uint _productId,
        bool _delivered
    ) external ;
    function isAccepted(string memory _symbol) external view returns (bool);
    function tokenSymbolToDetails(string memory _symbol) external view returns (Token memory);
    function checkTokenStatusAndDetails(
        string memory _symbol
    ) external view returns (bool, Token memory);
}