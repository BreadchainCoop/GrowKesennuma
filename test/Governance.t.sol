// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Governance.sol";
import "../src/Impactor.sol";
import "../src/Allowlist.sol";

contract MockDisbursement {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

contract GovernanceTest is Test {
    Governance public governance;
    ImpactorRegistry public impactorRegistry;
    Allowlist public allowlist;
    MockDisbursement public disbursement;

    address public owner;
    address public voter1;
    address public voter2;
    address public impactor1;
    address public impactor2;

    function setUp() public {
        owner = address(this);
        voter1 = address(0x1);
        voter2 = address(0x2);
        impactor1 = address(0x3);
        impactor2 = address(0x4);

        impactorRegistry = new ImpactorRegistry();
        allowlist = new Allowlist();
        disbursement = new MockDisbursement(owner);
        governance = new Governance(address(impactorRegistry), address(allowlist), address(disbursement));

        // Setup impactors
        impactorRegistry.addImpactor(impactor1, "Impactor 1");
        impactorRegistry.addImpactor(impactor2, "Impactor 2");

        // Allowlist voters
        allowlist.allow(voter1);
        allowlist.allow(voter2);
    }

    function testVote() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        points[0] = 100;

        vm.prank(voter1);
        governance.vote(impactorIds, points);

        Governance.Vote[] memory votes = governance.getVotesByUser(voter1);
        assertEq(votes.length, 1);
        assertEq(votes[0].impactorId, 0);
        assertEq(votes[0].points, 100);
        assertEq(votes[0].weight, 10e18); // Full weight since it's the only vote
        assertEq(governance.getTotalVotes(0), 10e18);
    }

    function testUpdateVote() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        points[0] = 50;

        vm.prank(voter1);
        governance.vote(impactorIds, points);

        points[0] = 100;
        vm.prank(voter1);
        governance.vote(impactorIds, points);

        Governance.Vote[] memory votes = governance.getVotesByUser(voter1);
        assertEq(votes.length, 1);
        assertEq(votes[0].impactorId, 0);
        assertEq(votes[0].points, 100);
        assertEq(votes[0].weight, 10e18);
        assertEq(governance.getTotalVotes(0), 10e18);
    }

    function testMultipleVotes() public {
        uint256[] memory impactorIds = new uint256[](2);
        uint256[] memory points = new uint256[](2);
        impactorIds[0] = 0;
        impactorIds[1] = 1;
        points[0] = 30;
        points[1] = 70;

        vm.prank(voter1);
        governance.vote(impactorIds, points);

        Governance.Vote[] memory votes = governance.getVotesByUser(voter1);
        assertEq(votes.length, 2);
        assertEq(votes[0].points, 30);
        assertEq(votes[1].points, 70);
        assertEq(votes[0].weight, 3e18); // 30% of voting power
        assertEq(votes[1].weight, 7e18); // 70% of voting power
        assertEq(governance.getTotalVotes(0), 3e18);
        assertEq(governance.getTotalVotes(1), 7e18);
    }

    function test_RevertWhen_NonAllowlistedUserVotes() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        points[0] = 100;

        address nonAllowlisted = address(0x5);
        vm.prank(nonAllowlisted);
        vm.expectRevert("Governance: not allow-listed");
        governance.vote(impactorIds, points);
    }

    function test_RevertWhen_VotingForInvalidImpactor() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 999; // Non-existent impactor ID
        points[0] = 100;

        vm.prank(voter1);
        vm.expectRevert("Governance: invalid impactor");
        governance.vote(impactorIds, points);
    }

    function test_RevertWhen_PointsExceedMaximum() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        points[0] = governance.maxPoints() + 1;

        vm.prank(voter1);
        vm.expectRevert("Governance: points > max");
        governance.vote(impactorIds, points);
    }

    function test_RevertWhen_ArraysLengthMismatch() public {
        uint256[] memory impactorIds = new uint256[](2);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        impactorIds[1] = 1;
        points[0] = 100;

        vm.prank(voter1);
        vm.expectRevert("Governance: bad array lengths");
        governance.vote(impactorIds, points);
    }

    function test_RevertWhen_EmptyArrays() public {
        uint256[] memory impactorIds = new uint256[](0);
        uint256[] memory points = new uint256[](0);

        vm.prank(voter1);
        vm.expectRevert("Governance: bad array lengths");
        governance.vote(impactorIds, points);
    }

    function test_RevertWhen_ZeroTotalPoints() public {
        uint256[] memory impactorIds = new uint256[](1);
        uint256[] memory points = new uint256[](1);
        impactorIds[0] = 0;
        points[0] = 0;

        vm.prank(voter1);
        vm.expectRevert("Governance: totalPoints = 0");
        governance.vote(impactorIds, points);
    }

    function testSetMaxPoints() public {
        uint256 newMaxPoints = 200;
        vm.prank(Disbursement(address(disbursement)).owner());
        governance.setMaxPoints(newMaxPoints);
        assertEq(governance.maxPoints(), newMaxPoints);
    }

    function testResetVotes() public {
        // First cast some votes
        uint256[] memory impactorIds = new uint256[](2);
        uint256[] memory points = new uint256[](2);
        impactorIds[0] = 0;
        impactorIds[1] = 1;
        points[0] = 30;
        points[1] = 70;

        vm.prank(voter1);
        governance.vote(impactorIds, points);

        // Verify votes are recorded
        assertEq(governance.getTotalVotes(0), 3e18); // 30% of 10e18
        assertEq(governance.getTotalVotes(1), 7e18); // 70% of 10e18
        assertEq(governance.currentEpoch(), 1);

        // Reset votes
        vm.prank(address(disbursement));
        governance.resetVotes();

        // Verify votes are cleared and epoch is incremented
        assertEq(governance.getTotalVotes(0), 0);
        assertEq(governance.getTotalVotes(1), 0);
        assertEq(governance.currentEpoch(), 2);

        // Verify user can vote again in new epoch
        vm.prank(voter1);
        governance.vote(impactorIds, points);
        assertEq(governance.getTotalVotes(0), 3e18);
        assertEq(governance.getTotalVotes(1), 7e18);
    }
}
