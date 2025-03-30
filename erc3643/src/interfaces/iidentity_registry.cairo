// Identity Registry Interface
use starknet::ContractAddress;

#[starknet::interface]
pub trait IIdentityRegistry<TContractState> {
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

#[starknet::interface]
pub trait IIdentityRegistryCamelCase<TContractState> {
    // Identity management camelCase functions
    fn registerIdentity(ref self: TContractState, user_address: ContractAddress, identity: felt252, country: felt252) -> bool;
    fn updateIdentity(ref self: TContractState, user_address: ContractAddress, identity: felt252) -> bool;
    fn updateCountry(ref self: TContractState, user_address: ContractAddress, country: felt252) -> bool;
    fn deleteIdentity(ref self: TContractState, user_address: ContractAddress) -> bool;
    fn setIdentityStorage(ref self: TContractState, identity_storage: ContractAddress) -> bool;
    fn setClaimTopicsRegistry(ref self: TContractState, claim_topics_registry: ContractAddress) -> bool;
    fn setTrustedIssuersRegistry(ref self: TContractState, trusted_issuers_registry: ContractAddress) -> bool;
    fn getIdentity(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn getCountry(self: @TContractState, user_address: ContractAddress) -> felt252;
    fn isVerifiedAddress(self: @TContractState, user_address: ContractAddress) -> bool;
    fn isIdentityVerified(self: @TContractState, identity: felt252) -> bool;
    fn identityExists(self: @TContractState, identity: felt252) -> bool;
}