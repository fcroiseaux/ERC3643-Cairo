// Claim Topics Registry Interface
use core::array::Array;

#[starknet::interface]
pub trait IClaimTopicsRegistry<TContractState> {
    fn add_claim_topic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn remove_claim_topic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn get_claim_topics(self: @TContractState) -> Array<felt252>;
}

#[starknet::interface]
pub trait IClaimTopicsRegistryCamelCase<TContractState> {
    fn addClaimTopic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn removeClaimTopic(ref self: TContractState, claim_topic: felt252) -> bool;
    fn getClaimTopics(self: @TContractState) -> Array<felt252>;
}