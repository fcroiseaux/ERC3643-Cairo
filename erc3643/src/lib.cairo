//! ERC3643 (T-REX) implementation for StarkNet
//!
//! This library provides a complete implementation of the ERC3643 standard
//! for regulated tokens on StarkNet.

// Original modules (for backward compatibility)
pub mod token;
pub mod identity_registry;
pub mod compliance;
pub mod claim_topics_registry;
pub mod trusted_issuers_registry;
pub mod identity_storage;

// New component-based architecture
pub mod interfaces {
    pub mod ierc3643;
    pub mod iidentity_registry;
    pub mod iidentity_storage;
    pub mod icompliance;
    pub mod iclaim_topics_registry;
    pub mod itrusted_issuers_registry;
}

pub mod components {
    pub mod erc3643;
    pub mod identity_registry;
}

pub mod examples {
    pub mod erc3643_interface_example;
}

// Re-export key components for easier usage
pub use interfaces::ierc3643::IERC3643;