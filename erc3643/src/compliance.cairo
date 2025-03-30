// Import OpenZeppelin's components
use openzeppelin::access::ownable::OwnableComponent;
use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
use starknet::{
    ContractAddress, 
    get_caller_address,
    storage::StorageMapReadAccess,
    storage::StorageMapWriteAccess,
    storage::Map,
};
use core::array::ArrayTrait;

// Compliance Interface
#[starknet::interface]
pub trait ICompliance<TContractState> {
    fn check_compliance(
        self: @TContractState, 
        from: ContractAddress, 
        to: ContractAddress, 
        amount: u256
    ) -> bool;
    fn add_rule(ref self: TContractState, rule: ContractAddress) -> bool;
    fn remove_rule(ref self: TContractState, rule: ContractAddress) -> bool;
    fn add_compliance_check(ref self: TContractState, claim_topic: felt252) -> bool;
    fn remove_compliance_check(ref self: TContractState, claim_topic: felt252) -> bool;
    fn get_rules(self: @TContractState) -> Array<ContractAddress>;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress) -> bool;
    fn owner(self: @TContractState) -> ContractAddress;
}

// Compliance Rule Interface
#[starknet::interface]
trait IComplianceRule<TContractState> {
    fn check_compliance(
        self: @TContractState, 
        from: ContractAddress, 
        to: ContractAddress, 
        amount: u256
    ) -> bool;
}

#[starknet::contract]
pub mod Compliance {
    use super::*;
    
    // Component declarations
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    
    // Implement component interfaces
    // We're removing abi(embed_v0) to avoid duplicate entry points in testing
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    
    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        RuleAdded: RuleAdded,
        RuleRemoved: RuleRemoved,
        ComplianceCheckAdded: ComplianceCheckAdded,
        ComplianceCheckRemoved: ComplianceCheckRemoved,
    }
    
    #[derive(Drop, starknet::Event)]
    struct RuleAdded {
        rule: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct RuleRemoved {
        rule: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ComplianceCheckAdded {
        claim_topic: felt252,
    }
    
    #[derive(Drop, starknet::Event)]
    struct ComplianceCheckRemoved {
        claim_topic: felt252,
    }
    
    #[storage]
    struct Storage {
        // Component storage
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        
        // Compliance rules storage using maps
        rule_count_map: Map<felt252, u32>,  // Using 'rule_count' as key
        rules: Map<u32, ContractAddress>,
        rule_indices: Map<ContractAddress, u32>,
        
        // Compliance check topics
        check_count_map: Map<felt252, u32>,  // Using 'check_count' as key
        checks: Map<u32, felt252>,
        check_indices: Map<felt252, u32>,
    }
    
    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        // Initialize Ownable component
        OwnableInternalTrait::initializer(ref self.ownable, initial_owner);
        
        // Initialize counters using maps
        self.rule_count_map.write('rule_count', 0);
        self.check_count_map.write('check_count', 0);
    }
    
    #[abi(embed_v0)]
    impl ComplianceImpl of super::ICompliance<ContractState> {
        fn check_compliance(
            self: @ContractState, 
            from: ContractAddress, 
            to: ContractAddress, 
            amount: u256
        ) -> bool {
            // Get the number of rules
            let rule_count = self.get_rule_count();
            
            // If no rules, transfer is compliant
            if rule_count == 0 {
                return true;
            }
            
            // Check each rule
            let mut i: u32 = 0;
            loop {
                if i >= rule_count {
                    break;
                }
                
                // Get rule and check compliance
                let rule = self.rules.read(i);
                let is_rule_valid = super::IComplianceRuleDispatcher { contract_address: rule }
                    .check_compliance(from, to, amount);
                    
                if !is_rule_valid {
                    return false;
                }
                
                i += 1;
            };
            
            // All rules passed, transfer is compliant
            true
        }
        
        fn add_rule(ref self: ContractState, rule: ContractAddress) -> bool {
            // Only owner can add rules
            assert(get_caller_address() == self.ownable.owner(), 'Caller is not the owner');
            
            // Check if rule already exists
            let existing_index = self.rule_indices.read(rule);
            if existing_index != 0 {
                // Rule already exists
                return true;
            }
            
            // Get current rule count
            let rule_count = self.get_rule_count();
            
            // Add rule
            self.rules.write(rule_count, rule);
            self.rule_indices.write(rule, rule_count + 1); // +1 to differentiate from 0 (not found)
            
            // Increment count
            self.set_rule_count(rule_count + 1);
            
            // Emit event
            self.emit(RuleAdded { rule });
            
            true
        }
        
        fn remove_rule(ref self: ContractState, rule: ContractAddress) -> bool {
            // Only owner can remove rules
            self.ownable.assert_only_owner();
            
            // Check if rule exists
            let existing_index = self.rule_indices.read(rule);
            if existing_index == 0 {
                // Rule doesn't exist
                return true;
            }
            
            // Convert index from 1-based to 0-based
            let index = existing_index - 1;
            
            // Get current rule count
            let rule_count = self.get_rule_count();
            
            // If not the last rule, move the last rule to this index
            if index < rule_count - 1 {
                let last_rule = self.rules.read(rule_count - 1);
                self.rules.write(index, last_rule);
                self.rule_indices.write(last_rule, index + 1); // +1 to differentiate from 0 (not found)
            }
            
            // Remove rule
            self.rule_indices.write(rule, 0);
            
            // Decrement count
            self.set_rule_count(rule_count - 1);
            
            // Emit event
            self.emit(RuleRemoved { rule });
            
            true
        }
        
        fn add_compliance_check(ref self: ContractState, claim_topic: felt252) -> bool {
            // Only owner can add compliance checks
            self.ownable.assert_only_owner();
            
            // Check if check already exists
            let existing_index = self.check_indices.read(claim_topic);
            if existing_index != 0 {
                // Check already exists
                return true;
            }
            
            // Get current check count
            let check_count = self.get_check_count();
            
            // Add check
            self.checks.write(check_count, claim_topic);
            self.check_indices.write(claim_topic, check_count + 1); // +1 to differentiate from 0 (not found)
            
            // Increment count
            self.set_check_count(check_count + 1);
            
            // Emit event
            self.emit(ComplianceCheckAdded { claim_topic });
            
            true
        }
        
        fn remove_compliance_check(ref self: ContractState, claim_topic: felt252) -> bool {
            // Only owner can remove compliance checks
            self.ownable.assert_only_owner();
            
            // Check if check exists
            let existing_index = self.check_indices.read(claim_topic);
            if existing_index == 0 {
                // Check doesn't exist
                return true;
            }
            
            // Convert index from 1-based to 0-based
            let index = existing_index - 1;
            
            // Get current check count
            let check_count = self.get_check_count();
            
            // If not the last check, move the last check to this index
            if index < check_count - 1 {
                let last_check = self.checks.read(check_count - 1);
                self.checks.write(index, last_check);
                self.check_indices.write(last_check, index + 1); // +1 to differentiate from 0 (not found)
            }
            
            // Remove check
            self.check_indices.write(claim_topic, 0);
            
            // Decrement count
            self.set_check_count(check_count - 1);
            
            // Emit event
            self.emit(ComplianceCheckRemoved { claim_topic });
            
            true
        }
        
        fn get_rules(self: @ContractState) -> Array<ContractAddress> {
            let mut rules = ArrayTrait::<ContractAddress>::new();
            let rule_count = self.get_rule_count();
            
            let mut i: u32 = 0;
            loop {
                if i >= rule_count {
                    break;
                }
                
                // Get rule and add to array
                let rule = self.rules.read(i);
                rules.append(rule);
                
                i += 1;
            };
            
            rules
        }
        
        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.ownable.transfer_ownership(new_owner);
            true
        }
        
        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }
    }
    
    // Internal helper methods
    #[generate_trait]
    impl InternalFunctions of InternalTrait {
        // Helper methods for accessing the rule counter
        fn get_rule_count(self: @ContractState) -> u32 {
            self.rule_count_map.read('rule_count')
        }
        
        fn set_rule_count(ref self: ContractState, value: u32) {
            self.rule_count_map.write('rule_count', value);
        }
        
        // Helper methods for accessing the check counter
        fn get_check_count(self: @ContractState) -> u32 {
            self.check_count_map.read('check_count')
        }
        
        fn set_check_count(ref self: ContractState, value: u32) {
            self.check_count_map.write('check_count', value);
        }
    }
}