// SPDX-License-Identifier: GPL-3.0
import "../Common.sol";

pragma solidity >=0.8.26;
 
interface IShop {
   
    // function userCheckoutAmount(uint256 _payRef) external view returns (uint256);
    
   

    function getCart(
        uint256 _user
    ) external view returns (OrderItem[] memory);
    // @dev=NB: public mappings are by default getter functions so no need to define exclusive getters for them
    // function tokenSymbolToDetails(
    //     string memory _symbol
    // ) external view returns (Token memory tokenDetails);
}

interface IUser {
    function getUserData(
        address _account
    ) external view returns (User memory _userData);

    function getUsers(
        uint _start,
        uint _end
    ) external view returns (User[] memory);

    function register(
        string calldata _lastName,
        string calldata _firstName,
        UserType _userType
    ) external;

    function verifySeller(address _account) external;

}

interface IProduct{

     function getProductData(
        uint256 _productId
    ) external view  returns (Product memory);
    //  function getProductData(
    //     uint256 _productId
    // ) external view returns (Product memory);
}