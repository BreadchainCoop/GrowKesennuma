// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Impactor.sol";

contract ImpactorTest is Test {
    ImpactorRegistry public impactorRegistry;
    address public owner;
    address public impactor1;
    address public impactor2;

    function setUp() public {
        owner = address(this);
        impactor1 = address(0x1);
        impactor2 = address(0x2);
        impactorRegistry = new ImpactorRegistry();
    }

    function testAddImpactor() public {
        uint256 id = impactorRegistry.addImpactor(impactor1, "Test Impactor");
        assertEq(id, 0);
        assertEq(impactorRegistry.getImpactorCount(), 1);

        (address wallet, string memory name) = impactorRegistry.getImpactor(id);
        assertEq(wallet, impactor1);
        assertEq(name, "Test Impactor");
    }

    function testGetImpactor() public {
        uint256 id = impactorRegistry.addImpactor(impactor1, "Test Impactor");
        (address wallet, string memory name) = impactorRegistry.getImpactor(id);
        assertEq(wallet, impactor1);
        assertEq(name, "Test Impactor");
    }

    function testGetImpactorCount() public {
        assertEq(impactorRegistry.getImpactorCount(), 0);
        impactorRegistry.addImpactor(impactor1, "Test Impactor 1");
        assertEq(impactorRegistry.getImpactorCount(), 1);
        impactorRegistry.addImpactor(impactor2, "Test Impactor 2");
        assertEq(impactorRegistry.getImpactorCount(), 2);
    }

    function test_RevertWhen_GettingInvalidImpactor() public {
        vm.expectRevert("Invalid impactor ID");
        impactorRegistry.getImpactor(0);
    }

    function test_RevertWhen_AddingImpactorWithZeroAddress() public {
        vm.expectRevert("Invalid wallet address");
        impactorRegistry.addImpactor(address(0), "Test Impactor");
    }

    function test_RevertWhen_AddingImpactorWithEmptyName() public {
        vm.expectRevert("Name cannot be empty");
        impactorRegistry.addImpactor(impactor1, "");
    }
}
