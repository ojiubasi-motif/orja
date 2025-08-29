// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; //this has Ierc20 imported already

abstract contract ERC20Base {
    
    using SafeERC20 for IERC20;
    IERC20 erc20;

    function safeDepositToEscrow(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        _token.safeTransferFrom(_from, _to, _amount);
    }

    function safeWithdrawFromEscrow(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) internal {
        _token.safeTransfer(_to,_amount);
    }
}