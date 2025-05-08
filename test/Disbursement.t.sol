// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Disbursement.sol";
import "../src/Governance.sol";
import "../src/Impactor.sol";
import "../src/Allowlist.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }
}

contract DisbursementTest is Test {
    Disbursement public disbursement;
    ImpactorRegistry public impactorRegistry;
    Governance public governance;
    Allowlist public allowlist;
    MockToken public token;
    
    address public owner;
    address public voter1;
    address public impactor1;
    address public impactor2;

    function setUp() public {
        owner = address(this);
        voter1 = address(0x1);
        impactor1 = address(0x2);
        impactor2 = address(0x3);

        token = new MockToken();
        impactorRegistry = new ImpactorRegistry();
        allowlist = new Allowlist();
        
        // Deploy Disbursement first with a temporary Governance address
        disbursement = new Disbursement(
            address(impactorRegistry),
            address(0), // Temporary Governance address
            address(token)
        );

        // Deploy Governance with the actual Disbursement address
        governance = new Governance(
            address(impactorRegistry),
            address(allowlist),
            address(disbursement)
        );

        // Update Disbursement with the actual Governance address
        disbursement.setGovernance(address(governance));

        // Setup impactors
        impactorRegistry.addImpactor(impactor1, "Impactor 1");
        impactorRegistry.addImpactor(impactor2, "Impactor 2");

        // Allowlist voter
        allowlist.allow(voter1);

        // Setup votes
        uint256[] memory impactorIds = new uint256[](2);
        uint256[] memory points = new uint256[](2);
        impactorIds[0] = 0;
        impactorIds[1] = 1;
        points[0] = 30;
        points[1] = 70;

        vm.prank(voter1);
        governance.vote(impactorIds, points);

        // Add funds
        token.approve(address(disbursement), 1000 * 10**token.decimals());
        disbursement.addFunds(1000 * 10**token.decimals());
    }

    function testDisburseFunds() public {
        disbursement.disburseFunds();
        
        // Check balances after disbursement
        uint256 impactor1Balance = token.balanceOf(impactor1);
        uint256 impactor2Balance = token.balanceOf(impactor2);
        
        // 30% to impactor1, 70% to impactor2
        assertEq(impactor1Balance, 300 * 10**token.decimals());
        assertEq(impactor2Balance, 700 * 10**token.decimals());
        assertEq(token.balanceOf(address(disbursement)), 0);
        assertEq(disbursement.totalFunds(), 0);
    }

    function test_RevertWhen_DisbursingWithNoFunds() public {
        disbursement.disburseFunds(); // First disbursement should succeed
        
        vm.expectRevert();
        disbursement.disburseFunds(); // Second disbursement should fail
    }

    function testTransferOwnership() public {
        address newOwner = address(0x5);
        disbursement.transferOwnership(newOwner);
        assertEq(disbursement.owner(), newOwner);
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        address newOwner = address(0x5);
        vm.prank(voter1);
        vm.expectRevert();
        disbursement.transferOwnership(newOwner);
    }
} 