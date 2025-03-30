# ERC3643 on StarkNet

## Overview

This project provides a StarkNet implementation of the ERC3643 T-REX (Token for Regulated EXchanges) standard. It enables the compliant tokenization of financial assets on StarkNet while maintaining the regulatory compliance features of the ERC3643 standard.

## What is ERC3643?

ERC3643 is a token standard for regulated exchanges that extends ERC20 with identity management, compliance rules, forced transfers, and other features required for securities tokens. This implementation provides all the necessary components to create compliant security tokens on StarkNet.

## Key Features

- **Regulatory Compliance**: Security tokens that meet regulatory requirements
- **Identity Management**: Manage investor identities with verification
- **Transfer Compliance**: Enforce transfer restrictions based on regulatory rules
- **Claim Verification**: Verify required claims for each identity
- **Forced Transfers**: Allow authorized agents to force transfer tokens
- **Recovery**: Support token recovery from lost addresses
- **Freezing**: Ability to freeze tokens at address level

## Components

The implementation consists of several interconnected components:

1. **Token**: The main contract representing the token itself
2. **Identity Registry**: Manages investor identities
3. **Identity Storage**: Stores identity data
4. **Compliance**: Enforces transfer restrictions based on regulatory requirements
5. **Claim Topics Registry**: Defines required identity claims
6. **Trusted Issuers Registry**: Manages trusted identity verifiers

### Library Organization

The codebase is organized into:

- **Interfaces**: Standardized interfaces for all components (`src/interfaces/`)
- **Core Components**: Reusable component implementations (`src/components/`)
- **Examples**: Reference implementations for quick start (`src/examples/`)
- **Tests**: Comprehensive test suite (`tests/`)

## Architecture

```
┌─────────────────┐           ┌───────────────────┐          ┌────────────────────┐
│     Token       │◄─────────►│  IdentityRegistry │◄────────►│ ClaimTopicsRegistry│
└────────┬────────┘           └─────────┬─────────┘          └────────────────────┘
         │                              │                               ▲
         │                              │                               │
         ▼                              ▼                               │
┌─────────────────┐           ┌───────────────────┐          ┌────────────────────┐
│  Compliance     │           │ IdentityStorage   │◄────────►│TrustedIssuersRegistry│
└─────────────────┘           └───────────────────┘          └────────────────────┘
```

## Getting Started

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/) - Cairo package manager
- [StarkNet Foundry](https://foundry.paradigm.xyz/) - Testing framework for StarkNet

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/erc3643.git
   cd erc3643
   ```

2. Build the project:
   ```bash
   scarb build
   ```

3. Run tests:
   ```bash
   snforge test
   ```

## Usage

To deploy a new ERC3643 token on StarkNet, use the deployment script:

```bash
./scripts/deploy.sh [testnet|mainnet]
```

This will deploy all necessary contracts (Token, Identity Registry, Compliance, etc.) in the correct order and configure them properly.

## Testing

The project uses [StarkNet Foundry](https://foundry.paradigm.xyz/) for testing. To run tests:

```bash
# Run all tests
snforge test

# Run a specific test
snforge test test_token_initialization

# Run tests with a specific filter
snforge test test_compliance

# Run comprehensive test suite
snforge test test_comprehensive
```

The testing framework includes:
- **Comprehensive tests**: End-to-end testing of all components
- **Unit tests**: Testing individual contract functions
- **Integration tests**: Testing interactions between contracts
- **Testing utilities**: Using StarkNet Foundry's cheatcodes for state manipulation

## License

This project is licensed under the MIT License - see the [LICENSE](./erc3643/LICENSE) file for details.

## Acknowledgments

- [ERC-3643 Standard](https://eips.ethereum.org/EIPS/eip-3643)
- [T-REX Protocol](https://github.com/TokenySolutions/T-REX)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)