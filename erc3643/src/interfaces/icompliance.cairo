//! Compliance Interface
use starknet::ContractAddress;
use core::array::Array;

#[starknet::interface]
pub trait ICompliance<TContractState> {
    fn check_compliance(self: @TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn set_token(ref self: TContractState, token: ContractAddress) -> bool;
    fn add_compliance_rule(ref self: TContractState, rule: felt252) -> bool;
    fn remove_compliance_rule(ref self: TContractState, rule: felt252) -> bool;
    fn get_compliance_rules(self: @TContractState) -> Array<felt252>;
    fn get_token(self: @TContractState) -> ContractAddress;
}

#[starknet::interface]
pub trait IComplianceCamelCase<TContractState> {
    fn checkCompliance(self: @TContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool;
    fn setToken(ref self: TContractState, token: ContractAddress) -> bool;
    fn addComplianceRule(ref self: TContractState, rule: felt252) -> bool;
    fn removeComplianceRule(ref self: TContractState, rule: felt252) -> bool;
    fn getComplianceRules(self: @TContractState) -> Array<felt252>;
    fn getToken(self: @TContractState) -> ContractAddress;
}