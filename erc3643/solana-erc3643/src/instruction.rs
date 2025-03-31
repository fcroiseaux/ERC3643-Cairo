//! Instruction types for the ERC3643 token program

use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    instruction::{AccountMeta, Instruction},
    pubkey::Pubkey,
    sysvar,
};

/// Instructions supported by the ERC3643 Token program
#[derive(BorshSerialize, BorshDeserialize, Clone, Debug, PartialEq)]
pub enum TokenInstruction {
    /// Initialize a new token
    ///
    /// Accounts expected:
    /// 0. `[writable]` The token account to initialize
    /// 1. `[]` Rent sysvar
    /// 2. `[signer]` Token owner
    /// 3. `[]` Identity registry account
    /// 4. `[]` Compliance account
    InitializeToken {
        /// Name of the token
        name: String,
        /// Symbol of the token
        symbol: String,
        /// Number of decimals in token amount
        decimals: u8,
    },

    /// Transfer tokens with compliance verification
    ///
    /// Accounts expected:
    /// 0. `[signer]` Owner account
    /// 1. `[writable]` Source token account
    /// 2. `[writable]` Destination token account
    /// 3. `[]` Token account
    /// 4. `[]` Identity registry account
    /// 5. `[]` Compliance account
    Transfer {
        /// Amount to transfer
        amount: u64,
    },

    /// Force transfer tokens (only for agents)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Agent account
    /// 1. `[writable]` Source token account
    /// 2. `[writable]` Destination token account
    /// 3. `[]` Token account
    /// 4. `[]` Identity registry account
    /// 5. `[]` Compliance account
    ForcedTransfer {
        /// Amount to transfer
        amount: u64,
    },

    /// Mint new tokens (only for agents)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Agent account
    /// 1. `[writable]` Destination token account
    /// 2. `[writable]` Token account
    /// 3. `[]` Identity registry account
    Mint {
        /// Amount to mint
        amount: u64,
    },

    /// Burn tokens
    ///
    /// Accounts expected:
    /// 0. `[signer]` Owner account
    /// 1. `[writable]` Source token account
    /// 2. `[writable]` Token account
    Burn {
        /// Amount to burn
        amount: u64,
    },

    /// Recover tokens from a lost address (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Lost token account
    /// 2. `[writable]` Recovery destination token account
    /// 3. `[writable]` Token account
    Recover {
        /// Amount to recover
        amount: u64,
    },

    /// Freeze an address (only for agents)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Agent account
    /// 1. `[writable]` Target token account
    /// 2. `[writable]` Token account
    FreezeAddress,

    /// Unfreeze an address (only for agents)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Agent account
    /// 1. `[writable]` Target token account
    /// 2. `[writable]` Token account
    UnfreezeAddress,

    /// Set compliance (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    /// 2. `[]` New compliance account
    SetCompliance,

    /// Set identity registry (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    /// 2. `[]` New identity registry account
    SetIdentityRegistry,

    /// Add an agent (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    /// 2. `[]` Agent account to add
    AddAgent,

    /// Remove an agent (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    /// 2. `[]` Agent account to remove
    RemoveAgent,

    /// Pause the token (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    Pause,

    /// Unpause the token (only for token owner)
    ///
    /// Accounts expected:
    /// 0. `[signer]` Token owner account
    /// 1. `[writable]` Token account
    Unpause,

    /// Register an identity in the identity registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Identity registry owner or agent
    /// 1. `[writable]` Identity registry account
    /// 2. `[writable]` Identity storage account
    /// 3. `[]` User account to register
    RegisterIdentity {
        /// Identity hash
        identity: [u8; 32],
        /// Country code
        country: u16,
    },

    /// Update an identity in the identity registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Identity registry owner or agent
    /// 1. `[writable]` Identity registry account
    /// 2. `[writable]` Identity storage account
    /// 3. `[]` User account to update
    UpdateIdentity {
        /// New identity hash
        identity: [u8; 32],
    },

    /// Update country for an identity
    ///
    /// Accounts expected:
    /// 0. `[signer]` Identity registry owner or agent
    /// 1. `[writable]` Identity registry account
    /// 2. `[writable]` Identity storage account
    /// 3. `[]` User account to update
    UpdateCountry {
        /// New country code
        country: u16,
    },

    /// Delete an identity from the registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Identity registry owner or agent
    /// 1. `[writable]` Identity registry account
    /// 2. `[writable]` Identity storage account
    /// 3. `[]` User account to delete
    DeleteIdentity,

    /// Add a claim topic to the registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Claim topics registry owner
    /// 1. `[writable]` Claim topics registry account
    AddClaimTopic {
        /// Claim topic to add
        topic: u64,
    },

    /// Remove a claim topic from the registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Claim topics registry owner
    /// 1. `[writable]` Claim topics registry account
    RemoveClaimTopic {
        /// Claim topic to remove
        topic: u64,
    },

    /// Add a trusted issuer to the registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Trusted issuers registry owner
    /// 1. `[writable]` Trusted issuers registry account
    /// 2. `[]` Issuer account to add
    AddTrustedIssuer {
        /// Claim topics supported by the issuer
        claim_topics: Vec<u64>,
    },

    /// Remove a trusted issuer from the registry
    ///
    /// Accounts expected:
    /// 0. `[signer]` Trusted issuers registry owner
    /// 1. `[writable]` Trusted issuers registry account
    /// 2. `[]` Issuer account to remove
    RemoveTrustedIssuer,

    /// Update claim topics for a trusted issuer
    ///
    /// Accounts expected:
    /// 0. `[signer]` Trusted issuers registry owner
    /// 1. `[writable]` Trusted issuers registry account
    /// 2. `[]` Issuer account to update
    UpdateIssuerClaimTopics {
        /// New claim topics for the issuer
        claim_topics: Vec<u64>,
    },

    /// Add a compliance rule
    ///
    /// Accounts expected:
    /// 0. `[signer]` Compliance owner
    /// 1. `[writable]` Compliance account
    /// 2. `[]` Rule account to add
    AddComplianceRule,

    /// Remove a compliance rule
    ///
    /// Accounts expected:
    /// 0. `[signer]` Compliance owner
    /// 1. `[writable]` Compliance account
    /// 2. `[]` Rule account to remove
    RemoveComplianceRule,
}

/// Creates an `InitializeToken` instruction
pub fn initialize_token(
    program_id: &Pubkey,
    token_account: &Pubkey,
    owner: &Pubkey,
    identity_registry: &Pubkey,
    compliance: &Pubkey,
    name: String,
    symbol: String,
    decimals: u8,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new(*token_account, false),
        AccountMeta::new_readonly(sysvar::rent::id(), false),
        AccountMeta::new_readonly(*owner, true),
        AccountMeta::new_readonly(*identity_registry, false),
        AccountMeta::new_readonly(*compliance, false),
    ];

    let data = TokenInstruction::InitializeToken {
        name,
        symbol,
        decimals,
    }
    .try_to_vec()
    .unwrap();

    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}

/// Creates a `Transfer` instruction
pub fn transfer(
    program_id: &Pubkey,
    owner: &Pubkey,
    source: &Pubkey,
    destination: &Pubkey,
    token: &Pubkey,
    identity_registry: &Pubkey,
    compliance: &Pubkey,
    amount: u64,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*owner, true),
        AccountMeta::new(*source, false),
        AccountMeta::new(*destination, false),
        AccountMeta::new_readonly(*token, false),
        AccountMeta::new_readonly(*identity_registry, false),
        AccountMeta::new_readonly(*compliance, false),
    ];

    let data = TokenInstruction::Transfer { amount }.try_to_vec().unwrap();

    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}

/// Creates a `ForcedTransfer` instruction
pub fn forced_transfer(
    program_id: &Pubkey,
    agent: &Pubkey,
    source: &Pubkey,
    destination: &Pubkey,
    token: &Pubkey,
    identity_registry: &Pubkey,
    compliance: &Pubkey,
    amount: u64,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*agent, true),
        AccountMeta::new(*source, false),
        AccountMeta::new(*destination, false),
        AccountMeta::new_readonly(*token, false),
        AccountMeta::new_readonly(*identity_registry, false),
        AccountMeta::new_readonly(*compliance, false),
    ];

    let data = TokenInstruction::ForcedTransfer { amount }
        .try_to_vec()
        .unwrap();

    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}

/// Creates a `Mint` instruction
pub fn mint(
    program_id: &Pubkey,
    agent: &Pubkey,
    destination: &Pubkey,
    token: &Pubkey,
    identity_registry: &Pubkey,
    amount: u64,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*agent, true),
        AccountMeta::new(*destination, false),
        AccountMeta::new(*token, false),
        AccountMeta::new_readonly(*identity_registry, false),
    ];

    let data = TokenInstruction::Mint { amount }.try_to_vec().unwrap();

    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}

/// Creates a `Burn` instruction
pub fn burn(
    program_id: &Pubkey,
    owner: &Pubkey,
    source: &Pubkey,
    token: &Pubkey,
    amount: u64,
) -> Instruction {
    let accounts = vec![
        AccountMeta::new_readonly(*owner, true),
        AccountMeta::new(*source, false),
        AccountMeta::new(*token, false),
    ];

    let data = TokenInstruction::Burn { amount }.try_to_vec().unwrap();

    Instruction {
        program_id: *program_id,
        accounts,
        data,
    }
}

// Additional instruction creation functions would go here...