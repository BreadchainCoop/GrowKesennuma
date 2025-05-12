// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Impactor.sol";
import "./Allowlist.sol";
import "./Disbursement.sol";

contract Governance {
    /* -------------------------------------------------------------------------- */
    /*                                   Types                                    */
    /* -------------------------------------------------------------------------- */

    struct Vote {
        uint256 impactorId;
        uint256 points;
        uint256 weight;
        uint256 epoch;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Storage                                   */
    /* -------------------------------------------------------------------------- */

    ImpactorRegistry public immutable impactorRegistry;
    Allowlist public immutable allowlist;
    address public immutable disbursement; // 1 to 1 linkage to Disbursement

    // user  => list of votes cast in the current epoch
    mapping(address => Vote[]) public userVotes;

    // impactorId => cumulative weight in current epoch
    mapping(uint256 => uint256) public totalVotes;

    // user  => last epoch in which they voted
    mapping(address => uint256) public lastVoteEpoch;

    uint256 public currentEpoch = 1;
    uint256 public maxPoints = 100; // per-impactor cap

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event VoteCast(address indexed voter, uint256[] impactorIds, uint256[] points, uint256 votingPower, uint256 epoch);

    event EpochIncremented(uint256 newEpoch);
    event VotesReset();
    event MaxPointsChanged(uint256 newMaxPoints);

    /* -------------------------------------------------------------------------- */
    /*                                 Modifiers                                  */
    /* -------------------------------------------------------------------------- */

    modifier onlyAllowlisted() {
        require(allowlist.isAllowlisted(msg.sender), "Governance: not allow-listed");
        _;
    }

    modifier onlyDisbursement() {
        require(msg.sender == disbursement, "Governance: caller not Disbursement");
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Constructor                                */
    /* -------------------------------------------------------------------------- */

    constructor(address _impactorRegistry, address _allowlist, address _disbursement) {
        require(
            _impactorRegistry != address(0) && _allowlist != address(0) && _disbursement != address(0),
            "Governance: zero address"
        );

        impactorRegistry = ImpactorRegistry(_impactorRegistry);
        allowlist = Allowlist(_allowlist);
        disbursement = _disbursement;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 Functions                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Cast / update your votes for the current epoch
    /// @dev    *All* previous votes are deleted first (prevents weight stacking).
    ///         `_impactorIds` **must** be strictly ascending to guarantee uniqueness.
    function vote(uint256[] calldata _impactorIds, uint256[] calldata _points) external onlyAllowlisted {
        uint256 len = _impactorIds.length;
        require(len == _points.length && len > 0, "Governance: bad array lengths");

        /* --------------------------- clear old votes -------------------------- */
        _removeVotes(msg.sender);

        /* ------------------------- calculate new votes ------------------------ */

        // Voting power could be token-based; hard-coded here for brevity
        uint256 votingPower = 10 ether;

        // 1. validate points & compute totalPoints
        uint256 totalPoints;
        for (uint256 i = 0; i < len; ++i) {
            require(_points[i] <= maxPoints, "Governance: points > max");
            totalPoints += _points[i];
        }
        require(totalPoints > 0, "Governance: totalPoints = 0");

        // 2. iterate once more to record votes
        Vote[] storage newVotes = userVotes[msg.sender];

        uint256 lastId = type(uint256).max; // used for strictly-ascending check
        for (uint256 i = 0; i < len; ++i) {
            uint256 id = _impactorIds[i];

            // uniqueness guard: IDs must be strictly ascending
            require(i == 0 || id > lastId, "Governance: duplicate or unsorted IDs");
            lastId = id;

            require(
                id < impactorRegistry.getImpactorCount() && impactorRegistry.impactorExists(id),
                "Governance: invalid impactor"
            );

            // weight = proportional share of votingPower
            uint256 weight = (_points[i] * votingPower) / totalPoints;
            require(weight > 0, "Governance: weight = 0");

            newVotes.push(Vote({impactorId: id, points: _points[i], weight: weight, epoch: currentEpoch}));

            totalVotes[id] += weight;
        }

        lastVoteEpoch[msg.sender] = currentEpoch;
        emit VoteCast(msg.sender, _impactorIds, _points, votingPower, currentEpoch);
    }

    /// @notice Called by Disbursement after it pays out to zero all tallies and start a new epoch
    function resetVotes() external onlyDisbursement {
        uint256 count = impactorRegistry.getImpactorCount();
        for (uint256 i = 0; i < count; ++i) {
            totalVotes[i] = 0;
        }
        ++currentEpoch;
        emit EpochIncremented(currentEpoch);
        emit VotesReset();
    }

    /* ------------------------------ Admin ops ------------------------------- */

    /// @notice Update the per-impactor points cap; callable by the Disbursement *owner*
    function setMaxPoints(uint256 _maxPoints) external {
        address owner = Disbursement(disbursement).owner();
        require(msg.sender == owner, "Governance: caller not owner");
        require(_maxPoints > 0, "Governance: maxPoints = 0");
        maxPoints = _maxPoints;
        emit MaxPointsChanged(_maxPoints);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Internal helpers                              */
    /* -------------------------------------------------------------------------- */

    /// @dev remove (and unweight) all votes of `user`
    function _removeVotes(address user) internal {
        Vote[] storage votes = userVotes[user];
        uint256 len = votes.length;

        for (uint256 i = 0; i < len; ++i) {
            uint256 id = votes[i].impactorId;
            uint256 weight = votes[i].weight;
            if (totalVotes[id] >= weight) totalVotes[id] -= weight;
        }

        delete userVotes[user];
    }

    /* -------------------------------------------------------------------------- */
    /*                               View helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice  Full vote objects cast by `_voter` in the current epoch
    function getVotesByUser(address _voter) external view returns (Vote[] memory) {
        return userVotes[_voter];
    }

    /// @notice  Total weighted votes accumulated for a given impactor in the
    ///          current epoch.  Used by Disbursement to calculate payouts.
    function getTotalVotes(uint256 _impactorId) external view returns (uint256) {
        return totalVotes[_impactorId];
    }
}
