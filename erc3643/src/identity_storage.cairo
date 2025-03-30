// Import OpenZeppelin's components
use openzeppelin::access::ownable::OwnableComponent;
use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
};
use core::array::ArrayTrait;

// Identity Storage Interface
#[starknet::interface]
pub trait IIdentityStorage<TContractState> {
    // Ownable interface
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn renounce_ownership(ref self: TContractState) -> bool;
    
    // Identity storage functions
    fn register_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn update_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn update_country(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn delete_identity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn get_identity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_country(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_expiration_date(self: @TContractState, user_address: ContractAddress) -> u64;
    fn set_expiration_date(ref self: TContractState, user_address: ContractAddress, expiration_date: u64) -> bool;
    fn get_addresses_by_identity(self: @TContractState, identity: felt252) -> Array<ContractAddress>;
}

#[starknet::contract]
pub mod IdentityStorage {
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
        IdentityRegistered: IdentityRegistered,
        IdentityUpdated: IdentityUpdated,
        CountryUpdated: CountryUpdated,
        IdentityRemoved: IdentityRemoved,
        ExpirationDateUpdated: ExpirationDateUpdated,
    }
    
    #[derive(Drop, starknet::Event)]
    struct IdentityRegistered {
        user_address: ContractAddress,
        identity: felt252,
        country: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct IdentityUpdated {
        user_address: ContractAddress,
        identity: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct CountryUpdated {
        user_address: ContractAddress,
        country: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct IdentityRemoved {
        user_address: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ExpirationDateUpdated {
        user_address: ContractAddress,
        expiration_date: u64,
    }
    
    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        
        // Identity storage - using consistent map naming convention
        identity_by_address_map: starknet::storage::Map::<ContractAddress, felt252>,
        country_by_address_map: starknet::storage::Map::<ContractAddress, felt252>,
        expiration_by_address_map: starknet::storage::Map::<ContractAddress, u64>,
        
        // Mapping from identity to its addresses (manages as counters and individual entries)
        address_count_by_identity_map: starknet::storage::Map::<felt252, u32>,
        address_by_identity_index_map: starknet::storage::Map::<(felt252, u32), ContractAddress>,
        
        // Registry contract that can manage this storage
        registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'registry' as key
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        // Initialize Ownable component
        self.ownable.initializer(initial_owner);
        
        // Set registry as the owner initially
        self.registry_map.write('registry', initial_owner);
    }
    
    #[abi(embed_v0)]
    impl IdentityStorageImpl of super::IIdentityStorage<ContractState> {
        // Ownable functions
        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }
        
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.ownable.transfer_ownership(new_owner);
            true
        }
        
        fn renounce_ownership(ref self: ContractState) -> bool {
            self.ownable.renounce_ownership();
            true
        }
        
        // Identity storage functions
        fn register_identity(ref self: ContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool {
            // Only registry contract can register identities
            self._assert_only_registry();
            
            // Check if identity already exists
            let existing_identity = self.identity_by_address_map.read(user_address);
            assert(existing_identity == 0, 'Identity already exists');
            
            // Store the identity and country
            self.identity_by_address_map.write(user_address, identity);
            self.country_by_address_map.write(user_address, country);
            
            // Add address to the identity's addresses list
            self._add_address_to_identity(identity, user_address);
            
            // Emit event
            self.emit(IdentityRegistered { user_address, identity, country });
            
            true
        }
        
        fn update_identity(ref self: ContractState, user_address: ContractAddress, identity: felt252) -> bool {
            // Only registry contract can update identities
            self._assert_only_registry();
            
            // Check if identity exists
            let existing_identity = self.identity_by_address_map.read(user_address);
            assert(existing_identity != 0, 'Identity does not exist');
            
            // Check if new identity is different
            assert(existing_identity != identity, 'Identity is the same');
            
            // Remove address from old identity's list
            self._remove_address_from_identity(existing_identity, user_address);
            
            // Update the identity
            self.identity_by_address_map.write(user_address, identity);
            
            // Add address to new identity's list
            self._add_address_to_identity(identity, user_address);
            
            // Emit event
            self.emit(IdentityUpdated { user_address, identity });
            
            true
        }
        
        fn update_country(ref self: ContractState, user_address: ContractAddress, country: felt252) -> bool {
            // Only registry contract can update countries
            self._assert_only_registry();
            
            // Check if identity exists
            let existing_identity = self.identity_by_address_map.read(user_address);
            assert(existing_identity != 0, 'Identity does not exist');
            
            // Update the country
            self.country_by_address_map.write(user_address, country);
            
            // Emit event
            self.emit(CountryUpdated { user_address, country });
            
            true
        }
        
        fn delete_identity(ref self: ContractState, user_address: ContractAddress) -> bool {
            // Only registry contract can delete identities
            self._assert_only_registry();
            
            // Check if identity exists
            let existing_identity = self.identity_by_address_map.read(user_address);
            assert(existing_identity != 0, 'Identity does not exist');
            
            // Remove address from identity's list
            self._remove_address_from_identity(existing_identity, user_address);
            
            // Delete identity, country and expiration date
            self.identity_by_address_map.write(user_address, 0);
            self.country_by_address_map.write(user_address, 0);
            self.expiration_by_address_map.write(user_address, 0);
            
            // Emit event
            self.emit(IdentityRemoved { user_address });
            
            true
        }
        
        fn get_identity(self: @ContractState, user_address: ContractAddress) -> felt252 {
            self.identity_by_address_map.read(user_address)
        }
        
        fn get_country(self: @ContractState, user_address: ContractAddress) -> felt252 {
            self.country_by_address_map.read(user_address)
        }
        
        fn get_expiration_date(self: @ContractState, user_address: ContractAddress) -> u64 {
            self.expiration_by_address_map.read(user_address)
        }
        
        fn set_expiration_date(ref self: ContractState, user_address: ContractAddress, expiration_date: u64) -> bool {
            // Only registry contract can set expiration dates
            self._assert_only_registry();
            
            // Check if identity exists
            let existing_identity = self.identity_by_address_map.read(user_address);
            assert(existing_identity != 0, 'Identity does not exist');
            
            // Set expiration date
            self.expiration_by_address_map.write(user_address, expiration_date);
            
            // Emit event
            self.emit(ExpirationDateUpdated { user_address, expiration_date });
            
            true
        }
        
        fn get_addresses_by_identity(self: @ContractState, identity: felt252) -> Array<ContractAddress> {
            let mut addresses = ArrayTrait::<ContractAddress>::new();
            let count = self.address_count_by_identity_map.read(identity);
            
            let mut i: u32 = 0;
            loop {
                if i >= count {
                    break;
                }
                
                // Get the address at the current index and add it to the array
                let addr = self.address_by_identity_index_map.read((identity, i));
                addresses.append(addr);
                
                i += 1;
            };
            
            addresses
        }
    }
    
    // Internal functions
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        fn _assert_only_registry(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.registry_map.read('registry'), 'Only registry can call');
        }
        
        fn _add_address_to_identity(ref self: ContractState, identity: felt252, address: ContractAddress) {
            let count = self.address_count_by_identity_map.read(identity);
            
            // Add address to identity's addresses
            self.address_by_identity_index_map.write((identity, count), address);
            
            // Increment counter
            self.address_count_by_identity_map.write(identity, count + 1);
        }
        
        fn _remove_address_from_identity(ref self: ContractState, identity: felt252, address: ContractAddress) {
            let count = self.address_count_by_identity_map.read(identity);
            if count == 0 {
                return;
            }
            
            // Find the index of the address in the array
            let mut index: u32 = 0;
            let mut found = false;
            
            loop {
                if index >= count {
                    break;
                }
                
                if self.address_by_identity_index_map.read((identity, index)) == address {
                    found = true;
                    break;
                }
                
                index += 1;
            };
            
            // If the address is found, remove it by replacing it with the last element and decrementing count
            if found {
                // If this is not the last element, move the last element to this index
                if index < count - 1 {
                    let last_address = self.address_by_identity_index_map.read((identity, count - 1));
                    self.address_by_identity_index_map.write((identity, index), last_address);
                }
                
                // Decrement counter
                self.address_count_by_identity_map.write(identity, count - 1);
            }
        }
    }
}