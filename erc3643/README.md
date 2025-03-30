# ERC3643 for StarkNet

## Overview

This is a StarkNet implementation of the ERC3643 T-REX (Token for Regulated EXchanges) standard. This implementation enables compliant tokenization of financial assets on StarkNet while maintaining the regulatory compliance features of the ERC3643 standard.

## Features

- **Compliant Token**: Security tokens that meet regulatory requirements
- **Identity Management**: Manage investor identities and verification
- **Transfer Compliance**: Enforce transfer restrictions based on regulatory rules
- **Claim Verification**: Verify required claims for each identity
- **Forced Transfers**: Allow authorized agents to force transfer tokens
- **Recovery**: Support token recovery from lost addresses
- **Freezing**: Support freezing of tokens at address level

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

## Building and Testing

### Prerequisites

- [Scarb](https://docs.swmansion.com/scarb/)
- [StarkNet Foundry](https://foundry.paradigm.xyz/)

### Build

```bash
scarb build
```

### Test using StarkNet Foundry

The project uses [StarkNet Foundry](https://foundry.paradigm.xyz/) for testing, providing a robust testing framework for StarkNet contracts.

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

### Test Features

The testing framework leverages StarkNet Foundry's powerful features:

- **Contract Deployment**: Easily deploy and test contracts
- **Cheatcodes**: Manipulate the blockchain state during testing
  - `start_prank`: Spoof caller addresses
  - `spy_events`: Monitor emitted events
  - `start_warp`: Time manipulation
- **Fuzzing**: Automatically generate test inputs
- **Assertions**: Comprehensive assertion library

## Deployment

To deploy the contracts to StarkNet:

```bash
./scripts/deploy.sh [testnet|mainnet]
```

This will deploy all the necessary contracts in the correct order and configure them properly.

## License

This project is licensed under the MIT License - see the LICENSE file for details