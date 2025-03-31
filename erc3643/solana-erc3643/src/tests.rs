#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        instruction::*,
        processor::Processor,
        state::{Token, TokenAccount},
    };
    use solana_program::{
        account_info::AccountInfo, entrypoint::ProgramResult, program_error::ProgramError,
        program_pack::Pack, pubkey::Pubkey, sysvar::rent,
    };
    use solana_program_test::{processor, ProgramTest};
    use solana_sdk::{
        account::Account,
        signature::{Keypair, Signer},
        transaction::Transaction,
    };

    #[tokio::test]
    async fn test_initialize_token() {
        // Create program test environment
        let program_id = Pubkey::new_unique();
        let mut program_test = ProgramTest::new(
            "solana_erc3643",
            program_id,
            processor!(Processor::process),
        );

        // Add accounts needed for test
        let token_account_keypair = Keypair::new();
        let owner_keypair = Keypair::new();
        let identity_registry_keypair = Keypair::new();
        let compliance_keypair = Keypair::new();

        // Set up the token account
        let token_account_space = Token::LEN;
        let rent = solana_program_test::get_minimum_rent(&program_test.program_context);
        let token_account_rent = rent;
        program_test.add_account(
            token_account_keypair.pubkey(),
            Account {
                lamports: token_account_rent,
                data: vec![0; token_account_space],
                owner: program_id,
                ..Account::default()
            },
        );

        // Start the program test
        let (mut banks_client, payer, recent_blockhash) = program_test.start().await;

        // Create the instruction data
        let name = "Test Token".to_string();
        let symbol = "TEST".to_string();
        let decimals = 9;

        // Create instruction
        let instruction = initialize_token(
            &program_id,
            &token_account_keypair.pubkey(),
            &owner_keypair.pubkey(),
            &identity_registry_keypair.pubkey(),
            &compliance_keypair.pubkey(),
            name.clone(),
            symbol.clone(),
            decimals,
        );

        // Create transaction
        let mut transaction = Transaction::new_with_payer(&[instruction], Some(&payer.pubkey()));
        transaction.sign(&[&payer, &owner_keypair], recent_blockhash);

        // Process the transaction
        banks_client.process_transaction(transaction).await.unwrap();

        // Verify the token is initialized correctly
        let token_account = banks_client
            .get_account(token_account_keypair.pubkey())
            .await
            .unwrap()
            .unwrap();
        let token = Token::unpack(&token_account.data).unwrap();

        assert_eq!(token.name, name);
        assert_eq!(token.symbol, symbol);
        assert_eq!(token.decimals, decimals);
        assert_eq!(token.owner, owner_keypair.pubkey());
        assert_eq!(token.identity_registry, identity_registry_keypair.pubkey());
        assert_eq!(token.compliance, compliance_keypair.pubkey());
        assert_eq!(token.supply, 0);
        assert_eq!(token.is_paused, false);
        assert!(token.is_initialized);
    }

    // Additional tests would be added here for other functionalities
    // such as transfer, mint, burn, etc.
}