# ERC3643 Components for StarkNet

This library provides modular and reusable components for implementing ERC3643 (T-REX) tokens on StarkNet. The design follows a component-based approach similar to OpenZeppelin's libraries, allowing for flexible integration into various token implementations.

## Directory Structure

```
src/
├── interfaces/           # Public interfaces
│   ├── ierc3643.cairo    # Main ERC3643 token interface
│   ├── iidentity_registry.cairo
│   ├── iidentity_storage.cairo
│   ├── icompliance.cairo
│   ├── iclaim_topics_registry.cairo
│   └── itrusted_issuers_registry.cairo
├── components/           # Reusable components
│   ├── erc3643.cairo     # ERC3643 token component
│   └── identity_registry.cairo
└── examples/             # Example implementations
    └── erc3643_interface_example.cairo
```

## Usage

### 1. Basic Token Implementation

The simplest way to implement an ERC3643 token is to directly implement the `IERC3643` interface:

```cairo
use crate::interfaces::ierc3643::IERC3643;

#[starknet::contract]
pub mod MyToken {
    use super::*;
    
    #[storage]
    struct Storage {
        // Your token storage
    }
    
    #[abi(embed_v0)]
    impl ERC3643Impl of IERC3643<ContractState> {
        // Implement the interface methods
    }
}
```

See `examples/erc3643_interface_example.cairo` and `examples/erc3643_token.cairo` for complete examples.

## Interfaces

We provide a set of standardized interfaces:

- `IERC3643`: The main token interface
- `IIdentityRegistry`: Interface for identity management
- `IIdentityStorage`: Interface for storing identity data
- `ICompliance`: Interface for compliance checking
- `IClaimTopicsRegistry`: Interface for claim topics management
- `ITrustedIssuersRegistry`: Interface for trusted issuers management

Each interface has both snake_case and camelCase versions for compatibility.

### Using the IERC3643 Interface

The `IERC3643` interface extends ERC20 with additional regulatory compliance features:

```cairo
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
```

## Components

The library provides the following reusable components:

- `erc3643::components::erc3643`: Core ERC3643 token implementation
- `erc3643::components::identity_registry`: Identity registry implementation

These components can be used to create custom token implementations with minimal effort.

## Further Development

Future enhancements will include:
- Complete component implementations for all interfaces
- Improved documentation and examples
- Testing utilities for ERC3643 tokens