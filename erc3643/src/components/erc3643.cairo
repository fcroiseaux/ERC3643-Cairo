//! ERC3643 Component
//!
//! This component provides functionality for ERC3643 tokens, also known as the T-REX standard.
//! It adds regulatory compliance features on top of the standard ERC20 token.

use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
};
use core::array::ArrayTrait;
use core::traits::Into;
use core::array::Array;

// External interfaces
use crate::interfaces::icompliance::{IComplianceDispatcherTrait, IComplianceDispatcher};
use crate::interfaces::iidentity_registry::{IIdentityRegistryDispatcherTrait, IIdentityRegistryDispatcher};

// Event declarations
#[derive(Drop, starknet::Event)]
struct Frozen {
    address: ContractAddress,
}

#[derive(Drop, starknet::Event)]
struct Unfrozen {
    address: ContractAddress,
}

#[derive(Drop, starknet::Event)]
struct RecoverySuccess {
    from: ContractAddress,
    to: ContractAddress,
    amount: u256,
}

#[derive(Drop, starknet::Event)]
struct ComplianceAdded {
    compliance: ContractAddress,
}

#[derive(Drop, starknet::Event)]
struct IdentityRegistryAdded {
    identity_registry: ContractAddress,
}

#[derive(Drop, starknet::Event)]
struct AgentAdded {
    agent: ContractAddress,
}

#[derive(Drop, starknet::Event)]
struct AgentRemoved {
    agent: ContractAddress,
}

// Component storage
#[starknet::component]
pub mod ERC3643Component {
    use super::*;

    #[storage]
    struct Storage {
        // Contract addresses storage
        compliance_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'compliance' as key
        identity_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'registry' as key
        
        // Frozen addresses
        frozen_addresses: starknet::storage::Map::<ContractAddress, bool>,
        
        // Compliance agents
        agents: starknet::storage::Map::<ContractAddress, bool>,
        
        // Token metadata - only used if not already present in ERC20 component
        stored_name: starknet::storage::Map::<felt252, felt252>,  // Store name as felt252
        stored_symbol: starknet::storage::Map::<felt252, felt252>,  // Store symbol as felt252
    }

    // Events from the component
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Frozen: Frozen,
        Unfrozen: Unfrozen,
        RecoverySuccess: RecoverySuccess,
        ComplianceAdded: ComplianceAdded,
        IdentityRegistryAdded: IdentityRegistryAdded,
        AgentAdded: AgentAdded,
        AgentRemoved: AgentRemoved,
    }

    // External trait implementation
    #[embeddable_as(ERC3643TraitImpl)]
    pub impl ERC3643Impl<
        TContractState, 
        +HasComponent<TContractState>
    > of crate::interfaces::ierc3643::IERC3643<ComponentState<TContractState>> {
        
        // ERC3643 core functions
        fn forced_transfer(
            ref self: ComponentState<TContractState>, 
            from: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            assert(self.agents.read(caller), 'Only agents allowed');
            
            self._check_transfer_compliance(from, to, amount);
            
            // Check frozen status
            assert(!self.frozen_addresses.read(from), 'Sender address is frozen');
            assert(!self.frozen_addresses.read(to), 'Recipient address is frozen');
            
            // We'll assume the parent contract will handle the actual transfer
            // after compliance checks
            true
        }
        
        fn mint(ref self: ComponentState<TContractState>, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            assert(self.agents.read(caller), 'Only agents allowed');
            
            // Verify recipient has valid identity
            assert(self._is_verified_address(to), 'Recipient not verified');
            
            // We'll assume the parent contract will handle the actual minting
            true
        }
        
        fn burn(ref self: ComponentState<TContractState>, amount: u256) -> bool {
            // We'll assume the parent contract will handle the actual burning
            true
        }
        
        fn recover(
            ref self: ComponentState<TContractState>, 
            lost_address: ContractAddress, 
            amount: u256
        ) -> bool {
            // Only owner can recover tokens - this will be checked by the parent contract
            
            // Check if address is frozen
            assert(!self.frozen_addresses.read(lost_address), 'Address is frozen');
            
            let caller = get_caller_address();
            self.emit(RecoverySuccess { from: lost_address, to: caller, amount });
            true
        }
        
        fn freeze_address(
            ref self: ComponentState<TContractState>, 
            address_to_freeze: ContractAddress
        ) -> bool {
            self.set_address_frozen(address_to_freeze, true)
        }
        
        fn unfreeze_address(
            ref self: ComponentState<TContractState>, 
            address_to_unfreeze: ContractAddress
        ) -> bool {
            self.set_address_frozen(address_to_unfreeze, false)
        }
        
        fn set_address_frozen(
            ref self: ComponentState<TContractState>, 
            target_address: ContractAddress, 
            frozen: bool
        ) -> bool {
            let caller = get_caller_address();
            assert(self.agents.read(caller), 'Only agents allowed');
            
            self.frozen_addresses.write(target_address, frozen);
            
            if frozen {
                self.emit(Frozen { address: target_address });
            } else {
                self.emit(Unfrozen { address: target_address });
            }
            
            true
        }
        
        fn set_compliance(
            ref self: ComponentState<TContractState>, 
            compliance_address: ContractAddress
        ) -> bool {
            // Only owner can set compliance - this will be checked by the parent contract
            
            self.compliance_map.write('compliance', compliance_address);
            self.emit(ComplianceAdded { compliance: compliance_address });
            true
        }
        
        fn set_identity_registry(
            ref self: ComponentState<TContractState>, 
            identity_registry: ContractAddress
        ) -> bool {
            // Only owner can set identity registry - this will be checked by the parent contract
            
            self.identity_registry_map.write('registry', identity_registry);
            self.emit(IdentityRegistryAdded { identity_registry });
            true
        }
        
        fn is_verified_address(
            self: @ComponentState<TContractState>, 
            address: ContractAddress
        ) -> bool {
            self._is_verified_address(address)
        }
        
        fn is_compliance_agent(
            self: @ComponentState<TContractState>, 
            address: ContractAddress
        ) -> bool {
            self.agents.read(address)
        }
        
        fn is_frozen(
            self: @ComponentState<TContractState>, 
            address: ContractAddress
        ) -> bool {
            self.frozen_addresses.read(address)
        }
        
        fn add_agent(
            ref self: ComponentState<TContractState>, 
            agent: ContractAddress
        ) -> bool {
            // Only owner can add agents - this will be checked by the parent contract
            
            self.agents.write(agent, true);
            self.emit(AgentAdded { agent });
            true
        }
        
        fn remove_agent(
            ref self: ComponentState<TContractState>, 
            agent: ContractAddress
        ) -> bool {
            // Only owner can remove agents - this will be checked by the parent contract
            
            self.agents.write(agent, false);
            self.emit(AgentRemoved { agent });
            true
        }

        // ERC20 standard functions - will be implemented by the parent contract
        fn name(self: @ComponentState<TContractState>) -> felt252 {
            // Read from stored name
            let stored = self.stored_name.read('name');
            if stored != 0 {
                return stored;
            }
            'Token' // Default fallback
        }

        fn symbol(self: @ComponentState<TContractState>) -> felt252 {
            // Read from stored symbol
            let stored = self.stored_symbol.read('symbol');
            if stored != 0 {
                return stored;
            }
            'TKN' // Default fallback
        }
        
        fn decimals(self: @ComponentState<TContractState>) -> u8 {
            18 // Default value
        }
        
        fn total_supply(self: @ComponentState<TContractState>) -> u256 {
            0 // Will be implemented by parent contract
        }
        
        fn balance_of(self: @ComponentState<TContractState>, account: ContractAddress) -> u256 {
            0 // Will be implemented by parent contract
        }
        
        fn allowance(
            self: @ComponentState<TContractState>, 
            owner: ContractAddress, 
            spender: ContractAddress
        ) -> u256 {
            0 // Will be implemented by parent contract
        }
        
        fn transfer(
            ref self: ComponentState<TContractState>, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            // Check if sender is frozen
            let caller = get_caller_address();
            assert(!self.frozen_addresses.read(caller), 'Sender address is frozen');
            
            // Check if recipient is frozen
            assert(!self.frozen_addresses.read(to), 'Recipient address is frozen');
            
            // Check compliance for the transfer
            self._check_transfer_compliance(caller, to, amount);
            
            // The actual transfer will be handled by the parent contract
            true
        }
        
        fn transfer_from(
            ref self: ComponentState<TContractState>, 
            from: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            // Check if sender is frozen
            assert(!self.frozen_addresses.read(from), 'Sender address is frozen');
            
            // Check if recipient is frozen
            assert(!self.frozen_addresses.read(to), 'Recipient address is frozen');
            
            // Check compliance for the transfer
            self._check_transfer_compliance(from, to, amount);
            
            // The actual transfer will be handled by the parent contract
            true
        }
        
        fn approve(
            ref self: ComponentState<TContractState>, 
            spender: ContractAddress, 
            amount: u256
        ) -> bool {
            // The actual approval will be handled by the parent contract
            true
        }
    }

    // Internal implementation for components to use
    #[generate_trait]
    pub impl InternalImpl<
        TContractState, 
        +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            name: felt252,
            symbol: felt252,
            initial_owner: ContractAddress,
            compliance: ContractAddress,
            identity_registry: ContractAddress
        ) {
            // Initialize token metadata
            self.stored_name.write('name', name);
            self.stored_symbol.write('symbol', symbol);
            
            // Initialize registry addresses
            self.compliance_map.write('compliance', compliance);
            self.identity_registry_map.write('registry', identity_registry);
            
            // Add initial owner as an agent
            self.agents.write(initial_owner, true);
        }
        
        fn _check_transfer_compliance(
            ref self: ComponentState<TContractState>, 
            from: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) {
            // Check if sender and recipient have verified identities
            assert(self._is_verified_address(from), 'Sender identity not verified');
            assert(self._is_verified_address(to), 'Recipient identity not verified');
            
            // Check if transfer complies with rules
            let compliance_contract = self.compliance_map.read('compliance');
            
            // Call the compliance contract
            let compliance_dispatcher = IComplianceDispatcher { contract_address: compliance_contract };
            let compliant = compliance_dispatcher.check_compliance(from, to, amount);
            assert(compliant, 'Transfer not compliant');
        }
        
        fn _is_verified_address(
            self: @ComponentState<TContractState>, 
            address: ContractAddress
        ) -> bool {
            let identity_registry = self.identity_registry_map.read('registry');
            
            // Call identity registry to check if address is verified
            let registry_dispatcher = IIdentityRegistryDispatcher { contract_address: identity_registry };
            registry_dispatcher.is_verified_address(address)
        }
    }
}