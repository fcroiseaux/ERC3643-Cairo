// Simplified version without using OwnableComponent
// We'll implement our own ownership control
use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
    storage::Map,
};
use core::array::ArrayTrait;
use core::traits::TryInto;
use core::option::OptionTrait;

// Trusted Issuers Registry Interface
#[starknet::interface]
pub trait ITrustedIssuersRegistry<TContractState> {
    fn add_trusted_issuer(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn remove_trusted_issuer(ref self: TContractState, issuer: felt252) -> bool;
    fn update_issuer_claims(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn get_trusted_issuers(self: @TContractState) -> Array<felt252>;
    fn get_issuer_claim_topics(self: @TContractState, issuer: felt252) -> Array<felt252>;
    fn is_trusted_issuer(self: @TContractState, issuer: felt252) -> bool;
    fn has_claim_topic(self: @TContractState, issuer: felt252, claim_topic: felt252) -> bool;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod TrustedIssuersRegistry {
    use super::*;
    
    // No component declarations - we'll implement ownership directly
    
    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnershipTransferred: OwnershipTransferred,
        TrustedIssuerAdded: TrustedIssuerAdded,
        TrustedIssuerRemoved: TrustedIssuerRemoved,
        ClaimTopicsUpdated: ClaimTopicsUpdated,
    }
    
    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        previous_owner: ContractAddress,
        new_owner: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct TrustedIssuerAdded {
        issuer: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct TrustedIssuerRemoved {
        issuer: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ClaimTopicsUpdated {
        issuer: felt252,
    }
    
    #[storage]
    struct Storage {
        // Owner storage - using a map with a fixed key for consistency
        _owner_map: Map<felt252, ContractAddress>,  // Map to store the owner at key "owner"
        
        // Use a Map with a fixed key to store the counter
        trusted_issuer_counter_map: Map<u32, u32>,  // Map to store the counter at key 0
        trusted_issuers_by_index: Map<u32, felt252>,  // Index to issuer mapping
        trusted_issuer_indexes: Map<felt252, u32>,  // Issuer to index mapping
        
        // Issuer claim topics storage
        issuer_claim_topic_counts: Map<felt252, u32>,  // Number of claim topics for an issuer
        issuer_claim_topics: Map<(felt252, u32), felt252>,  // Issuer + index to claim topic mapping
    }
    
    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        // Initialize owner directly
        self._owner_map.write('owner', initial_owner);
        
        // Emit ownership event
        // Use a consistent pattern for the zero address
        let mut zero_addr_felt: felt252 = 0;
        let zero_address: ContractAddress = zero_addr_felt.try_into().unwrap();
        self.emit(OwnershipTransferred { 
            previous_owner: zero_address, 
            new_owner: initial_owner 
        });
        
        // Initialize counter using a Map entry for simplicity
        self.trusted_issuer_counter_map.write(0, 0);
    }
    
    #[abi(embed_v0)]
    impl TrustedIssuersRegistryImpl of super::ITrustedIssuersRegistry<ContractState> {
        fn add_trusted_issuer(ref self: ContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool {
            // Only owner can add trusted issuers
            self.assert_only_owner();
            
            // Check if issuer already exists
            if self.is_trusted_issuer(issuer) {
                // Update the claim topics instead
                return self.update_issuer_claims(issuer, claim_topics);
            }
            
            // Get current issuer count
            let trusted_issuer_count = self.get_trusted_issuer_count();
            
            // Add issuer
            self.trusted_issuers_by_index.write(trusted_issuer_count, issuer);
            self.trusted_issuer_indexes.write(issuer, trusted_issuer_count + 1); // +1 to differentiate from 0 (not found)
            
            // Add claim topics
            self._update_issuer_claim_topics(issuer, claim_topics);
            
            // Increment issuer count
            self.set_trusted_issuer_count(trusted_issuer_count + 1);
            
            // Emit event
            self.emit(TrustedIssuerAdded { issuer });
            
            true
        }
        
        fn remove_trusted_issuer(ref self: ContractState, issuer: felt252) -> bool {
            // Only owner can remove trusted issuers
            self.assert_only_owner();
            
            // Check if issuer exists
            if !self.is_trusted_issuer(issuer) {
                // Issuer doesn't exist
                return true;
            }
            
            // Get index (1-based)
            let index_1_based = self.trusted_issuer_indexes.read(issuer);
            if index_1_based == 0 {
                // Issuer not found (should not happen at this point)
                return true;
            }
            
            // Convert to 0-based index
            let index = index_1_based - 1;
            
            // Get current issuer count
            let trusted_issuer_count = self.get_trusted_issuer_count();
            
            // If not the last issuer, move the last issuer to this index
            if index < trusted_issuer_count - 1 {
                let last_issuer = self.trusted_issuers_by_index.read(trusted_issuer_count - 1);
                self.trusted_issuers_by_index.write(index, last_issuer);
                self.trusted_issuer_indexes.write(last_issuer, index + 1); // +1 to differentiate from 0
            }
            
            // Remove issuer
            self.trusted_issuer_indexes.write(issuer, 0);
            
            // Clear claim topics for this issuer
            self.issuer_claim_topic_counts.write(issuer, 0);
            
            // Decrement issuer count
            self.set_trusted_issuer_count(trusted_issuer_count - 1);
            
            // Emit event
            self.emit(TrustedIssuerRemoved { issuer });
            
            true
        }
        
        fn update_issuer_claims(ref self: ContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool {
            // Only owner can update claim topics
            self.assert_only_owner();
            
            // Check if issuer exists
            assert(self.is_trusted_issuer(issuer), 'Issuer not trusted');
            
            // Update claim topics
            self._update_issuer_claim_topics(issuer, claim_topics);
            
            // Emit event
            self.emit(ClaimTopicsUpdated { issuer });
            
            true
        }
        
        fn get_trusted_issuers(self: @ContractState) -> Array<felt252> {
            let mut issuers = ArrayTrait::<felt252>::new();
            let trusted_issuer_count = self.get_trusted_issuer_count();
            
            let mut i: u32 = 0;
            loop {
                if i >= trusted_issuer_count {
                    break;
                }
                
                // Get issuer and add to array
                let issuer = self.trusted_issuers_by_index.read(i);
                issuers.append(issuer);
                
                i += 1;
            };
            
            issuers
        }
        
        fn get_issuer_claim_topics(self: @ContractState, issuer: felt252) -> Array<felt252> {
            let mut claim_topics = ArrayTrait::<felt252>::new();
            
            // Check if issuer exists
            if !self.is_trusted_issuer(issuer) {
                return claim_topics; // Empty array
            }
            
            // Get claim topics count
            let claim_topic_count = self.issuer_claim_topic_counts.read(issuer);
            
            // Get all claim topics
            let mut i: u32 = 0;
            loop {
                if i >= claim_topic_count {
                    break;
                }
                
                // Get claim topic and add to array
                let claim_topic = self.issuer_claim_topics.read((issuer, i));
                claim_topics.append(claim_topic);
                
                i += 1;
            };
            
            claim_topics
        }
        
        fn is_trusted_issuer(self: @ContractState, issuer: felt252) -> bool {
            self.trusted_issuer_indexes.read(issuer) != 0
        }
        
        fn has_claim_topic(self: @ContractState, issuer: felt252, claim_topic: felt252) -> bool {
            // Check if issuer exists
            if !self.is_trusted_issuer(issuer) {
                return false;
            }
            
            // Get claim topics count
            let claim_topic_count = self.issuer_claim_topic_counts.read(issuer);
            
            // Check if claim topic exists
            let mut i: u32 = 0;
            loop {
                if i >= claim_topic_count {
                    break;
                }
                
                if self.issuer_claim_topics.read((issuer, i)) == claim_topic {
                    return true;
                }
                
                i += 1;
            };
            
            false
        }
        
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            // Use our internal implementation explicitly
            InternalFunctions::transfer_ownership(ref self, new_owner);
            true
        }
        
        fn owner(self: @ContractState) -> ContractAddress {
            // Use our internal implementation explicitly
            InternalFunctions::owner(self)
        }
    }
    
    // Internal functions
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        // Owner helper methods
        fn owner(self: @ContractState) -> ContractAddress {
            self._owner_map.read('owner')
        }
        
        fn assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            // Use InternalFunctions::owner directly to avoid ambiguity
            let current_owner = self._owner_map.read('owner');
            assert(caller == current_owner, 'Caller is not the owner');
        }
        
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            // Only owner can transfer ownership
            self.assert_only_owner();
            
            // Zero address validation
            let mut zero_addr_felt: felt252 = 0;
            let zero_address: ContractAddress = zero_addr_felt.try_into().unwrap();
            assert(new_owner != zero_address, 'New owner is the zero address');
            
            // Transfer ownership
            let previous_owner = self._owner_map.read('owner');
            self._owner_map.write('owner', new_owner);
            
            // Emit event
            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }
        
        // Helper methods for accessing the counter using the Map
        fn get_trusted_issuer_count(self: @ContractState) -> u32 {
            self.trusted_issuer_counter_map.read(0)
        }
        
        fn set_trusted_issuer_count(ref self: ContractState, value: u32) {
            self.trusted_issuer_counter_map.write(0, value);
        }
        
        fn _update_issuer_claim_topics(ref self: ContractState, issuer: felt252, claim_topics: Array<felt252>) {
            // Clear existing claim topics
            self.issuer_claim_topic_counts.write(issuer, 0);
            
            // Add new claim topics
            let len = claim_topics.len();
            let mut i: usize = 0;
            
            // For each claim topic in the array, add it to the storage
            loop {
                if i >= len {
                    break;
                }
                
                let topic = *claim_topics.at(i);
                let index: u32 = i.try_into().unwrap();
                self.issuer_claim_topics.write((issuer, index), topic);
                
                i += 1;
            };
            
            // Update the count
            let topic_count: u32 = len.try_into().unwrap();
            self.issuer_claim_topic_counts.write(issuer, topic_count);
        }
    }
}