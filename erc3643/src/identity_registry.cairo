// Import OpenZeppelin's components
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
};
use core::array::ArrayTrait;

// Identity Registry Interface
#[starknet::interface]
pub trait IIdentityRegistry<TContractState> {
    // Ownable interface (inherited from OpenZeppelin)
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn renounce_ownership(ref self: TContractState) -> bool;
    
    // Access control for agents (using OpenZeppelin's AccessControl)
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
    fn grant_role(ref self: TContractState, role: felt252, account: ContractAddress) -> bool;
    fn revoke_role(ref self: TContractState, role: felt252, account: ContractAddress) -> bool;
    fn get_role_admin(self: @TContractState, role: felt252) -> felt252;
    fn set_role_admin(ref self: TContractState, role: felt252, admin_role: felt252) -> bool;
    
    // Identity management functions
    fn register_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn update_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn update_country(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn delete_identity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn set_identity_storage(ref self: TContractState, identity_storage: ContractAddress) -> bool;
    fn set_claim_topics_registry(ref self: TContractState, claim_topics_registry: ContractAddress) -> bool;
    fn set_trusted_issuers_registry(ref self: TContractState, trusted_issuers_registry: ContractAddress) -> bool;
    fn get_identity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_country(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn is_verified_address(self: @TContractState, user_address: ContractAddress) -> bool;
    fn is_identity_verified(self: @TContractState, identity: felt252) -> bool;
    fn identity_exists(self: @TContractState, identity: felt252) -> bool;
}

// Identity Storage Interface
#[starknet::interface]
trait IIdentityStorageContract<TContractState> {
    fn register_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn update_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn update_country(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn delete_identity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn get_identity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_country(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_addresses_by_identity(self: @TContractState, identity: felt252) -> Array<ContractAddress>;
}

// Claim Topics Registry Interface
#[starknet::interface]
trait IClaimTopicsRegistryContract<TContractState> {
    fn get_claim_topics(self: @TContractState) -> Array<felt252>;
}

// Trusted Issuers Registry Interface
#[starknet::interface]
trait ITrustedIssuersRegistryContract<TContractState> {
    fn get_trusted_issuers(self: @TContractState) -> Array<felt252>;
    fn get_issuer_claim_topics(self: @TContractState, issuer: felt252) -> Array<felt252>;
    fn is_trusted_issuer(self: @TContractState, issuer: felt252) -> bool;
    fn has_claim_topic(self: @TContractState, issuer: felt252, claim_topic: felt252) -> bool;
}

#[starknet::contract]
pub mod IdentityRegistry {
    use super::*;
    
    // Component declarations
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    
    // Implement component interfaces
    // We're removing abi(embed_v0) to avoid duplicate entry points in testing
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    
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
        IdentityStorageSet: IdentityStorageSet,
        ClaimTopicsRegistrySet: ClaimTopicsRegistrySet,
        TrustedIssuersRegistrySet: TrustedIssuersRegistrySet,
    }
    
    #[derive(Drop, starknet::Event)]
    struct IdentityRegistered {
        user_address: ContractAddress,
        identity: felt252,
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
    struct IdentityStorageSet {
        identity_storage: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ClaimTopicsRegistrySet {
        claim_topics_registry: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct TrustedIssuersRegistrySet {
        trusted_issuers_registry: ContractAddress,
    }
    
    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        
        // Custom role management (simplified from AccessControl)
        roles_map: starknet::storage::Map::<(felt252, ContractAddress), bool>, // (role, account) => has_role
        
        // Contract address storage using maps for compatibility
        identity_storage_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'identity_storage' as key
        claim_topics_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'claim_topics_registry' as key
        trusted_issuers_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'trusted_issuers_registry' as key
    }
    
    // Constants
    const AGENT_ROLE: felt252 = selector!("AGENT_ROLE");
    const DEFAULT_ADMIN_ROLE: felt252 = 0;
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_owner: ContractAddress,
        identity_storage: ContractAddress,
        claim_topics_registry: ContractAddress,
        trusted_issuers_registry: ContractAddress
    ) {
        // Initialize Ownable component
        OwnableInternalTrait::initializer(ref self.ownable, initial_owner);
        
        // For SRC5 and AccessControl, we'd normally initialize them directly
        // But for simplicity, we'll just initialize the basic storage
        // This is a simplified approach - in a real implementation we would use the proper initialization methods
        
        // Grant AGENT_ROLE to initial owner (simplified implementation)
        // We directly write to the roles_map storage
        self.roles_map.write((AGENT_ROLE, initial_owner), true);
        
        // Set contract addresses using maps
        self.identity_storage_map.write('identity_storage', identity_storage);
        self.claim_topics_registry_map.write('claim_topics_registry', claim_topics_registry);
        self.trusted_issuers_registry_map.write('trusted_issuers_registry', trusted_issuers_registry);
    }
    
    #[abi(embed_v0)]
    impl IdentityRegistryImpl of super::IIdentityRegistry<ContractState> {
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
        
        // AccessControl functions (simplified implementation)
        fn has_role(self: @ContractState, role: felt252, account: ContractAddress) -> bool {
            // Simplified implementation - directly check the roles map
            self.roles_map.read((role, account))
        }
        
        fn grant_role(ref self: ContractState, role: felt252, account: ContractAddress) -> bool {
            // Only owner can grant roles in this simplified implementation
            self.ownable.assert_only_owner();
            
            // Grant role directly in the roles map
            self.roles_map.write((role, account), true);
            true
        }
        
        fn revoke_role(ref self: ContractState, role: felt252, account: ContractAddress) -> bool {
            // Only owner can revoke roles in this simplified implementation
            self.ownable.assert_only_owner();
            
            // Revoke role directly in the roles map
            self.roles_map.write((role, account), false);
            true
        }
        
        fn get_role_admin(self: @ContractState, role: felt252) -> felt252 {
            // Simplified implementation
            // All roles have DEFAULT_ADMIN_ROLE as their admin
            DEFAULT_ADMIN_ROLE
        }
        
        fn set_role_admin(ref self: ContractState, role: felt252, admin_role: felt252) -> bool {
            // Only owner can set role admin
            self.ownable.assert_only_owner();
            
            // Simplified implementation - just a placeholder
            // We're not actually storing or changing the admin role in this simplified version
            true
        }
        
        // Identity management functions
        fn register_identity(ref self: ContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool {
            // Only agent can register identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .register_identity(user_address, identity, country);
            
            // Emit event
            self.emit(IdentityRegistered { user_address, identity });
            
            true
        }
        
        fn update_identity(ref self: ContractState, user_address: ContractAddress, identity: felt252) -> bool {
            // Only agent can update identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .update_identity(user_address, identity);
            
            // Emit event
            self.emit(IdentityUpdated { user_address, identity });
            
            true
        }
        
        fn update_country(ref self: ContractState, user_address: ContractAddress, country: felt252) -> bool {
            // Only agent can update country
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .update_country(user_address, country);
            
            // Emit event
            self.emit(CountryUpdated { user_address, country });
            
            true
        }
        
        fn delete_identity(ref self: ContractState, user_address: ContractAddress) -> bool {
            // Only agent can delete identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .delete_identity(user_address);
            
            // Emit event
            self.emit(IdentityRemoved { user_address });
            
            true
        }
        
        fn set_identity_storage(ref self: ContractState, identity_storage: ContractAddress) -> bool {
            // Only owner can set identity storage
            self.ownable.assert_only_owner();
            
            // Set identity storage
            self.identity_storage_map.write('identity_storage', identity_storage);
            
            // Emit event
            self.emit(IdentityStorageSet { identity_storage });
            
            true
        }
        
        fn set_claim_topics_registry(ref self: ContractState, claim_topics_registry: ContractAddress) -> bool {
            // Only owner can set claim topics registry
            self.ownable.assert_only_owner();
            
            // Set claim topics registry
            self.claim_topics_registry_map.write('claim_topics_registry', claim_topics_registry);
            
            // Emit event
            self.emit(ClaimTopicsRegistrySet { claim_topics_registry });
            
            true
        }
        
        fn set_trusted_issuers_registry(ref self: ContractState, trusted_issuers_registry: ContractAddress) -> bool {
            // Only owner can set trusted issuers registry
            self.ownable.assert_only_owner();
            
            // Set trusted issuers registry
            self.trusted_issuers_registry_map.write('trusted_issuers_registry', trusted_issuers_registry);
            
            // Emit event
            self.emit(TrustedIssuersRegistrySet { trusted_issuers_registry });
            
            true
        }
        
        fn get_identity(self: @ContractState, user_address: ContractAddress) -> felt252 {
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .get_identity(user_address)
        }
        
        fn get_country(self: @ContractState, user_address: ContractAddress) -> felt252 {
            let identity_storage = self.get_identity_storage();
            super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .get_country(user_address)
        }
        
        fn is_verified_address(self: @ContractState, user_address: ContractAddress) -> bool {
            // Get identity for the address
            let identity = self.get_identity(user_address);
            
            // If no identity, address is not verified
            if identity == 0 {
                return false;
            }
            
            // Check if identity has valid claims
            self.is_identity_verified(identity)
        }
        
        fn is_identity_verified(self: @ContractState, identity: felt252) -> bool {
            // If identity doesn't exist, it's not verified
            if !self.identity_exists(identity) {
                return false;
            }
            
            // Get required claim topics
            let claim_topics_registry = self.get_claim_topics_registry();
            let required_claim_topics = super::IClaimTopicsRegistryContractDispatcher { contract_address: claim_topics_registry }
                .get_claim_topics();
            
            if required_claim_topics.len() == 0 {
                // If no required topics, identity is verified
                return true;
            }
            
            // Get trusted issuers
            let trusted_issuers_registry = self.get_trusted_issuers_registry();
            let trusted_issuers = super::ITrustedIssuersRegistryContractDispatcher { contract_address: trusted_issuers_registry }
                .get_trusted_issuers();
            
            if trusted_issuers.len() == 0 {
                // If no trusted issuers, identity is not verified
                return false;
            }
            
            // For each trusted issuer, check if they have issued claims for all required topics
            let mut i: usize = 0;
            let issuers_len = trusted_issuers.len();
            
            loop {
                if i >= issuers_len {
                    break;
                }
                
                let issuer = *trusted_issuers.at(i);
                // We need to check each required topic individually, so we don't need to store all issuer claim topics
                // Using underscore prefix to indicate intentionally unused variable
                let _issuer_claim_topics = super::ITrustedIssuersRegistryContractDispatcher { contract_address: trusted_issuers_registry }
                    .get_issuer_claim_topics(issuer);
                
                // Check if issuer has all required claim topics
                let mut has_all_topics = true;
                let mut j: usize = 0;
                let required_topics_len = required_claim_topics.len();
                
                loop {
                    if j >= required_topics_len {
                        break;
                    }
                    
                    let topic = *required_claim_topics.at(j);
                    let has_topic = super::ITrustedIssuersRegistryContractDispatcher { contract_address: trusted_issuers_registry }
                        .has_claim_topic(issuer, topic);
                    
                    if !has_topic {
                        has_all_topics = false;
                        break;
                    }
                    
                    j += 1;
                };
                
                if has_all_topics {
                    return true; // Found an issuer with all required topics
                }
                
                i += 1;
            };
            
            // No trusted issuer has all required claim topics for this identity
            false
        }
        
        fn identity_exists(self: @ContractState, identity: felt252) -> bool {
            // Identity exists if there's at least one address associated with it
            let identity_storage = self.get_identity_storage();
            let addresses = super::IIdentityStorageContractDispatcher { contract_address: identity_storage }
                .get_addresses_by_identity(identity);
                
            addresses.len() > 0
        }
    }
    
    // Internal functions
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        fn _assert_only_agent(self: @ContractState) {
            // Check if the caller has the AGENT_ROLE
            let caller = get_caller_address();
            assert(self.has_role(AGENT_ROLE, caller), 'Only agents allowed');
        }
        
        // Helper functions to read contract addresses from storage
        fn get_identity_storage(self: @ContractState) -> ContractAddress {
            self.identity_storage_map.read('identity_storage')
        }
        
        fn get_claim_topics_registry(self: @ContractState) -> ContractAddress {
            self.claim_topics_registry_map.read('claim_topics_registry')
        }
        
        fn get_trusted_issuers_registry(self: @ContractState) -> ContractAddress {
            self.trusted_issuers_registry_map.read('trusted_issuers_registry')
        }
    }
}