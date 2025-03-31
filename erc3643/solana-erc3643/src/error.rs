//! Error types for the ERC3643 token program

use num_derive::FromPrimitive;
use solana_program::{decode_error::DecodeError, program_error::ProgramError, program_error::PrintProgramError};
use thiserror::Error;

/// Errors that may be returned by the Token program.
#[derive(Clone, Debug, Eq, Error, FromPrimitive, PartialEq)]
pub enum TokenError {
    /// Invalid instruction
    #[error("Invalid instruction")]
    InvalidInstruction,

    /// Not rent exempt
    #[error("Not rent exempt")]
    NotRentExempt,

    /// Expected a different program owner
    #[error("Expected a different program owner")]
    IncorrectProgramId,

    /// Invalid owner
    #[error("Invalid account owner")]
    InvalidOwner,

    /// Identity not verified
    #[error("Identity not verified")]
    IdentityNotVerified,

    /// Address is frozen
    #[error("Address is frozen")]
    AddressFrozen,

    /// Transfer not compliant
    #[error("Transfer not compliant")]
    TransferNotCompliant,

    /// Account is not authorized for operation
    #[error("Account is not authorized for operation")]
    Unauthorized,

    /// Invalid Identity
    #[error("Invalid identity")]
    InvalidIdentity,

    /// Identity already exists
    #[error("Identity already exists")]
    IdentityAlreadyExists,

    /// Identity not found
    #[error("Identity not found")]
    IdentityNotFound,

    /// Insufficient funds
    #[error("Insufficient funds")]
    InsufficientFunds,

    /// Invalid agent
    #[error("Invalid agent")]
    InvalidAgent,

    /// Token is paused
    #[error("Token is paused")]
    TokenPaused,

    /// Transfer exceeds limit
    #[error("Transfer exceeds limit")]
    TransferExceedsLimit,

    /// Invalid claim topic
    #[error("Invalid claim topic")]
    InvalidClaimTopic,

    /// Invalid issuer
    #[error("Invalid issuer")]
    InvalidIssuer,
}

impl From<TokenError> for ProgramError {
    fn from(e: TokenError) -> Self {
        ProgramError::Custom(e as u32)
    }
}

impl<T> DecodeError<T> for TokenError {
    fn type_of() -> &'static str {
        "TokenError"
    }
}

impl PrintProgramError for TokenError {
    fn print<E>(&self)
    where
        E: 'static + std::error::Error + DecodeError<E> + PrintProgramError + num_traits::FromPrimitive,
    {
        match self {
            TokenError::InvalidInstruction => println!("Error: Invalid instruction"),
            TokenError::NotRentExempt => println!("Error: Not rent exempt"),
            TokenError::IncorrectProgramId => println!("Error: Expected a different program owner"),
            TokenError::InvalidOwner => println!("Error: Invalid account owner"),
            TokenError::IdentityNotVerified => println!("Error: Identity not verified"),
            TokenError::AddressFrozen => println!("Error: Address is frozen"),
            TokenError::TransferNotCompliant => println!("Error: Transfer not compliant"),
            TokenError::Unauthorized => println!("Error: Account is not authorized for operation"),
            TokenError::InvalidIdentity => println!("Error: Invalid identity"),
            TokenError::IdentityAlreadyExists => println!("Error: Identity already exists"),
            TokenError::IdentityNotFound => println!("Error: Identity not found"),
            TokenError::InsufficientFunds => println!("Error: Insufficient funds"),
            TokenError::InvalidAgent => println!("Error: Invalid agent"),
            TokenError::TokenPaused => println!("Error: Token is paused"),
            TokenError::TransferExceedsLimit => println!("Error: Transfer exceeds limit"),
            TokenError::InvalidClaimTopic => println!("Error: Invalid claim topic"),
            TokenError::InvalidIssuer => println!("Error: Invalid issuer"),
        }
    }
}