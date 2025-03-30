//! ERC3643 Token Implementation Example
//!
//! This is an example implementation of an ERC3643 token using the reusable components.

use starknet::{
    ContractAddress, 
    get_caller_address,
};
use openzeppelin::token::erc20::ERC20Component;
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::security::pausable::PausableComponent;
use crate::components::erc3643::ERC3643Component;

// Import interfaces
use crate::interfaces::ierc3643::IERC3643;

#[starknet::contract]
pub mod ERC3643TokenExample {
    use super::*;
    
    // Component declarations - not using the events for our custom components
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: ERC3643Component, storage: erc3643);  // No event import needed
    
    // Implement component interfaces
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl ERC3643Impl = ERC3643Component::ERC3643Impl<ContractState>;
    impl ERC3643InternalImpl = ERC3643Component::InternalImpl<ContractState>;
    impl ERC3643TraitImpl = ERC3643Component::ERC3643TraitImpl<ContractState>;
    
    // Required to satisfy OpenZeppelin's ERC20 internals
    impl ERC20HooksImpl of ERC20Component::ERC20HooksTrait<ContractState> {
        fn before_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {}
        
        fn after_update(
            ref self: ERC20Component::ComponentState<ContractState>,
            from: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {}
    }
    
    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        PausableEvent: PausableComponent::Event,
    }
    
    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        
        #[substorage(v0)]
        erc3643: ERC3643Component::Storage,
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        initial_owner: ContractAddress,
        compliance: ContractAddress,
        identity_registry: ContractAddress
    ) {
        // Initialize ERC20 component
        self.erc20.initializer(name, symbol);
        
        // Initialize Ownable component
        self.ownable.initializer(initial_owner);
        
        // Initialize Pausable component
        self.pausable.initializer();
        
        // Initialize ERC3643 component
        self.erc3643.initializer(name, symbol, initial_owner, compliance, identity_registry);
    }
    
    // Implement the IERC3643 interface directly in the contract
    #[external(v0)]
    impl ERC3643TokenImpl of IERC3643<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            // Return the name from the ERC20 component
            let result = self.erc3643.name();
            result
        }
        
        fn symbol(self: @ContractState) -> felt252 {
            // Return the symbol from the ERC20 component
            let result = self.erc3643.symbol();
            result
        }
        
        fn decimals(self: @ContractState) -> u8 {
            // Return the decimals from the ERC20 component
            let result = self.erc3643.decimals();
            result
        }
        
        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }
        
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }
        
        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.erc20.allowance(owner, spender)
        }
        
        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            // First check regulatory compliance with ERC3643 component
            let compliance_ok = self.erc3643.transfer(to, amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual transfer
            let caller = get_caller_address();
            self.erc20._transfer(caller, to, amount);
            true
        }
        
        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            // First check regulatory compliance with ERC3643 component
            let compliance_ok = self.erc3643.transfer_from(from, to, amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual transfer
            let caller = get_caller_address();
            
            // Check and update allowance
            let current_allowance = self.erc20.allowance(from, caller);
            assert(current_allowance >= amount, 'Insufficient allowance');
            self.erc20._approve(from, caller, current_allowance - amount);
            
            // Execute transfer
            self.erc20._transfer(from, to, amount);
            true
        }
        
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self.erc20._approve(caller, spender, amount);
            true
        }
        
        fn forced_transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            // First check regulatory compliance with ERC3643 component
            let compliance_ok = self.erc3643.forced_transfer(from, to, amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual transfer
            self.erc20._transfer(from, to, amount);
            true
        }
        
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            // First check regulatory compliance with ERC3643 component
            let compliance_ok = self.erc3643.mint(to, amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual minting
            self.erc20._mint(to, amount);
            true
        }
        
        fn burn(ref self: ContractState, amount: u256) -> bool {
            // Get compliance check from ERC3643 component
            let compliance_ok = self.erc3643.burn(amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual burning
            let caller = get_caller_address();
            self.erc20._burn(caller, amount);
            true
        }
        
        fn recover(ref self: ContractState, lost_address: ContractAddress, amount: u256) -> bool {
            // Only owner can recover tokens
            self.ownable.assert_only_owner();
            
            // First check regulatory compliance with ERC3643 component
            let compliance_ok = self.erc3643.recover(lost_address, amount);
            assert(compliance_ok, 'Compliance check failed');
            
            // If compliance is ok, perform the actual transfer
            let owner = self.ownable.owner();
            self.erc20._transfer(lost_address, owner, amount);
            true
        }
        
        fn freeze_address(ref self: ContractState, address_to_freeze: ContractAddress) -> bool {
            self.erc3643.freeze_address(address_to_freeze)
        }
        
        fn unfreeze_address(ref self: ContractState, address_to_unfreeze: ContractAddress) -> bool {
            self.erc3643.unfreeze_address(address_to_unfreeze)
        }
        
        fn set_address_frozen(ref self: ContractState, target_address: ContractAddress, frozen: bool) -> bool {
            self.erc3643.set_address_frozen(target_address, frozen)
        }
        
        fn set_compliance(ref self: ContractState, compliance_address: ContractAddress) -> bool {
            // Only owner can set compliance
            self.ownable.assert_only_owner();
            self.erc3643.set_compliance(compliance_address)
        }
        
        fn set_identity_registry(ref self: ContractState, identity_registry: ContractAddress) -> bool {
            // Only owner can set identity registry
            self.ownable.assert_only_owner();
            self.erc3643.set_identity_registry(identity_registry)
        }
        
        fn is_verified_address(self: @ContractState, address: ContractAddress) -> bool {
            self.erc3643.is_verified_address(address)
        }
        
        fn is_compliance_agent(self: @ContractState, address: ContractAddress) -> bool {
            self.erc3643.is_compliance_agent(address)
        }
        
        fn is_frozen(self: @ContractState, address: ContractAddress) -> bool {
            self.erc3643.is_frozen(address)
        }
        
        fn add_agent(ref self: ContractState, agent: ContractAddress) -> bool {
            // Only owner can add agents
            self.ownable.assert_only_owner();
            self.erc3643.add_agent(agent)
        }
        
        fn remove_agent(ref self: ContractState, agent: ContractAddress) -> bool {
            // Only owner can remove agents
            self.ownable.assert_only_owner();
            self.erc3643.remove_agent(agent)
        }
    }
    
    // Additional methods for pausable functionality
    #[external(v0)]
    impl PausableTokenImpl of IPausableToken<ContractState> {
        fn pause(ref self: ContractState) -> bool {
            self.ownable.assert_only_owner();
            self.pausable.pause();
            true
        }
        
        fn unpause(ref self: ContractState) -> bool {
            self.ownable.assert_only_owner();
            self.pausable.unpause();
            true
        }
        
        fn is_paused(self: @ContractState) -> bool {
            self.pausable.is_paused()
        }
    }
}

// Define the pausable interface here for simplicity
#[starknet::interface]
pub trait IPausableToken<TContractState> {
    fn pause(ref self: TContractState) -> bool;
    fn unpause(ref self: TContractState) -> bool;
    fn is_paused(self: @TContractState) -> bool;
}