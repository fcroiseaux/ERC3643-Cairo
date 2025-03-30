//! Identity Registry Component
//!
//! This component manages investor identities, including verification and checks.

use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
};
use core::array::Array;

// External interfaces
use crate::interfaces::iidentity_storage::{IIdentityStorageDispatcherTrait, IIdentityStorageDispatcher};
use crate::interfaces::iclaim_topics_registry::{IClaimTopicsRegistryDispatcherTrait, IClaimTopicsRegistryDispatcher};
use crate::interfaces::itrusted_issuers_registry::{ITrustedIssuersRegistryDispatcherTrait, ITrustedIssuersRegistryDispatcher};

// Event declarations
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

// Component implementation
#[starknet::component]
pub mod IdentityRegistryComponent {
    use super::*;

    // Constants
    const AGENT_ROLE: felt252 = selector!("AGENT_ROLE");
    const DEFAULT_ADMIN_ROLE: felt252 = 0;

    #[storage]
    struct Storage {
        // Custom role management (simplified from AccessControl)
        roles_map: starknet::storage::Map::<(felt252, ContractAddress), bool>, // (role, account) => has_role
        
        // Contract address storage
        identity_storage_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'identity_storage' as key
        claim_topics_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'claim_topics_registry' as key
        trusted_issuers_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'trusted_issuers_registry' as key
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        IdentityRegistered: IdentityRegistered,
        IdentityUpdated: IdentityUpdated,
        CountryUpdated: CountryUpdated,
        IdentityRemoved: IdentityRemoved,
        IdentityStorageSet: IdentityStorageSet,
        ClaimTopicsRegistrySet: ClaimTopicsRegistrySet,
        TrustedIssuersRegistrySet: TrustedIssuersRegistrySet,
    }

    // External interface implementation
    #[embeddable_as(IdentityRegistryTraitImpl)]
    pub impl IdentityRegistryImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of crate::interfaces::iidentity_registry::IIdentityRegistry<ComponentState<TContractState>> {
        
        // Identity management functions
        fn register_identity(
            ref self: ComponentState<TContractState>, 
            user_address: ContractAddress, 
            identity: felt252, 
            country: felt252
        ) -> bool {
            // Only agent can register identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.register_identity(user_address, identity, country);
            
            // Emit event
            self.emit(IdentityRegistered { user_address, identity });
            
            true
        }
        
        fn update_identity(
            ref self: ComponentState<TContractState>, 
            user_address: ContractAddress, 
            identity: felt252
        ) -> bool {
            // Only agent can update identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.update_identity(user_address, identity);
            
            // Emit event
            self.emit(IdentityUpdated { user_address, identity });
            
            true
        }
        
        fn update_country(
            ref self: ComponentState<TContractState>, 
            user_address: ContractAddress, 
            country: felt252
        ) -> bool {
            // Only agent can update country
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.update_country(user_address, country);
            
            // Emit event
            self.emit(CountryUpdated { user_address, country });
            
            true
        }
        
        fn delete_identity(
            ref self: ComponentState<TContractState>, 
            user_address: ContractAddress
        ) -> bool {
            // Only agent can delete identity
            self._assert_only_agent();
            
            // Call identity storage contract
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.delete_identity(user_address);
            
            // Emit event
            self.emit(IdentityRemoved { user_address });
            
            true
        }
        
        fn set_identity_storage(
            ref self: ComponentState<TContractState>, 
            identity_storage: ContractAddress
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Set identity storage
            self.identity_storage_map.write('identity_storage', identity_storage);
            
            // Emit event
            self.emit(IdentityStorageSet { identity_storage });
            
            true
        }
        
        fn set_claim_topics_registry(
            ref self: ComponentState<TContractState>, 
            claim_topics_registry: ContractAddress
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Set claim topics registry
            self.claim_topics_registry_map.write('claim_topics_registry', claim_topics_registry);
            
            // Emit event
            self.emit(ClaimTopicsRegistrySet { claim_topics_registry });
            
            true
        }
        
        fn set_trusted_issuers_registry(
            ref self: ComponentState<TContractState>, 
            trusted_issuers_registry: ContractAddress
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Set trusted issuers registry
            self.trusted_issuers_registry_map.write('trusted_issuers_registry', trusted_issuers_registry);
            
            // Emit event
            self.emit(TrustedIssuersRegistrySet { trusted_issuers_registry });
            
            true
        }
        
        fn get_identity(
            self: @ComponentState<TContractState>, 
            user_address: ContractAddress
        ) -> felt252 {
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.get_identity(user_address)
        }
        
        fn get_country(
            self: @ComponentState<TContractState>, 
            user_address: ContractAddress
        ) -> felt252 {
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            storage_dispatcher.get_country(user_address)
        }
        
        fn is_verified_address(
            self: @ComponentState<TContractState>, 
            user_address: ContractAddress
        ) -> bool {
            // Get identity for the address
            let identity = self.get_identity(user_address);
            
            // If no identity, address is not verified
            if identity == 0 {
                return false;
            }
            
            // Check if identity has valid claims
            self.is_identity_verified(identity)
        }
        
        fn is_identity_verified(
            self: @ComponentState<TContractState>, 
            identity: felt252
        ) -> bool {
            // If identity doesn't exist, it's not verified
            if !self.identity_exists(identity) {
                return false;
            }
            
            // Get required claim topics
            let claim_topics_registry = self.get_claim_topics_registry();
            let topics_dispatcher = IClaimTopicsRegistryDispatcher { contract_address: claim_topics_registry };
            let required_claim_topics = topics_dispatcher.get_claim_topics();
            
            if required_claim_topics.len() == 0 {
                // If no required topics, identity is verified
                return true;
            }
            
            // Get trusted issuers
            let trusted_issuers_registry = self.get_trusted_issuers_registry();
            let issuers_dispatcher = ITrustedIssuersRegistryDispatcher { contract_address: trusted_issuers_registry };
            let trusted_issuers = issuers_dispatcher.get_trusted_issuers();
            
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
                
                // Check if issuer has all required claim topics
                let mut has_all_topics = true;
                let mut j: usize = 0;
                let required_topics_len = required_claim_topics.len();
                
                loop {
                    if j >= required_topics_len {
                        break;
                    }
                    
                    let topic = *required_claim_topics.at(j);
                    let has_topic = issuers_dispatcher.has_claim_topic(issuer, topic);
                    
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
        
        fn identity_exists(
            self: @ComponentState<TContractState>, 
            identity: felt252
        ) -> bool {
            // Identity exists if there's at least one address associated with it
            let identity_storage = self.get_identity_storage();
            let storage_dispatcher = IIdentityStorageDispatcher { contract_address: identity_storage };
            let addresses = storage_dispatcher.get_addresses_by_identity(identity);
                
            addresses.len() > 0
        }
    }

    // Role management functions - simplified from AccessControl
    #[generate_trait]
    pub impl RoleManagementImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of RoleManagementTrait<TContractState> {
        fn has_role(
            self: @ComponentState<TContractState>, 
            role: felt252, 
            account: ContractAddress
        ) -> bool {
            // Simplified implementation - directly check the roles map
            self.roles_map.read((role, account))
        }
        
        fn grant_role(
            ref self: ComponentState<TContractState>, 
            role: felt252, 
            account: ContractAddress
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Grant role directly in the roles map
            self.roles_map.write((role, account), true);
            true
        }
        
        fn revoke_role(
            ref self: ComponentState<TContractState>, 
            role: felt252, 
            account: ContractAddress
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Revoke role directly in the roles map
            self.roles_map.write((role, account), false);
            true
        }
        
        fn get_role_admin(
            self: @ComponentState<TContractState>, 
            role: felt252
        ) -> felt252 {
            // Simplified implementation - all roles have DEFAULT_ADMIN_ROLE as admin
            DEFAULT_ADMIN_ROLE
        }
        
        fn set_role_admin(
            ref self: ComponentState<TContractState>, 
            role: felt252, 
            admin_role: felt252
        ) -> bool {
            // Owner check should be done by the parent contract
            
            // Simplified implementation - placeholder
            true
        }
    }

    // Internal implementation
    #[generate_trait]
    pub impl InternalImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            initial_owner: ContractAddress,
            identity_storage: ContractAddress,
            claim_topics_registry: ContractAddress,
            trusted_issuers_registry: ContractAddress
        ) {
            // Grant AGENT_ROLE to initial owner
            self.roles_map.write((AGENT_ROLE, initial_owner), true);
            
            // Set contract addresses
            self.identity_storage_map.write('identity_storage', identity_storage);
            self.claim_topics_registry_map.write('claim_topics_registry', claim_topics_registry);
            self.trusted_issuers_registry_map.write('trusted_issuers_registry', trusted_issuers_registry);
        }
        
        fn _assert_only_agent(self: @ComponentState<TContractState>) {
            // Check if the caller has the AGENT_ROLE
            let caller = get_caller_address();
            assert(self.roles_map.read((AGENT_ROLE, caller)), 'Only agents allowed');
        }
        
        // Helper functions to read contract addresses
        fn get_identity_storage(self: @ComponentState<TContractState>) -> ContractAddress {
            self.identity_storage_map.read('identity_storage')
        }
        
        fn get_claim_topics_registry(self: @ComponentState<TContractState>) -> ContractAddress {
            self.claim_topics_registry_map.read('claim_topics_registry')
        }
        
        fn get_trusted_issuers_registry(self: @ComponentState<TContractState>) -> ContractAddress {
            self.trusted_issuers_registry_map.read('trusted_issuers_registry')
        }
    }
}