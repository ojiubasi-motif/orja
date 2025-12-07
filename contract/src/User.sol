// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@src/Common.sol";

contract TrussUser is Base {
    bytes32 private constant USER_STORAGE_SLOT = keccak256("erc7575.user.storage");

    struct UserStorage {
        uint256 _refCounter;
        mapping(address => bool) isRegistered; //is acc is registered
        mapping(address => bool) isVerified; //is acc verified?
        mapping(address => uint256) userToRecordIndex;
        User[] users;
        mapping(address => bool) isAdmin;
        address[] admins;
    }

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function _getUserStorage()
        private
        pure
        returns (UserStorage storage $)
    {
        bytes32 slot = USER_STORAGE_SLOT;
        assembly {
            $.slot := slot
        }
    }

    function initializev2(
        // address _escrowAddress,
        address initialOwner
    )
        external
        // initializer
        reinitializer(4)
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
    ) private returns (uint32 id) {
        // uint256 id;
        UserStorage storage $ = _getUserStorage();
        $._refCounter++;

        id = uint32(
            uint256(
                keccak256(
                    abi.encodePacked(
                        $._refCounter,
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
        string calldata _firstName // UserType _userType
    ) external {
        require(msg.sender != address(0), "Invalid address");
        UserStorage storage $ = _getUserStorage();
        require(
            !$.isRegistered[msg.sender],
            "Address Already assigned to a user"
        );
        $.isRegistered[msg.sender] = true;
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
        $.users.push(newUser);
        // uint dataindex = /;
        $.userToRecordIndex[msg.sender] = $.users.length - 1;
        emit ResgisteredAuser(userId, msg.sender);
    }

    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "not a valid account");
        UserStorage storage $ = _getUserStorage();
        require(!$.isAdmin[_admin], "already an admin");
        $.isAdmin[_admin] = true;
        $.admins.push(_admin);
    }

    // function ch
    function verifySeller(address _account) external onlyAdmins {
        require(_account != address(0), "not a valid account");
        UserStorage storage $ = _getUserStorage();
        User storage userData = $.users[$.userToRecordIndex[_account]];
        require(userData.account == _account, "account mismatch"); //this ensures address is registered
        require(
            !$.isVerified[userData.account],
            "this seller is already Verified!"
        );
        $.isVerified[userData.account] = true;
        userData.verificationStatus = VerificationStatus.Verified;
        emit VerifiedAuser(userData.userId);
    }

    function getUsers(
        uint _start,
        uint _end
    ) external view onlyAdmins returns (User[] memory) {
        UserStorage storage $ = _getUserStorage();
        require($.users.length > 0, "users array empty");
        require(
            _start <= _end && _end - _start <= 100,
            "you cannot fetch more than 100 products at once, and  start must not be greater than end"
        );
        uint256 _lastIndex = _end > $.users.length - 1 ? $.users.length - 1 : _end;
        uint256 _startIndex = _start > _lastIndex ? _lastIndex : _start;
        
        if ($.users.length <= 100) {
            _lastIndex = $.users.length - 1;
            _startIndex = _startIndex <= _lastIndex ? _startIndex : _lastIndex;
        }
        User[] memory fetchedUsers = new User[](
            _startIndex == _lastIndex ? 1 : (_lastIndex - _startIndex) + 1
        );

        for (uint i = 0; i < fetchedUsers.length; i++) {
            fetchedUsers[i] = $.users[i + _startIndex];
        }

        return fetchedUsers;
    }

    function getUserData(address _account) public view returns (User memory) {
        UserStorage storage $ = _getUserStorage();
        require($.users.length > 0, "users array empty");
        User memory userData = $.users[$.userToRecordIndex[_account]];
        return
            userData.account == _account
                ? userData
                : User(0, "", "", address(0), VerificationStatus.NotVerified);
    }

    modifier onlyAdmins() {
        UserStorage storage $ = _getUserStorage();
        require(
            msg.sender == owner() || $.isAdmin[msg.sender],
            "only admin can call this function"
        );
        _;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
