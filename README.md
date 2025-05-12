# GrowKesennuma Smart Contracts

Smart contracts for managing impactor registration, voting, and fund disbursement in Kesennuma.

## Overview

This project consists of four main contracts:

1. `ImpactorRegistry`: Manages impactor registration and approval
2. `Allowlist`: Controls who can participate in voting
3. `Governance`: Handles voting for impactors
4. `Disbursement`: Manages fund distribution based on votes

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js and npm (for development tools)

## Setup

1. Clone the repository:
```bash
git clone https://github.com/your-username/GrowKesennuma.git
cd GrowKesennuma
```

2. Install dependencies:
```bash
forge install
```

3. Copy the environment file and fill in your values:
```bash
cp .env.example .env
```

## Testing

Run the test suite:
```bash
forge test
```

## Deployment

1. Set up your environment variables in `.env`:
   - `PRIVATE_KEY`: Your deployer account's private key (without 0x prefix)
   - `TOKEN_ADDRESS`: Address of the ERC20 token to use for disbursements
   - `RPC_URL`: RPC URL for the network you're deploying to

2. Deploy to a testnet:
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --verify
```

3. Deploy to mainnet:
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast --verify
```

## Contract Architecture

### ImpactorRegistry
- Manages impactor registration
- Handles impactor approval
- Stores impactor information

### Allowlist
- Controls access to voting
- Manages allowlist membership
- Handles ownership transfer

### Governance
- Manages voting for impactors
- Tracks vote weights
- Handles epoch management

### Disbursement
- Manages fund distribution
- Calculates proportional shares
- Tracks balances
