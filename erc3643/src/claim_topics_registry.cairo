// Import OpenZeppelin's components
use openzeppelin::access::ownable::OwnableComponent;
// The following import is not needed as we use OwnableComponent directly
// use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
use starknet::{
    ContractAddress, 
    // get_caller_address not needed as we use OwnableComponent::assert_only_owner
    // get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
    storage::Map,
};
use core::array::ArrayTrait;

// Claim Topics Registry Interface
#[starknet::interface]
pub trait IClaimTopicsRegistry<TContractState> {
    fn add_claim_topic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn remove_claim_topic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn get_claim_topics(self: @TContractState) -> Array<felt252>;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn owner(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
pub mod ClaimTopicsRegistry {
    use super::*;
    
    // Component declarations
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    
    // Implement component interfaces
    // We're removing abi(embed_v0) to avoid duplicate entry points in testing
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    
    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        ClaimTopicAdded: ClaimTopicAdded,
        ClaimTopicRemoved: ClaimTopicRemoved,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ClaimTopicAdded {
        claim_topic: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ClaimTopicRemoved {
        claim_topic: felt252,
    }
    
    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        
        // Claim topics storage using maps to avoid direct storage access issues
        topic_count_map: Map<felt252, u32>,  // Using 'count' as key
        topics: Map<u32, felt252>,  // Index to topic mapping
        topic_indices: Map<felt252, u32>,  // Topic to index mapping
    }
    
    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        // Initialize Ownable component
        self.ownable.initializer(initial_owner);
        
        // Initialize counter using a Map entry for simplicity
        self.topic_count_map.write('count', 0);
    }
    
    #[abi(embed_v0)]
    impl ClaimTopicsRegistryImpl of super::IClaimTopicsRegistry<ContractState> {
        fn add_claim_topic(ref self: ContractState, claim_topic: felt252) -> bool {
            // Only owner can add claim topics
            self.ownable.assert_only_owner();
            
            // Check if topic already exists
            let existing_index = self.topic_indices.read(claim_topic);
            if existing_index != 0 {
                // Topic already exists
                return true;
            }
            
            // Get current topic count
            let topic_count = self.get_topic_count();
            
            // Add topic
            self.topics.write(topic_count, claim_topic);
            self.topic_indices.write(claim_topic, topic_count + 1); // +1 to differentiate from 0 (not found)
            
            // Increment count
            self.set_topic_count(topic_count + 1);
            
            // Emit event
            self.emit(ClaimTopicAdded { claim_topic });
            
            true
        }
        
        fn remove_claim_topic(ref self: ContractState, claim_topic: felt252) -> bool {
            // Only owner can remove claim topics
            self.ownable.assert_only_owner();
            
            // Check if topic exists
            let existing_index = self.topic_indices.read(claim_topic);
            if existing_index == 0 {
                // Topic doesn't exist
                return true;
            }
            
            // Convert index from 1-based to 0-based
            let index = existing_index - 1;
            
            // Get current topic count
            let topic_count = self.get_topic_count();
            
            // If not the last topic, move the last topic to this index
            if index < topic_count - 1 {
                let last_topic = self.topics.read(topic_count - 1);
                self.topics.write(index, last_topic);
                self.topic_indices.write(last_topic, index + 1); // +1 to differentiate from 0 (not found)
            }
            
            // Remove topic
            self.topic_indices.write(claim_topic, 0);
            
            // Decrement count
            self.set_topic_count(topic_count - 1);
            
            // Emit event
            self.emit(ClaimTopicRemoved { claim_topic });
            
            true
        }
        
        fn get_claim_topics(self: @ContractState) -> Array<felt252> {
            let mut topics = ArrayTrait::<felt252>::new();
            let topic_count = self.get_topic_count();
            
            let mut i: u32 = 0;
            loop {
                if i >= topic_count {
                    break;
                }
                
                // Get topic and add to array
                let topic = self.topics.read(i);
                topics.append(topic);
                
                i += 1;
            };
            
            topics
        }
        
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.ownable.transfer_ownership(new_owner);
            true
        }
        
        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }
    }
    
    // Internal helper functions
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        // Helper methods for accessing the counter using the Map
        fn get_topic_count(self: @ContractState) -> u32 {
            self.topic_count_map.read('count')
        }
        
        fn set_topic_count(ref self: ContractState, value: u32) {
            self.topic_count_map.write('count', value);
        }
    }
}