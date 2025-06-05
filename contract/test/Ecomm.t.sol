// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Ecommerce} from "../src/Ecomm.sol";
import {Escrow} from "../src/Escrow.sol";

contract EcommTest is Test {
    Ecommerce public orja;
    Escrow public escrow;
    address constant deployer = address(0x5E1A7C6f994cb18d331c72EAc68768c6e2965ac6);
    address constant ecomAddr = address(0x347f276aa941a9c22f6840F641F5302de727624b);
    address constant escrowAddr = address(0xA1852B1b99569AFc1cf5854229292c68FebB36e1);
    address seller1;
    address buyer1;
    function setUp() public {
        // counter = new Counter();
        // counter.setNumber(0);
        vm.createSelectFork("sepolia");
        orja = Ecommerce(ecomAddr);
        escrow = Escrow(escrowAddr);
        seller1 = makeAddr("seller1");
        buyer1 = makeAddr("buyer1");
        // vm.prank(deployer);
        // escrow.setEcommercePlatform(ecomAddr);
    }


    function testRegisterAndVerifySeller() public {
        // Test user registration
        // uint256 userId = 1;
        string memory lastName = "Doe";
        string memory firstName = "John";
        address account = address(0x1234567890123456789012345678901234567890);
        
        orja.registerUser(userId, lastName, firstName, account);
        
        (uint256 registeredUserId, string memory registeredLastName, string memory registeredFirstName, address registeredAccount) = orja.getUserDetails(userId);
        
        assertEq(registeredUserId, userId);
        assertEq(registeredLastName, lastName);
        assertEq(registeredFirstName, firstName);
        assertEq(registeredAccount, account);
    }
    // function test_Increment() public {
    //     counter.increment();
    //     assertEq(counter.number(), 1);
    // }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }

}