// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Impactor.sol";
import "./Allowlist.sol";

contract Governance {
    struct Vote {
        uint256 impactorId;
        uint256 points;
        uint256 weight;
        uint256 epoch;
    }

    ImpactorRegistry public impactorRegistry;
    Allowlist public allowlist;
    address public immutable disbursement;
    
    mapping(address => Vote[]) public userVotes;
    mapping(uint256 => uint256) public totalVotes;
    mapping(address => uint256) public lastVoteEpoch;
    uint256 public currentEpoch;
    uint256 public maxPoints;
    
    event VoteCast(address indexed voter, uint256[] impactorIds, uint256[] points, uint256 votingPower, uint256 epoch);
    event EpochIncremented(uint256 newEpoch);
    event VotesReset();

    constructor(
        address _impactorRegistry,
        address _allowlist,
        address _disbursement
    ) {
        require(_disbursement != address(0), "Invalid disbursement address");
        impactorRegistry = ImpactorRegistry(_impactorRegistry);
        allowlist = Allowlist(_allowlist);
        disbursement = _disbursement;
        maxPoints = 100; // Default max points per impactor
        currentEpoch = 1;
    }

    modifier onlyAllowlisted() {
        require(allowlist.isAllowlisted(msg.sender), "User not allowlisted");
        _;
    }

    modifier onlyDisbursement() {
        require(msg.sender == disbursement, "Only disbursement can call this function");
        _;
    }

    function vote(uint256[] calldata _impactorIds, uint256[] calldata _points) external onlyAllowlisted {
        require(_impactorIds.length == _points.length, "Arrays length mismatch");
        require(_impactorIds.length > 0, "Empty arrays");
        
        // Get user's voting power (for now just using 1, but could be based on token balance or other factors)
        uint256 votingPower = 10e18;

        // Remove all previous votes if they're from a previous epoch
        if (lastVoteEpoch[msg.sender] < currentEpoch) {
            Vote[] storage votes = userVotes[msg.sender];
            for (uint256 i = 0; i < votes.length; i++) {
                if (totalVotes[votes[i].impactorId] >= votes[i].weight) {
                    totalVotes[votes[i].impactorId] -= votes[i].weight;
                }
            }
            delete userVotes[msg.sender];
        }

        // Calculate total points
        uint256 totalPoints;
        for (uint256 i = 0; i < _points.length; i++) {
            require(_points[i] <= maxPoints, "Points exceed maximum");
            totalPoints += _points[i];
        }
        require(totalPoints > 0, "Total points must be greater than 0");

        // Add new votes
        Vote[] storage votes = userVotes[msg.sender];
        for (uint256 i = 0; i < _impactorIds.length; i++) {
            require(_impactorIds[i] < impactorRegistry.getImpactorCount(), "Invalid impactor ID");
            require(impactorRegistry.impactorExists(_impactorIds[i]), "Impactor not approved");
            
            // Calculate weight based on points and voting power
            uint256 weight = (_points[i] * votingPower * 1e18) / totalPoints / 1e18;
            
            votes.push(Vote({
                impactorId: _impactorIds[i],
                points: _points[i],
                weight: weight,
                epoch: currentEpoch
            }));
            totalVotes[_impactorIds[i]] += weight;
        }

        lastVoteEpoch[msg.sender] = currentEpoch;
        emit VoteCast(msg.sender, _impactorIds, _points, votingPower, currentEpoch);
    }

    function resetVotes() external onlyDisbursement {
        // Clear total votes
        uint256 impactorCount = impactorRegistry.getImpactorCount();
        for (uint256 i = 0; i < impactorCount; i++) {
            totalVotes[i] = 0;
        }
        currentEpoch++;
        emit EpochIncremented(currentEpoch);
        emit VotesReset();
    }

    function getVotesByUser(address _voter) external view returns (Vote[] memory) {
        return userVotes[_voter];
    }

    function getTotalVotes(uint256 _impactorId) external view returns (uint256) {
        return totalVotes[_impactorId];
    }

    function setMaxPoints(uint256 _maxPoints) external {
        require(_maxPoints > 0, "Max points must be greater than 0");
        maxPoints = _maxPoints;
    }
} 