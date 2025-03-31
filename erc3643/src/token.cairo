// Import OpenZeppelin's components
use openzeppelin::token::erc20::ERC20Component;
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::security::pausable::PausableComponent;
use openzeppelin::utils::nonces::NoncesComponent;
use openzeppelin::utils::cryptography::snip12::SNIP12Metadata;
use starknet::{
    ContractAddress, 
    get_caller_address,
    syscalls::call_contract_syscall,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
};
use core::array::ArrayTrait;
use core::traits::Into;
use core::byte_array::ByteArray;

// Token Interface
#[starknet::interface]
pub trait IERC3643Token<TContractState> {
    // ERC20 standard functions (inherited from OpenZeppelin)
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    
    // ERC20 camelCase functions (OpenZeppelin v2.0.0 supports these directly)
    fn totalSupply(self: @TContractState) -> u256;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn transferFrom(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    
    // ERC2612 permit functions
    fn permit(
        ref self: TContractState,
        owner: ContractAddress,
        spender: ContractAddress,
        amount: u256,
        deadline: u64,
        signature: Span<felt252>
    );
    fn nonces(self: @TContractState, owner: ContractAddress) -> felt252;
    fn DOMAIN_SEPARATOR(self: @TContractState) -> felt252;
    
    // Pausable interface (inherited from OpenZeppelin)
    fn pause(ref self: TContractState) -> bool;
    fn unpause(ref self: TContractState) -> bool;
    fn is_paused(self: @TContractState) -> bool;
    
    // Ownable interface (inherited from OpenZeppelin)
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn renounce_ownership(ref self: TContractState) -> bool;
    
    // ERC3643 extended functions
    fn forced_transfer(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn mint(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn burn(ref self: TContractState, amount: u256) -> bool;
    fn recover(ref self: TContractState, lost_address: ContractAddress, amount: u256) -> bool;
    fn freeze_address(ref self: TContractState, address_to_freeze: ContractAddress) -> bool;
    fn unfreeze_address(ref self: TContractState, address_to_unfreeze: ContractAddress) -> bool;
    fn set_address_frozen(ref self: TContractState, target_address: ContractAddress, frozen: bool) -> bool;
    fn set_compliance(ref self: TContractState, compliance_address: ContractAddress) -> bool;
    fn set_identity_registry(ref self: TContractState, identity_registry: ContractAddress) -> bool;
    fn is_verified_address(self: @TContractState, address: ContractAddress) -> bool;
    fn is_compliance_agent(self: @TContractState, address: ContractAddress) -> bool;
    fn is_frozen(self: @TContractState, address: ContractAddress) -> bool;
    fn add_agent(ref self: TContractState, agent: ContractAddress) -> bool;
    fn remove_agent(ref self: TContractState, agent: ContractAddress) -> bool;
}

#[starknet::contract]
pub mod ERC3643Token {
    use super::*;
    
    // Component declarations
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: NoncesComponent, storage: nonces, event: NoncesEvent);

    // Implement component interfaces
    // We're removing abi(embed_v0) to avoid duplicate entry points in testing
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl NoncesImpl = NoncesComponent::NoncesImpl<ContractState>;
    impl NoncesInternalImpl = NoncesComponent::InternalImpl<ContractState>;
    
    // Implement ImmutableConfig trait required for OpenZeppelin v2.0.0
    // In v2.0.0, ImmutableConfig is a trait with constants
    impl ERC20Config of ERC20Component::ImmutableConfig {
        const DECIMALS: u8 = 18;
    }
    
    // Implement SNIP12Metadata for ERC2612 permit functionality
    impl ERC3643TokenSNIP12Metadata of SNIP12Metadata {
        fn name() -> felt252 {
            'ERC3643Token'
        }
        
        fn version() -> felt252 {
            '1'
        }
    }
    
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
        #[flat]
        NoncesEvent: NoncesComponent::Event,
        Frozen: Frozen,
        Unfrozen: Unfrozen,
        RecoverySuccess: RecoverySuccess,
        ComplianceAdded: ComplianceAdded,
        IdentityRegistryAdded: IdentityRegistryAdded,
        AgentAdded: AgentAdded,
        AgentRemoved: AgentRemoved,
    }
    
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
        nonces: NoncesComponent::Storage,
        
        // ERC3643 additional storage using maps to avoid direct storage access issues
        compliance_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'compliance' as key
        identity_registry_map: starknet::storage::Map::<felt252, ContractAddress>,  // Using 'registry' as key
        frozen_addresses: starknet::storage::Map::<ContractAddress, bool>,
        agents: starknet::storage::Map::<ContractAddress, bool>,
    }
    
    // Constants
    const AGENT_ROLE: felt252 = selector!("AGENT_ROLE");
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        initial_owner: ContractAddress,
        compliance: ContractAddress,
        identity_registry: ContractAddress
    ) {
        // Initialize ERC20 component with name and symbol 
        // In OpenZeppelin v2.0.0, the name and symbol must be ByteArray
        let name_bytes: ByteArray = "Token";
        let symbol_bytes: ByteArray = "TKN";
        self.erc20.initializer(name_bytes, symbol_bytes);
        
        // Initialize owner
        self.ownable.initializer(initial_owner);
        
        // Initialize the pausable component 
        // No explicit initializer needed for Pausable in v2.0.0
        
        // Initialize ERC3643 specific storage using maps
        self.compliance_map.write('compliance', compliance);
        self.identity_registry_map.write('registry', identity_registry);
        
        // Add initial owner as an agent
        self.agents.write(initial_owner, true);
    }
    
    #[abi(embed_v0)]
    impl ERC3643TokenImpl of super::IERC3643Token<ContractState> {
        // ERC20 functions
        fn name(self: @ContractState) -> felt252 {
            'Token'
        }

        fn symbol(self: @ContractState) -> felt252 {
            'TKN'
        }

        fn decimals(self: @ContractState) -> u8 {
            // Use the value from our ImmutableConfig implementation
            // In OpenZeppelin v2.0.0, decimals comes from ImmutableConfig
            18
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
            // Check if contract is paused using OpenZeppelin's pausable component
            self.pausable.assert_not_paused();
            
            // Check if sender is frozen
            let caller = get_caller_address();
            assert(!self.frozen_addresses.read(caller), 'Sender frozen');
            
            // Check if recipient is frozen
            assert(!self.frozen_addresses.read(to), 'Recipient frozen');
            
            // Check compliance for the transfer
            self._check_transfer_compliance(caller, to, amount);
            
            // Perform the transfer using ERC20 component
            self.erc20.transfer(to, amount)
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            // Check if contract is paused using OpenZeppelin's pausable component
            self.pausable.assert_not_paused();
            
            // Check if sender is frozen
            assert(!self.frozen_addresses.read(from), 'Sender frozen');
            
            // Check if recipient is frozen
            assert(!self.frozen_addresses.read(to), 'Recipient frozen');
            
            // Check compliance for the transfer
            self._check_transfer_compliance(from, to, amount);
            
            // Perform the transfer using ERC20 component
            self.erc20.transfer_from(from, to, amount)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }
        
        // ERC20 camelCase functions
        fn totalSupply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }
        
        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }
        
        fn transferFrom(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            // Direct implementation to avoid ambiguity
            // Check if contract is paused using OpenZeppelin's pausable component
            self.pausable.assert_not_paused();
            
            // Check if sender is frozen
            assert(!self.frozen_addresses.read(from), 'Sender frozen');
            
            // Check if recipient is frozen
            assert(!self.frozen_addresses.read(to), 'Recipient frozen');
            
            // Check compliance for the transfer
            self._check_transfer_compliance(from, to, amount);
            
            // Perform the transfer using ERC20 component
            self.erc20.transfer_from(from, to, amount)
        }
        
        // ERC2612 permit implementation
        fn permit(
            ref self: ContractState,
            owner: ContractAddress,
            spender: ContractAddress,
            amount: u256,
            deadline: u64,
            signature: Span<felt252>
        ) {
            // For now, permit functionality is a placeholder
            // We would need to implement a proper permit mechanism
            // This requires more specific implementation with OpenZeppelin v2.0.0
            assert(deadline >= starknet::get_block_timestamp(), 'Permit expired');
            
            // Approve the spender for the amount
            // Use the nonce and increment it
            self.nonces.use_nonce(owner);
            self.erc20._approve(owner, spender, amount);
        }
        
        fn nonces(self: @ContractState, owner: ContractAddress) -> felt252 {
            // Return the current nonce for the owner
            self.nonces.nonces(owner)
        }
        
        fn DOMAIN_SEPARATOR(self: @ContractState) -> felt252 {
            'ERC3643Token_v1' // Simple domain separator
        }

        // Pausable functions
        fn pause(ref self: ContractState) -> bool {
            // Only owner can pause
            self.ownable.assert_only_owner();
            
            // Use the OpenZeppelin pausable component
            self.pausable.pause();
            true
        }

        fn unpause(ref self: ContractState) -> bool {
            // Only owner can unpause
            self.ownable.assert_only_owner();
            
            // Use the OpenZeppelin pausable component
            self.pausable.unpause();
            true
        }

        fn is_paused(self: @ContractState) -> bool {
            // Use the OpenZeppelin pausable component
            self.pausable.is_paused()
        }

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
        
        // ERC3643 specific functions
        fn forced_transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            assert(self.agents.read(caller), 'Only agents allowed');
            
            self._check_transfer_compliance(from, to, amount);
            
            // Use the ERC20 internal transfer function but check for frozen status first
            assert(!self.frozen_addresses.read(from), 'Sender frozen');
            assert(!self.frozen_addresses.read(to), 'Recipient frozen');
            
            // Ensure contract is not paused using OpenZeppelin's pausable component
            self.pausable.assert_not_paused();
            
            // Use ERC20 internal transfer method to bypass allowance checks
            // This is a forced transfer, so we don't need to check allowances
            self.erc20._transfer(from, to, amount);
            true
        }
        
        fn mint(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            assert(self.agents.read(caller), 'Only agents allowed');
            
            // Verify recipient has valid identity
            assert(self._is_verified_address(to), 'Recipient not verified');
            
            // Mint tokens using ERC20 component
            self.erc20.mint(to, amount);
            true
        }
        
        fn burn(ref self: ContractState, amount: u256) -> bool {
            let caller = get_caller_address();
            
            // Use ERC20 component burn function
            self.erc20.burn(caller, amount);
            true
        }
        
        fn recover(ref self: ContractState, lost_address: ContractAddress, amount: u256) -> bool {
            // Only owner can recover tokens
            self.ownable.assert_only_owner();
            
            let owner = self.ownable.owner();
            let recovered_balance = self.erc20.balance_of(lost_address);
            assert(recovered_balance >= amount, 'Insufficient balance');
            
            // Transfer tokens from lost address to owner using internal transfer
            assert(!self.frozen_addresses.read(lost_address), 'Address frozen');
            self.erc20._transfer(lost_address, owner, amount);
            
            self.emit(RecoverySuccess { from: lost_address, to: owner, amount });
            true
        }
        
        fn freeze_address(ref self: ContractState, address_to_freeze: ContractAddress) -> bool {
            self.set_address_frozen(address_to_freeze, true)
        }
        
        fn unfreeze_address(ref self: ContractState, address_to_unfreeze: ContractAddress) -> bool {
            self.set_address_frozen(address_to_unfreeze, false)
        }
        
        fn set_address_frozen(ref self: ContractState, target_address: ContractAddress, frozen: bool) -> bool {
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
        
        fn set_compliance(ref self: ContractState, compliance_address: ContractAddress) -> bool {
            // Only owner can set compliance
            self.ownable.assert_only_owner();
            
            self.compliance_map.write('compliance', compliance_address);
            self.emit(ComplianceAdded { compliance: compliance_address });
            true
        }
        
        fn set_identity_registry(ref self: ContractState, identity_registry: ContractAddress) -> bool {
            // Only owner can set identity registry
            self.ownable.assert_only_owner();
            
            self.identity_registry_map.write('registry', identity_registry);
            self.emit(IdentityRegistryAdded { identity_registry });
            true
        }
        
        fn is_verified_address(self: @ContractState, address: ContractAddress) -> bool {
            self._is_verified_address(address)
        }
        
        fn is_compliance_agent(self: @ContractState, address: ContractAddress) -> bool {
            self.agents.read(address)
        }
        
        fn is_frozen(self: @ContractState, address: ContractAddress) -> bool {
            self.frozen_addresses.read(address)
        }
        
        fn add_agent(ref self: ContractState, agent: ContractAddress) -> bool {
            // Only owner can add agents
            self.ownable.assert_only_owner();
            
            self.agents.write(agent, true);
            self.emit(AgentAdded { agent });
            true
        }
        
        fn remove_agent(ref self: ContractState, agent: ContractAddress) -> bool {
            // Only owner can remove agents
            self.ownable.assert_only_owner();
            
            self.agents.write(agent, false);
            self.emit(AgentRemoved { agent });
            true
        }
    }
    
    
    // Internal functions implementation
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        fn _check_transfer_compliance(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) {
            // Following checks-effects-interactions pattern to prevent reentrancy
            
            // 1. CHECKS: Verify identities first
            // Check if sender and recipient have verified identities
            assert(self._is_verified_address(from), 'Sender not verified');
            assert(self._is_verified_address(to), 'Recipient not verified');
            
            // 2. Read state that we'll need for external call
            let compliance_contract = self.compliance_map.read('compliance');
            
            // Convert u256 amount to felt252s for the call
            let amount_low = amount.low;
            let amount_high = amount.high;
            
            // 3. INTERACTIONS: Make external call last (after all checks and state changes)
            let calldata = array![from.into(), to.into(), amount_low.into(), amount_high.into()];
            let success = call_contract_syscall(
                compliance_contract,
                selector!("check_compliance"),
                calldata.span()
            ).unwrap();
            
            // Ensure compliance check passed (expecting a bool return value)
            let has_result = success.len() > 0;
            if has_result {
                let result_value = *success.at(0);
                assert(result_value != 0, 'Transfer not compliant');
            } else {
                // No result means the call failed
                assert(false, 'Compliance check failed');
            }
        }
        
        fn _is_verified_address(self: @ContractState, address: ContractAddress) -> bool {
            // First read all state we need before making any external calls
            let identity_registry = self.identity_registry_map.read('registry');
            
            // Then make external calls (following checks-effects-interactions pattern)
            // Call identity registry to check if address is verified
            let calldata = array![address.into()];
            let result = call_contract_syscall(
                identity_registry,
                selector!("is_verified_address"),
                calldata.span()
            ).unwrap();
            
            // Process the result
            if result.len() > 0 {
                *result.at(0) != 0
            } else {
                false
            }
        }
    }
}