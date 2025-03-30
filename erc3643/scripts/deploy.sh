#!/bin/bash
set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building stark3643 contracts...${NC}"
scarb build

echo -e "${YELLOW}Preparing to deploy stark3643 contracts to StarkNet...${NC}"

# Ensure environment variables are set
if [ -z "$STARKNET_ACCOUNT" ]; then
    echo -e "${RED}Error: STARKNET_ACCOUNT environment variable is not set${NC}"
    exit 1
fi

if [ -z "$STARKNET_PRIVATE_KEY" ]; then
    echo -e "${RED}Error: STARKNET_PRIVATE_KEY environment variable is not set${NC}"
    exit 1
fi

# Get network from command line argument or default to testnet
NETWORK="${1:-testnet}"

if [ "$NETWORK" != "testnet" ] && [ "$NETWORK" != "mainnet" ]; then
    echo -e "${RED}Error: Network must be either 'testnet' or 'mainnet'${NC}"
    exit 1
fi

echo -e "${YELLOW}Deploying to $NETWORK...${NC}"

# Deploy contracts in correct order
echo -e "${YELLOW}Deploying ClaimTopicsRegistry...${NC}"
CLAIM_TOPICS_REGISTRY=$(sncast --profile $NETWORK declare --contract-name ClaimTopicsRegistry)
CLASS_HASH=$(echo "$CLAIM_TOPICS_REGISTRY" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
CLAIM_TOPICS_REGISTRY_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $STARKNET_ACCOUNT)
CLAIM_TOPICS_REGISTRY_ADDR=$(echo "$CLAIM_TOPICS_REGISTRY_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}ClaimTopicsRegistry deployed at: $CLAIM_TOPICS_REGISTRY_ADDR${NC}"

echo -e "${YELLOW}Deploying TrustedIssuersRegistry...${NC}"
TRUSTED_ISSUERS_REGISTRY=$(sncast --profile $NETWORK declare --contract-name TrustedIssuersRegistry)
CLASS_HASH=$(echo "$TRUSTED_ISSUERS_REGISTRY" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
TRUSTED_ISSUERS_REGISTRY_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $STARKNET_ACCOUNT)
TRUSTED_ISSUERS_REGISTRY_ADDR=$(echo "$TRUSTED_ISSUERS_REGISTRY_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}TrustedIssuersRegistry deployed at: $TRUSTED_ISSUERS_REGISTRY_ADDR${NC}"

echo -e "${YELLOW}Deploying IdentityStorage...${NC}"
IDENTITY_STORAGE=$(sncast --profile $NETWORK declare --contract-name IdentityStorage)
CLASS_HASH=$(echo "$IDENTITY_STORAGE" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
IDENTITY_STORAGE_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $STARKNET_ACCOUNT)
IDENTITY_STORAGE_ADDR=$(echo "$IDENTITY_STORAGE_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}IdentityStorage deployed at: $IDENTITY_STORAGE_ADDR${NC}"

echo -e "${YELLOW}Deploying IdentityRegistry...${NC}"
IDENTITY_REGISTRY=$(sncast --profile $NETWORK declare --contract-name IdentityRegistry)
CLASS_HASH=$(echo "$IDENTITY_REGISTRY" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
IDENTITY_REGISTRY_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $STARKNET_ACCOUNT $IDENTITY_STORAGE_ADDR $TRUSTED_ISSUERS_REGISTRY_ADDR $CLAIM_TOPICS_REGISTRY_ADDR)
IDENTITY_REGISTRY_ADDR=$(echo "$IDENTITY_REGISTRY_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}IdentityRegistry deployed at: $IDENTITY_REGISTRY_ADDR${NC}"

echo -e "${YELLOW}Deploying Compliance...${NC}"
COMPLIANCE=$(sncast --profile $NETWORK declare --contract-name Compliance)
CLASS_HASH=$(echo "$COMPLIANCE" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
COMPLIANCE_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $STARKNET_ACCOUNT)
COMPLIANCE_ADDR=$(echo "$COMPLIANCE_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}Compliance deployed at: $COMPLIANCE_ADDR${NC}"

echo -e "${YELLOW}Deploying ERC3643Token...${NC}"
TOKEN=$(sncast --profile $NETWORK declare --contract-name ERC3643Token)
CLASS_HASH=$(echo "$TOKEN" | grep -o '"class_hash": "[^"]*' | cut -d'"' -f4)
TOKEN_NAME_HEX=$(echo -n "T-REX Token" | xxd -p)
TOKEN_SYMBOL_HEX=$(echo -n "TREX" | xxd -p)
TOKEN_ADDR=$(sncast --profile $NETWORK deploy --class-hash $CLASS_HASH --constructor-calldata $TOKEN_NAME_HEX $TOKEN_SYMBOL_HEX $STARKNET_ACCOUNT $COMPLIANCE_ADDR $IDENTITY_REGISTRY_ADDR)
TOKEN_ADDR=$(echo "$TOKEN_ADDR" | grep -o '"contract_address": "[^"]*' | cut -d'"' -f4)
echo -e "${GREEN}ERC3643Token deployed at: $TOKEN_ADDR${NC}"

# Set up relationships between contracts
echo -e "${YELLOW}Setting up contract relationships...${NC}"
sncast --profile $NETWORK invoke --contract-address $IDENTITY_STORAGE_ADDR --function set_registry --calldata $IDENTITY_REGISTRY_ADDR

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "Token address: $TOKEN_ADDR"
echo -e "Identity Registry address: $IDENTITY_REGISTRY_ADDR"
echo -e "Identity Storage address: $IDENTITY_STORAGE_ADDR"
echo -e "Compliance address: $COMPLIANCE_ADDR"
echo -e "Claim Topics Registry address: $CLAIM_TOPICS_REGISTRY_ADDR"
echo -e "Trusted Issuers Registry address: $TRUSTED_ISSUERS_REGISTRY_ADDR"