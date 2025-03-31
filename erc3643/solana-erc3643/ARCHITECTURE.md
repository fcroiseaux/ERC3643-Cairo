# Solana ERC3643 Architecture

This document describes the architecture of the ERC3643 (T-REX) implementation for the Solana blockchain.

## Overview

The ERC3643 standard provides a framework for tokenized securities with built-in regulatory compliance features. This implementation for Solana follows the same principles while adapting to Solana's account-based model.

## Core Components

### Token Program

The main ERC3643 token program implements:

- Standard token functionality (transfer, mint, burn)
- Regulatory features (forced transfers, freezing, recovery)
- Agent management
- Integration with identity and compliance

### Account Structure

The implementation uses the following account types:

1. **Token Account**: Contains the token metadata, including name, symbol, supply, and references to identity registry and compliance.
2. **Token Holder Account**: Stores token balances for individual holders.
3. **Identity Registry Account**: Manages verifications and links to identity storage.
4. **Identity Storage Account**: Stores identity data and country information.
5. **Compliance Account**: Contains compliance rules and checks.
6. **Claim Topics Registry Account**: Defines required claim topics.
7. **Trusted Issuers Registry Account**: Maintains a list of trusted identity issuers.

### Data Model

#### Token Account Data

```
struct Token {
    is_initialized: bool,
    owner: Pubkey,
    name: String,
    symbol: String,
    decimals: u8,
    supply: u64,
    is_paused: bool,
    identity_registry: Pubkey,
    compliance: Pubkey,
}
```

#### Token Holder Account Data

```
struct TokenAccount {
    is_initialized: bool,
    token: Pubkey,
    owner: Pubkey,
    amount: u64,
    state: u8,  // Flags like FROZEN
}
```

#### Identity Registry Data

```
struct IdentityRegistry {
    is_initialized: bool,
    owner: Pubkey,
    identity_storage: Pubkey,
    trusted_issuers_registry: Pubkey,
    claim_topics_registry: Pubkey,
}
```

#### Identity Data

```
struct Identity {
    is_initialized: bool,
    owner: Pubkey,
    identity_hash: [u8; 32],
    country: u16,
}
```

## Workflow

### Token Creation and Management

1. **Initialize Token**: Create the token with parameters and link to identity registry and compliance.
2. **Agent Management**: Add or remove agents (entities with special permissions).
3. **Pause/Unpause**: Temporarily halt all transfers if needed.

### Identity Management

1. **Register Identity**: Associate an address with an identity and country.
2. **Verify Identity**: Check identity against trusted issuers and required claim topics.
3. **Update/Delete Identity**: Modify or remove identity information.

### Transfer Workflow

1. **Verify Identities**: Ensure both sender and receiver have verified identities.
2. **Check Compliance**: Validate the transfer against compliance rules.
3. **Check Freezing**: Ensure neither account is frozen.
4. **Check Pause Status**: Ensure the token is not paused.
5. **Execute Transfer**: Move tokens from sender to receiver.

### Compliance Enforcement

1. **Freezing**: Agents can freeze addresses to prevent transfers.
2. **Forced Transfers**: Agents can force transfers for regulatory purposes.
3. **Token Recovery**: The token owner can recover tokens from lost addresses.

## Differences from Ethereum Implementation

1. **Account Model**: Solana uses an account-based model, so data is stored in separate accounts rather than in contract storage.
2. **Program Ownership**: Accounts are owned by programs, which determines who can modify them.
3. **Rent**: Accounts need to maintain a minimum balance for rent exemption.
4. **Transaction Model**: Instructions are executed in programs rather than through method calls.
5. **Authorization**: Uses Solana's native signing mechanism rather than EVM's msg.sender.

## Security Considerations

1. **Program Validation**: Validate all accounts passed to instructions.
2. **Ownership Checks**: Ensure operations are performed by authorized principals.
3. **State Validation**: Validate all state transitions.
4. **Rent Exemption**: Ensure accounts maintain rent exemption.

## Optimizations

1. **Account Size**: Minimize account sizes to reduce transaction costs.
2. **Instruction Batching**: Batch related operations into a single transaction.
3. **Cross-Program Invocations**: Use CPIs for interactions between components.
4. **State Compression**: Use efficient state encoding to minimize storage.