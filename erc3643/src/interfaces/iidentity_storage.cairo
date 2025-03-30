// Identity Storage Interface
use starknet::ContractAddress;
use core::array::Array;

#[starknet::interface]
pub trait IIdentityStorage<TContractState> {
    fn register_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn update_identity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn update_country(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn delete_identity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn get_identity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_country(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn get_addresses_by_identity(self: @TContractState, identity: felt252) -> Array<ContractAddress>;
}

#[starknet::interface]
pub trait IIdentityStorageCamelCase<TContractState> {
    fn registerIdentity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn updateIdentity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn updateCountry(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn deleteIdentity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn getIdentity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn getCountry(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn getAddressesByIdentity(self: @TContractState, identity: felt252) -> Array<ContractAddress>;
}