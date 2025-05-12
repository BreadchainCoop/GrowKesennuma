// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Impactor.sol";
import "./Governance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Disbursement {
    using SafeERC20 for IERC20;

    ImpactorRegistry public impactorRegistry;
    Governance public governance;
    IERC20 public token;
    address public owner;

    mapping(uint256 => uint256) public balances;
    uint256 public totalFunds;
    uint256 public constant MAX_IMPACTORS = 1000;

    event FundsAdded(uint256 amount);
    event FundsDisbursed(uint256 totalAmount, uint256[] impactorIds, uint256[] amounts);
    event OwnerChanged(address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _impactorRegistry, address _governance, address _token) {
        impactorRegistry = ImpactorRegistry(_impactorRegistry);
        governance = Governance(_governance);
        token = IERC20(_token);
        owner = msg.sender;
    }

    function addFunds(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        totalFunds += _amount;
        emit FundsAdded(_amount);
    }

    function disburseFunds() external {
        require(totalFunds > 0, "No funds available");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to disburse");

        uint256 impactorCount = impactorRegistry.getImpactorCount();
        require(impactorCount > 0, "No impactors registered");
        require(impactorCount <= MAX_IMPACTORS, "Too many impactors");

        totalFunds = 0;

        uint256 totalVotes;
        uint256[] memory impactorIds = new uint256[](impactorCount);
        uint256[] memory amounts = new uint256[](impactorCount);

        for (uint256 i = 0; i < impactorCount; i++) {
            impactorIds[i] = i;
            uint256 votes = governance.getTotalVotes(i);
            totalVotes += votes;
            amounts[i] = votes;
        }

        require(totalVotes > 0, "No votes cast");

        for (uint256 i = 0; i < impactorCount; i++) {
            if (amounts[i] > 0) {
                uint256 amount = (balance * amounts[i] * 1e18) / totalVotes;
                amount = amount / 1e18;

                (address impactorWallet,) = impactorRegistry.getImpactor(i);
                token.safeTransfer(impactorWallet, amount);
                amounts[i] = amount;
            }
        }

        emit FundsDisbursed(balance, impactorIds, amounts);

        governance.resetVotes();
    }

    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "Invalid governance address");
        require(Governance(_governance).disbursement() == address(this), "Governance mismatch");
        governance = Governance(_governance);
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only owner can call this function");
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}
