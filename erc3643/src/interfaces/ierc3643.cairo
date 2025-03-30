// ERC3643 Token Interface
use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC3643<TContractState> {
    // ERC20 standard functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    
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

#[starknet::interface]
pub trait IERC3643CamelCase<TContractState> {
    // ERC20 camelCase functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn totalSupply(self: @TContractState) -> u256;
    fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn transferFrom(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    
    // ERC3643 extended camelCase functions
    fn forcedTransfer(ref self: TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn mint(ref self: TContractState, to: ContractAddress, amount: u256) -> bool;
    fn burn(ref self: TContractState, amount: u256) -> bool;
    fn recover(ref self: TContractState, lost_address: ContractAddress, amount: u256) -> bool;
    fn freezeAddress(ref self: TContractState, address_to_freeze: ContractAddress) -> bool;
    fn unfreezeAddress(ref self: TContractState, address_to_unfreeze: ContractAddress) -> bool;
    fn setAddressFrozen(ref self: TContractState, target_address: ContractAddress, frozen: bool) -> bool;
    fn setCompliance(ref self: TContractState, compliance_address: ContractAddress) -> bool;
    fn setIdentityRegistry(ref self: TContractState, identity_registry: ContractAddress) -> bool;
    fn isVerifiedAddress(self: @TContractState, address: ContractAddress) -> bool;
    fn isComplianceAgent(self: @TContractState, address: ContractAddress) -> bool;
    fn isFrozen(self: @TContractState, address: ContractAddress) -> bool;
    fn addAgent(ref self: TContractState, agent: ContractAddress) -> bool;
    fn removeAgent(ref self: TContractState, agent: ContractAddress) -> bool;
}