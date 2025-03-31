# Solana ERC3643 (T-REX) Implementation

This is a Solana implementation of the ERC3643 Token for Regulated EXchanges (T-REX) standard, which provides a framework for tokenized securities on the Solana blockchain.

## Features

- **Compliance Management**: Enforces regulatory compliance for token transfers
- **Identity Verification**: Integrates with on-chain identity verification 
- **Permissioned Transfers**: Restricts transfers to verified identities only
- **Agent System**: Allows designated agents to perform administrative actions
- **Token Recovery**: Enables recovery of tokens from lost addresses
- **Freezing**: Supports freezing specific addresses when necessary
- **Regulatory Controls**: Provides functions for regulatory oversight

## Architecture

The implementation consists of the following components:

1. **Token Program**: Core token functionality with regulatory extensions
2. **Identity Registry**: Manages user identities and verification status
3. **Identity Storage**: Stores identity data and associated information
4. **Trusted Issuers Registry**: Maintains a list of trusted identity issuers
5. **Claim Topics Registry**: Defines required claim topics for verification
6. **Compliance Program**: Enforces transfer rules and compliance checks

## Development

### Prerequisites

- Rust 1.70.0 or later
- Solana CLI tools
- Anchor framework (optional)

### Building

```bash
cargo build-bpf
```

### Testing

```bash
cargo test-bpf
```

## License

MIT