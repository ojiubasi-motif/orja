// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./Common.sol";
import { TrussUserv1 } from "@src/v1/User.sol"; 

contract TrussUser is TrussUserv1 {
    // mapping(address => bool) private isRegistered; //is acc is registered
    // mapping(address => bool) private isVerified; //is acc verified?
    

    // address payable escrowContract;

    // User[] users;

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function initializev2(
        // address _escrowAddress,
        address initialOwner
    )
        external
        // address _feedAddr //  address _adminDaoAddress
        reinitializer(3)
    {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        // require(_escrowAddress != address(0), "Invalid ESCROW address");
        // escrowContract = payable(_escrowAddress);
    }

    function _generateUserId(
        string calldata _lastName,
        string calldata _firstName,
        address _userAcc
    ) private view returns (uint32 id) {
        // uint256 id;
        id = uint32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _lastName,
                        _firstName,
                        _userAcc,
                        block.timestamp
                    )
                )
            )
        );
        // return id;
    }

    function register(
        string calldata _lastName,
        string calldata _firstName
    ) external // UserType _userType
    {
        require(msg.sender != address(0), "Invalid address");
        require(
            !isRegistered[msg.sender],
            "Address Already assigned to a user"
        );
        isRegistered[msg.sender] = true;
        User memory newUser;
        uint256 userId = _generateUserId(_lastName, _firstName, msg.sender);
        newUser = User(
            userId,
            _lastName,
            _firstName,
            msg.sender,
            // _userType,
            VerificationStatus.NotVerified
        );
        users.push(newUser);
        // uint dataindex = /;
        userToRecordIndex[msg.sender] = users.length - 1;
        emit ResgisteredAuser(userId, msg.sender);
    }

    // function ch
    function verifySeller(address _account) external onlyAdmins {
        require(_account != address(0), "not a valid account");
        User storage userData = users[userToRecordIndex[_account]];
        require(userData.account == _account, "account mismatch"); //this ensures address is registered
        require(
            !isVerified[userData.account],
            "this seller is already Verified!"
        );
        isVerified[userData.account] = true;
        userData.verificationStatus = VerificationStatus.Verified;
        emit VerifiedAuser(userData.userId);
    }

    function getUsers(
        uint _start,
        uint _end
    ) external view onlyAdmins returns (User[] memory) {
        // require(_start < _end, "Invalid range");
        require(_end < users.length, "End index out of bounds");
        require(
            _start <= _end && _end - _start <= 500,
            "Invalid range and/or range shouldn't be bigger than 500"
        );
        User[] memory fetchedUsers = new User[](
            _start == _end ? 1 : (_end - _start) + 1
        );

        for (uint i = 0; i < fetchedUsers.length; i++) {
            fetchedUsers[i] = users[i + _start];
        }
        // User[] memory users = new User[](_end - _start);
        return fetchedUsers;
    }

    function getUserData(address _account) public view returns (User memory) {
        require(users.length > 0, "users array empty");
        User memory userData = users[userToRecordIndex[_account]];
        return
            userData.account == _account
                ? userData
                : User(0, "", "", address(0), VerificationStatus.NotVerified);
    }

    modifier onlyAdmins() {
        require(
            msg.sender == owner() ||
                msg.sender ==
                address(0x56c92833A4A3dac0E7d8b56c31e3Fd52B5dEC856),
            "only admin can call this function"
        );
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
