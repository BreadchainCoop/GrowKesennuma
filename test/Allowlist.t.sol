// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Allowlist.sol";

contract AllowlistTest is Test {
    Allowlist public allowlist;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        allowlist = new Allowlist();
    }

    function testAllowUser() public {
        allowlist.allow(user1);
        assertTrue(allowlist.isAllowlisted(user1));
    }

    function testBatchAllow() public {
        address[] memory users = new address[](2);
        users[0] = user1;
        users[1] = user2;

        allowlist.batchAllow(users);
        assertTrue(allowlist.isAllowlisted(user1));
        assertTrue(allowlist.isAllowlisted(user2));
    }

    function testTransferOwnership() public {
        allowlist.transferOwnership(user1);
        assertEq(allowlist.owner(), user1);
    }

    function test_RevertWhen_AllowingZeroAddress() public {
        vm.expectRevert("Invalid user address");
        allowlist.allow(address(0));
    }

    function test_RevertWhen_AllowingAlreadyAllowedUser() public {
        allowlist.allow(user1);
        vm.expectRevert("User already allowed");
        allowlist.allow(user1);
    }

    function test_RevertWhen_TransferringOwnershipToZeroAddress() public {
        vm.expectRevert("Invalid new owner address");
        allowlist.transferOwnership(address(0));
    }

    function test_RevertWhen_NonOwnerAllowsUser() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        allowlist.allow(user2);
    }

    function test_RevertWhen_NonOwnerBatchAllowsUsers() public {
        address[] memory users = new address[](1);
        users[0] = user2;

        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        allowlist.batchAllow(users);
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        vm.prank(user1);
        vm.expectRevert("Only owner can call this function");
        allowlist.transferOwnership(user2);
    }
}
