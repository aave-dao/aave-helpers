# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build

# IMPORTANT It is highly probable that will be necessary to modify the --fork-block-number, depending on the test
test   :; forge test -vvv --rpc-url=${ETH_RPC_URL} --fork-block-number 16146270
test-aave-v3	:; forge test --match-contract AaveV3HelpersTest -vvv --rpc-url=${ETH_RPC_URL} --fork-block-number 16146270
trace   :; forge test -vvvv --rpc-url=${ETH_RPC_URL} --fork-block-number 16146270
clean  :; forge clean