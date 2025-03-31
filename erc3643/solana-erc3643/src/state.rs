//! State transitions for ERC3643 token program

use borsh::{BorshDeserialize, BorshSerialize};
use solana_program::{
    program_error::ProgramError,
    program_pack::{IsInitialized, Pack, Sealed},
    pubkey::Pubkey,
};

/// Token account state flags
pub const ACCOUNT_FROZEN_FLAG: u8 = 1;

/// Token data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Token {
    /// Initialized state
    pub is_initialized: bool,
    /// Token owner
    pub owner: Pubkey,
    /// Token name
    pub name: String,
    /// Token symbol
    pub symbol: String,
    /// Number of decimals
    pub decimals: u8,
    /// Total supply
    pub supply: u64,
    /// Paused state
    pub is_paused: bool,
    /// Identity registry address
    pub identity_registry: Pubkey,
    /// Compliance address
    pub compliance: Pubkey,
}

impl IsInitialized for Token {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for Token {}

impl Pack for Token {
    const LEN: usize = 512; // Allocate enough space for the token data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let token = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(token)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}

impl Token {
    /// Check if a pubkey is an agent for this token
    pub fn is_agent(&self, key: &Pubkey) -> bool {
        // In a real implementation, we would check against a list of agents stored in another account
        // For simplicity, we just check if the key is the owner
        *key == self.owner
    }
}

/// Token account data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct TokenAccount {
    /// Initialized state
    pub is_initialized: bool,
    /// The token this account holds
    pub token: Pubkey,
    /// The owner of this account
    pub owner: Pubkey,
    /// The amount of tokens held
    pub amount: u64,
    /// The account state (flags such as frozen)
    pub state: u8,
}

impl IsInitialized for TokenAccount {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for TokenAccount {}

impl Pack for TokenAccount {
    const LEN: usize = 128; // Allocate enough space for the token account data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let account = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(account)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}

/// Identity data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Identity {
    /// Initialized state
    pub is_initialized: bool,
    /// The owner of this identity
    pub owner: Pubkey,
    /// The identity hash
    pub identity_hash: [u8; 32],
    /// The country code
    pub country: u16,
}

impl IsInitialized for Identity {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for Identity {}

impl Pack for Identity {
    const LEN: usize = 128; // Allocate enough space for the identity data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let identity = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(identity)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}

/// Identity registry data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct IdentityRegistry {
    /// Initialized state
    pub is_initialized: bool,
    /// The owner of this registry
    pub owner: Pubkey,
    /// Identity storage address
    pub identity_storage: Pubkey,
    /// Trusted issuers registry address
    pub trusted_issuers_registry: Pubkey,
    /// Claim topics registry address
    pub claim_topics_registry: Pubkey,
}

impl IsInitialized for IdentityRegistry {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for IdentityRegistry {}

impl Pack for IdentityRegistry {
    const LEN: usize = 256; // Allocate enough space for the registry data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let registry = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(registry)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}

impl IdentityRegistry {
    /// Check if an address is verified
    pub fn is_verified_address(&self, address: &Pubkey) -> bool {
        // In a real implementation, we would load the identity data for this address
        // and check the required claims against the trusted issuers
        // For simplicity, we'll just return true here
        true
    }

    /// Check if an identity exists for a given address
    pub fn identity_exists(&self, address: &Pubkey) -> bool {
        // In a real implementation, we would check if there's an identity record
        // for this address in the identity storage
        // For simplicity, we'll just return false here
        false
    }

    /// Check if a pubkey is an agent for this registry
    pub fn is_agent(&self, key: &Pubkey) -> bool {
        // In a real implementation, we would check against a list of agents stored in another account
        // For simplicity, we just check if the key is the owner
        *key == self.owner
    }
}

/// Compliance data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Compliance {
    /// Initialized state
    pub is_initialized: bool,
    /// The owner of this compliance
    pub owner: Pubkey,
}

impl IsInitialized for Compliance {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for Compliance {}

impl Pack for Compliance {
    const LEN: usize = 128; // Allocate enough space for the compliance data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let compliance = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(compliance)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}

impl Compliance {
    /// Check if a transfer is compliant
    pub fn check_transfer(&self, from: &Pubkey, to: &Pubkey, amount: u64) -> bool {
        // In a real implementation, we would check against the compliance rules
        // For simplicity, we'll just return true here
        true
    }
}

/// Agent data
#[derive(BorshSerialize, BorshDeserialize, PartialEq, Debug, Clone)]
pub struct Agent {
    /// Initialized state
    pub is_initialized: bool,
    /// The agent pubkey
    pub key: Pubkey,
}

impl IsInitialized for Agent {
    fn is_initialized(&self) -> bool {
        self.is_initialized
    }
}

impl Sealed for Agent {}

impl Pack for Agent {
    const LEN: usize = 64; // Allocate enough space for the agent data

    fn unpack_from_slice(src: &[u8]) -> Result<Self, ProgramError> {
        let agent = Self::try_from_slice(src).map_err(|_| ProgramError::InvalidAccountData)?;
        Ok(agent)
    }

    fn pack_into_slice(&self, dst: &mut [u8]) {
        let data = self.try_to_vec().unwrap();
        let len = data.len();
        dst[..len].copy_from_slice(&data);
    }
}