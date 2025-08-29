// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./Common.sol";

contract TrussUser is Base {
    mapping(address => bool) private isRegistered; //is acc is registered
    mapping(address => bool) private isVerified; //is acc verified?
    mapping(address => uint256) private userIdToRecordIndex;

    // address payable escrowContract;

    User[] users;

    constructor() // address _escrowAddress
    // address _feddAddr //  address _adminDaoAddress
    {
        _disableInitializers();
    }

    function initialize(
        // address _escrowAddress,
        address initialOwner
    )
        public
        // address _feedAddr //  address _adminDaoAddress
        initializer
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
        string calldata _firstName,
        UserType _userType
    ) external {
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
            _userType,
            VerificationStatus.NotVerified
        );
        users.push(newUser);
        // uint dataindex = /;
        userIdToRecordIndex[msg.sender] = users.length - 1;
        emit ResgisteredAuser(userId);
    }

    function verifySeller(address _account) external onlyOwner {
        User storage userData = users[userIdToRecordIndex[_account]];
        require(userData.account == _account, "account mismatch");
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
    ) external view onlyOwner returns (User[] memory) {
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
        require(isRegistered[_account], "account not registered");
        User memory userData = users[userIdToRecordIndex[_account]];
        require(
            userData.account != address(0) && userData.account == _account,
            "Invalid user address or user not registered"
        );
        return userData;
    }
// token utility functions=========
    function addTokenToAcceptedList(
        address _tokenAddress,
        string memory _symbol,
        address _feedAddress
    ) external onlyOwner {
        if (keccak256(bytes(_symbol)) == keccak256(bytes("ETH"))) {
            address ethAddr = address(uint160(uint256(keccak256("ETH")))); //calculate address to use for eth
            isAccepted["ETH"] = true;
            tokenSymbolToDetails["ETH"] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: ethAddr
            });
        } else {
            isAccepted[_symbol] = true;
            tokenSymbolToDetails[_symbol] = Token({
                feedAddr: _feedAddress, // Set the feed address if needed
                tokenAddr: _tokenAddress
            });
        }

        // acceptedTokens.push(TokenDetails(_symbol,_tokenAddress));
    }

    function delistToken(string memory _symbol) external onlyOwner {
        require(isAccepted[_symbol], "invalid Token symbol");
        isAccepted[_symbol] = false;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
