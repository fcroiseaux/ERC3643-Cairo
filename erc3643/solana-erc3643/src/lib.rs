//! Solana ERC3643 (T-REX) Implementation
//!
//! This library provides an implementation of the ERC3643 standard
//! for regulated tokens on the Solana blockchain.

pub mod error;
pub mod instruction;
pub mod processor;
pub mod state;
#[cfg(test)]
mod tests;

/// Program entrypoint
#[cfg(not(feature = "no-entrypoint"))]
pub mod entrypoint {
    use crate::processor::Processor;
    use solana_program::{
        account_info::AccountInfo, entrypoint, entrypoint::ProgramResult,
        program_error::PrintProgramError, pubkey::Pubkey,
    };

    entrypoint!(process_instruction);
    fn process_instruction(
        program_id: &Pubkey,
        accounts: &[AccountInfo],
        instruction_data: &[u8],
    ) -> ProgramResult {
        if let Err(error) = Processor::process(program_id, accounts, instruction_data) {
            // Print error information to the program log
            error.print::<crate::error::TokenError>();
            return Err(error);
        }
        Ok(())
    }
}

solana_program::declare_id!("TREX111111111111111111111111111111111111111");