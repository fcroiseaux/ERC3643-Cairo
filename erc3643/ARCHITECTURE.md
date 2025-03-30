# ERC3643 Project Architecture

This document provides an overview of the ERC3643 project architecture, which is a StarkNet implementation of the ERC3643 T-REX standard.

## Project Structure

```
erc3643/
├── Scarb.toml             # Project configuration file
├── src/                   # Source code directory
│   ├── lib.cairo          # Main module file
│   ├── token.cairo        # ERC3643 Token implementation
│   ├── identity_registry.cairo # Identity Registry implementation
│   ├── identity_storage.cairo  # Identity Storage implementation
│   ├── compliance.cairo        # Compliance implementation
│   ├── claim_topics_registry.cairo # Claim Topics Registry implementation
│   ├── trusted_issuers_registry.cairo # Trusted Issuers Registry implementation
│   ├── components/         # Reusable components directory
│   │   ├── erc3643.cairo   # ERC3643 token component
│   │   └── identity_registry.cairo
│   ├── examples/           # Example implementations
│   │   ├── erc3643_interface_example.cairo
│   │   └── erc3643_token.cairo
│   └── interfaces/         # Public interfaces
│       ├── ierc3643.cairo
│       ├── iidentity_registry.cairo
│       ├── iidentity_storage.cairo
│       ├── icompliance.cairo
│       ├── iclaim_topics_registry.cairo
│       └── itrusted_issuers_registry.cairo
├── tests/                 # Test directory
│   ├── test_token.cairo.bak
│   ├── test_compliance.cairo.bak
│   ├── test_comprehensive.cairo
│   ├── test_fixes.cairo
│   └── test_future.cairo
└── scripts/               # Deployment and utility scripts
    └── deploy.sh          # Deployment script
```

## Contract Relations

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

## Contracts Overview

### Token (ERC3643Token)

The ERC3643Token contract is the main contract representing the token itself. It extends ERC20 with additional regulatory compliance functionality:

- **Forced Transfer**: Authorized agents can force transfer tokens
- **Recovery**: Token recovery from lost addresses
- **Freezing**: Freezing tokens at address level
- **Compliance Checking**: Checks compliance before any transfer

### Identity Registry

The IdentityRegistry contract manages investor identities:

- Registers and updates investor identities
- Links identities to on-chain addresses
- Stores identity expiration dates
- Verifies identity claims against required claims

### Identity Storage

The IdentityStorage contract stores identity data:

- Stores the mapping between addresses and identities
- Manages multiple addresses per identity
- Stores country information
- Manages address expiration dates

### Compliance

The Compliance contract enforces transfer restrictions:

- Defines and enforces transfer rules
- Supports a modular rule system
- Validates transfers against all applicable rules

### Claim Topics Registry

The ClaimTopicsRegistry contract defines required claim topics:

- Manages required claim topics
- Allows adding/removing claim topics
- Allows querying required claims

### Trusted Issuers Registry

The TrustedIssuersRegistry contract manages trusted claim issuers:

- Manages trusted claim issuers
- Associates issuers with claim topics they can verify
- Allows checking if an issuer is trusted for a specific claim

## Flow of Operations

1. **Token Transfer**:
   - Token contract receives a transfer request
   - Token checks if sender and recipient are frozen
   - Token calls Identity Registry to verify identities
   - Token calls Compliance to check transfer compliance
   - If all checks pass, the transfer is executed

2. **Identity Verification**:
   - Identity Registry verifies an address by checking its identity
   - Identity Registry checks that the identity has all required claims
   - Identity Registry checks claim topics against the Claim Topics Registry
   - Identity Registry checks claim issuers against the Trusted Issuers Registry

3. **Compliance Check**:
   - Compliance contract executes all registered compliance rules
   - Each rule returns whether the transfer is compliant
   - If any rule fails, the transfer is not compliant