// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Impactor.sol";
import "../src/Allowlist.sol";
import "../src/Governance.sol";
import "../src/Disbursement.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy core contracts
        ImpactorRegistry impactorRegistry = new ImpactorRegistry();
        Allowlist allowlist = new Allowlist();
        
        // Deploy Disbursement first with a temporary Governance address
        Disbursement disbursement = new Disbursement(
            address(impactorRegistry),
            address(0), // Temporary Governance address
            0xa555d5344f6FB6c65da19e403Cb4c1eC4a1a5Ee3 // USDC token address
        );

        // Deploy Governance with the actual Disbursement address
        Governance governance = new Governance(
            address(impactorRegistry),
            address(allowlist),
            address(disbursement)
        );

        // Update Disbursement with the actual Governance address
        disbursement.setGovernance(address(governance));

        vm.stopBroadcast();

        // Log deployed addresses
        console.log("ImpactorRegistry deployed to:", address(impactorRegistry));
        console.log("Allowlist deployed to:", address(allowlist));
        console.log("Disbursement deployed to:", address(disbursement));
        console.log("Governance deployed to:", address(governance));
    }
} 