# Authorization-Governed Vault System

A secure, decentralized vault system for controlled asset withdrawals using Solidity smart contracts with authorization-based governance.

## Overview

This project implements a two-contract system that separates asset custody (vault) from permission validation (authorization manager). The vault contract holds and transfers funds, while the authorization manager contract validates withdrawal permissions.

## Architecture

### Smart Contracts

#### 1. AuthorizationManager.sol
- Validates withdrawal permissions
- Tracks authorization consumption to prevent reuse
- Encodes authorization scope (vault address, network, recipient, amount)
- External contract, does not hold funds

#### 2. SecureVault.sol
- Holds and manages blockchain native currency deposits
- Accepts deposits from any address
- Executes withdrawals only with valid authorizations
- Maintains accurate internal accounting
- Emits events for all state changes

## Key Features

- **Authorization-Based Governance**: Withdrawals require explicit authorization from an off-chain coordinator
- **Single-Use Authorizations**: Each authorization can only be consumed once
- **Deterministic Authorization Format**: Uses keccak256 hashing for consistent authorization encoding
- **Invariant Protection**: Prevents state corruption through careful order of operations
- **Full Observability**: Emits events for deposits, withdrawals, and authorization validation
- **Dockerized Deployment**: Complete setup with local blockchain and contract deployment

## Project Structure

```
.
├── contracts/
│   ├── AuthorizationManager.sol
│   └── SecureVault.sol
├── deploy.js
├── tests/
│   └── system.spec.js
├── docker/
│   ├── Dockerfile
│   └── entrypoint.sh
├── docker-compose.yml
├── hardhat.config.js
├── package.json
└── README.md
```

## Setup & Installation

### Prerequisites
- Docker and Docker Compose
- Node.js v16+ (for local development)
- npm or yarn

### Quick Start with Docker

```bash
# Clone the repository
git clone https://github.com/harshitha1246/authorization-governed-vault.git
cd authorization-governed-vault

# Build and run with Docker Compose
docker-compose up --build
```

This will:
1. Start a local Hardhat network
2. Compile smart contracts
3. Deploy AuthorizationManager and SecureVault
4. Output deployed contract addresses

### Local Development

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm test

# Deploy contracts
npm run deploy
```

## Usage Example

### 1. Deploy Contracts

Contracts are deployed automatically via `deploy.js` when running Docker Compose or:

```bash
npx hardhat run deploy.js --network localhost
```

### 2. Deposit Funds

```javascript
const tx = await vault.receive({ value: ethers.utils.parseEther("1.0") });
```

### 3. Request Authorization

Get an authorization signature from your off-chain coordinator:

```javascript
const authData = ethers.utils.solidityKeccak256(
  ["address", "uint256", "address", "uint256"],
  [vaultAddress, chainId, recipientAddress, withdrawAmount]
);
```

### 4. Withdraw Funds

```javascript
const tx = await vault.withdraw(
  recipientAddress,
  withdrawAmount,
  authorizationReference
);
```

## Authorization Flow

1. **User initiates withdrawal** by calling `vault.withdraw(recipient, amount, authRef)`
2. **Vault requests validation** from AuthorizationManager
3. **AuthorizationManager checks**:
   - Authorization hasn't been used before
   - Authorization scope matches request (vault, network, recipient, amount)
4. **Authorization consumed** on successful validation
5. **Funds transferred** to recipient
6. **Events emitted** for full auditability

## Security Considerations

### Invariants Protected
- Vault balance never becomes negative
- Each authorization can only effect one withdrawal
- Authorization scope is tightly bound to withdrawal parameters
- Internal accounting updated before external calls (Checks-Effects-Interactions)
- Initialization can only occur once

### Authorization Design
- Deterministic encoding prevents spoofing
- Unique authorization identifiers prevent reuse
- Explicit scope binding prevents authorization reinterpretation
- Off-chain generation allows flexible permission models

## Testing

Run the automated test suite:

```bash
npm test
```

Tests validate:
- Successful deposits and withdrawals
- Authorization consumption and reuse prevention
- Balance maintenance across operations
- Event emission correctness
- Failed authorization handling
- Edge cases and invariant violations

## Deployment

### Docker Deployment Output

When running `docker-compose up`, the deployment logs will show:

```
AuthorizationManager deployed at: 0x...
SecureVault deployed at: 0x...
Deployment completed successfully
```

These addresses are essential for interacting with the contracts.

## Common Mistakes to Avoid

1. **Allowing same authorization for multiple withdrawals** - Each authorization is single-use
2. **Transferring value before updating state** - Always update accounting first
3. **Failing to bind authorization scope** - Authorization must include vault, network, recipient, amount
4. **Insufficient initialization protection** - Use checks to prevent re-initialization
5. **Loose authorization encoding** - Use keccak256 with proper parameter types

## License

MIT

## Author

Harshitha Pasu
