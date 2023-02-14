# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build --sizes --via-ir
test   :; forge test -vvv
test-v3-listing-engine:; forge test -vvv --match-contract GenericV3ListingEngineTest --gas-report


# Scripts
listing-engine-opt :;  forge script script/GenericListingEngine.s.sol:DeployListingEngineOpt --rpc-url optimism --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY_OPTIMISM} -vvvv
listing-engine-arb :;  forge script script/GenericListingEngine.s.sol:DeployListingEngineArb --rpc-url arbitrum --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY_ARBITRUM} -vvvv
listing-engine-pol :;  forge script script/GenericListingEngine.s.sol:DeployListingEnginePol --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY_POLYGON} -vvvv
listing-engine-ava :;  forge script script/GenericListingEngine.s.sol:DeployListingEngineAva --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify --etherscan-api-key ${ETHERSCAN_API_KEY_AVALANCHE} -vvvv

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md
