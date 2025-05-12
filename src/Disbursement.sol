// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Impactor.sol";
import "./Governance.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Disbursement {
    ImpactorRegistry public impactorRegistry;
    Governance public governance;
    IERC20 public token;
    address public owner;

    mapping(uint256 => uint256) public balances;
    uint256 public totalFunds;

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
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        totalFunds += _amount;
        emit FundsAdded(_amount);
    }

    function disburseFunds() external {
        require(totalFunds > 0, "No funds available");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No funds to disburse");

        uint256 impactorCount = impactorRegistry.getImpactorCount();
        require(impactorCount > 0, "No impactors registered");

        uint256 totalVotes;
        uint256[] memory impactorIds = new uint256[](impactorCount);
        uint256[] memory amounts = new uint256[](impactorCount);

        // Calculate total votes and prepare arrays
        for (uint256 i = 0; i < impactorCount; i++) {
            impactorIds[i] = i;
            uint256 votes = governance.getTotalVotes(i);
            totalVotes += votes;
            amounts[i] = votes;
        }

        require(totalVotes > 0, "No votes cast");

        // Disburse funds proportionally to votes
        for (uint256 i = 0; i < impactorCount; i++) {
            if (amounts[i] > 0) {
                // Calculate amount with higher precision to avoid rounding errors
                uint256 amount = (balance * amounts[i] * 1e18) / totalVotes;
                amount = amount / 1e18; // Scale back down after division

                (address impactorWallet,) = impactorRegistry.getImpactor(i);
                require(token.transfer(impactorWallet, amount), "Transfer failed");
                amounts[i] = amount;
            }
        }

        emit FundsDisbursed(balance, impactorIds, amounts);

        // Reset votes after disbursement
        governance.resetVotes();

        totalFunds = 0;
    }

    function setGovernance(address _governance) external onlyOwner {
        require(_governance != address(0), "Invalid governance address");
        governance = Governance(_governance);
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Only owner can call this function");
        require(_newOwner != address(0), "Invalid new owner address");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}
