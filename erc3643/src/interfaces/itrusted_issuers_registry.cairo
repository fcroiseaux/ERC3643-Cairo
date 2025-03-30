// Trusted Issuers Registry Interface
use core::array::Array;

#[starknet::interface]
pub trait ITrustedIssuersRegistry<TContractState> {
    fn add_trusted_issuer(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn remove_trusted_issuer(ref self: TContractState, issuer: felt252) -> bool;
    fn update_issuer_claim_topics(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn add_claim_topic(ref self: TContractState, issuer: felt252, claim_topic: felt252) -> bool;
    fn remove_claim_topic(ref self: TContractState, issuer: felt252, claim_topic: felt252) -> bool;
    fn get_trusted_issuers(self: @TContractState) -> Array<felt252>;
    fn get_issuer_claim_topics(self: @TContractState, issuer: felt252) -> Array<felt252>;
    fn is_trusted_issuer(self: @TContractState, issuer: felt252) -> bool;
    fn has_claim_topic(self: @TContractState, issuer: felt252, claim_topic: felt252) -> bool;
}

#[starknet::interface]
pub trait ITrustedIssuersRegistryCamelCase<TContractState> {
    fn addTrustedIssuer(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn removeTrustedIssuer(ref self: TContractState, issuer: felt252) -> bool;
    fn updateIssuerClaimTopics(ref self: TContractState, issuer: felt252, claim_topics: Array<felt252>) -> bool;
    fn addClaimTopic(ref self: TContractState, issuer: felt252, claim_topic: felt252) -> bool;
    fn removeClaimTopic(ref self: TContractState, issuer: felt252, claim_topic: felt252) -> bool;
    fn getTrustedIssuers(self: @TContractState) -> Array<felt252>;
    fn getIssuerClaimTopics(self: @TContractState, issuer: felt252) -> Array<felt252>;
    fn isTrustedIssuer(self: @TContractState, issuer: felt252) -> bool;
    fn hasClaimTopic(self: @TContractState, issuer: felt252, claim_topic: felt252) -> bool;
}