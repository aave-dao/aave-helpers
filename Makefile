# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

# Build & test
build  :; forge build
test   :; forge test -vvv
test-gauntlet-strategies-update:; forge test -vvv --match-path src/test/AaveV3ConfigEngineGauntletProposal.t.sol --gas-report
test-config-engine:; forge test -vvv --match-path src/test/AaveV3ConfigEngineTest.t.sol --gas-report
test-rates-factory:; forge test -vvv --match-path src/test/V3RateStrategyFactory.t.sol --gas-report
test-v2-config-engine:; forge test -vvv --match-path src/test/AaveV2ConfigEngineTest.t.sol --gas-report
test-v2-rates-factory:; forge test -vvv --match-path src/test/V2RateStrategyFactory.t.sol --gas-report

# Scripts
deploy-engine-eth :;  forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineEth --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-opt :;  forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineOpt --rpc-url optimism --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-arb :;  forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineArb --rpc-url arbitrum --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-pol :;  forge script scripts/AaveV3ConfigEngine.s.sol:DeployEnginePol --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-ava :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineAva --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-met :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineMet --rpc-url metis --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-bas :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineBas --rpc-url base --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-gno :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineGno --rpc-url gnosis --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-bnb :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineBnb --rpc-url bnb --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-scroll :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineScroll --rpc-url scroll --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-engine-zkevm :; forge script scripts/AaveV3ConfigEngine.s.sol:DeployEngineZkEvm --rpc-url zkevm --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

deploy-rates-factory-eth :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryEth --rpc-url mainnet --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-pol :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryPol --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-opt :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryOpt --rpc-url optimism --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-arb :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryArb --rpc-url arbitrum --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-ava :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryAva --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-met :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryMet --rpc-url metis --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-bas :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryBas --rpc-url base --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-scroll :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryScroll--rpc-url scroll --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-gno :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryGno --rpc-url gnosis --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-bnb :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryBnb --rpc-url bnb --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-zkevm :; forge script scripts/V3RateStrategyFactory.s.sol:DeployRatesFactoryZkEvm --rpc-url zkevm --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

deploy-forwarder-pol :;  forge script scripts/CrosschainForwarders.s.sol:DeployPol --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-forwarder-opt :;  forge script scripts/CrosschainForwarders.s.sol:DeployOpt --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-forwarder-arb :;  forge script scripts/CrosschainForwarders.s.sol:DeployArb --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-forwarder-met :;  forge script scripts/CrosschainForwarders.s.sol:DeployMet --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-eth :; forge script scripts/RiskStewards.s.sol:DeployEth --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-pol :; forge script scripts/RiskStewards.s.sol:DeployPol --rpc-url polygon --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-opt :; forge script scripts/RiskStewards.s.sol:DeployOpt --rpc-url optimism --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-arb :; forge script scripts/RiskStewards.s.sol:DeployArb --rpc-url arbitrum --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-ava :; forge script scripts/RiskStewards.s.sol:DeployAva --rpc-url avalanche --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-met :; forge script scripts/RiskStewards.s.sol:DeployMet --rpc-url metis --broadcast --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-bas :; forge script scripts/RiskStewards.s.sol:DeployBas --rpc-url base --broadcast --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-gno :; forge script scripts/RiskStewards.s.sol:DeployGno --rpc-url gnosis --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-bnb :; forge script scripts/RiskStewards.s.sol:DeployBnb --rpc-url bnb --broadcast  --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-scroll :; forge script scripts/RiskStewards.s.sol:DeployScroll --rpc-url scroll --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-steward-zkevm :; forge script scripts/RiskStewards.s.sol:DeployZkEvm --rpc-url zkevm --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

deploy-freezing-steward-bnb :; forge script scripts/FreezingStewards.s.sol:DeployBnb --rpc-url bnb --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-freezing-steward-gno :; forge script scripts/FreezingStewards.s.sol:DeployGno --rpc-url gnosis --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-freezing-steward-scroll :; forge script scripts/FreezingStewards.s.sol:DeployScroll --rpc-url scroll --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-freezing-steward-zkevm :; forge script scripts/FreezingStewards.s.sol:DeployZkEvm --rpc-url zkevm --broadcast --legacy --ledger --legacy --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

deploy-rates-factory-v2-eth :; forge script scripts/V2RateStrategyFactory.s.sol:DeployV2RatesFactoryEth --mnemonics random --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-v2-eth-amm :; forge script scripts/V2RateStrategyFactory.s.sol:DeployV2RatesFactoryEthAMM --mnemonics random --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-v2-pol :; forge script scripts/V2RateStrategyFactory.s.sol:DeployV2RatesFactoryPol --mnemonics random --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-rates-factory-v2-ava :; forge script scripts/V2RateStrategyFactory.s.sol:DeployV2RatesFactoryAva --mnemonics random --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

deploy-config-engine-v2-eth :; forge script scripts/AaveV2ConfigEngine.s.sol:DeployV2EngineEth --mnemonics random --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-config-engine-v2-eth-amm :; forge script scripts/AaveV2ConfigEngine.s.sol:DeployV2EngineEthAMM --mnemonics random --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-config-engine-v2-pol :; forge script scripts/AaveV2ConfigEngine.s.sol:DeployV2EnginePol --mnemonics random --rpc-url polygon --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv
deploy-config-engine-v2-ava :; forge script scripts/AaveV2ConfigEngine.s.sol:DeployV2EngineAva --mnemonics random --rpc-url avalanche --broadcast --legacy --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv

# Utilities
download :; cast etherscan-source --chain ${chain} -d src/etherscan/${chain}_${address} ${address}
git-diff :
	@mkdir -p diffs
	@printf '%s\n%s\n%s\n' "\`\`\`diff" "$$(git diff --no-index --diff-algorithm=patience --ignore-space-at-eol ${before} ${after})" "\`\`\`" > diffs/${out}.md

# Voting scripts
vote :;  forge script scripts/VotingScripts.s.sol:VoteForProposal --rpc-url mainnet --broadcast --ledger --mnemonic-indexes ${MNEMONIC_INDEX} --sender ${LEDGER_SENDER} --verify -vvvv ${proposalId} ${support}

deploy-pk :; forge script ${contract} --rpc-url ${chain} $(if ${dry},--sender 0x25F2226B597E8F9514B3F68F00f494cF4f286491 -vvvv,--broadcast --private-key ${PRIVATE_KEY} --verify -vvvv --slow)
