# Aave Optimism -> Mainnet ERC20 Bridge

Currently there is no easy way for the Collector on Optimism to withdraw funds via bridging to Ethereum mainnet. An upgrade to the Collector to be made to bridge directly, however, with this approach, we can assign a Guardian the role to bridge as is done with other networks such as Polygon and Arbitrum.

The official Optimism documentation can be found [here](https://docs.optimism.io/builders/app-developers/bridging/standard-bridge).

## Functions

`function bridge(address token, address l1Token, uint256 amount) external onlyOwner`

Callable on Optimism. Withdraws an ERC20 from Optimism to Mainnet. The ERC20 token must be an OptimismBurnableERC20 in order to be bridged.
The first parameter is the token's address on Optimism, while the second one is the token's equivalent address on Mainnet (ie: USDC.e on Optimism and USDC on Mainnet). The last parameter is the amount of tokens to bridge.

`function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;`

Callable on Optimism. In case of emergency can be called by the owner to withdraw tokens from bridge contract back to any address on Optimism.

## Proving The Message

In order to finalize the bridge from Optimism to Mainnet, there are two steps required. Firstly, one must prove the message. Unfortunately, there's no way to do this on-chain with Foundry so we have to rely on the Optimism SDK by utilizing TokenLogic's CLI tool (forked off of BGD's aave-cli).

[The CLI tool can be found here](https://github.com/TokenLogic-com-au/aave-cli-tools).

The first command can be run a few minutes to an hour after the bridge transaction takes place.

The script can be run with the following command:

`yarn start optimism-prove-message <TX_HASH> <INDEX>` where TX_HASH is the transaction hash where the bridge took place and INDEX is the index of the ERC20 token in terms of how many tokens were bridged in the same transaction. For just one token, INDEX will be 0. For multiple, start from 0 and go up by one.

Once the message is proven, around 7 days later from the transaction, it will be available to be finalized as Optimism is an optimistic rollup.

## Finalizing

[The CLI can be found here](https://github.com/TokenLogic-com-au/aave-cli-tools).

Just like when proving the message, there's a command in order to finalize the bridge.

`yarn start optimism-finalize-bridge <TX_HASH> <INDEX>` where TX_HASH is the transaction hash where the bridge took place and INDEX is the index of the ERC20 token in terms of how many tokens were bridged in the same transaction. For just one token, INDEX will be 0. For multiple, start from 0 and go up by one.

## Transactions

| Token  | Bridge                                                                                                     | Prove                                                                                            | Finalize                                                                                        |
| ------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| USDC.e | [Tx](https://optimistic.etherscan.io/tx/0xa3f71476258d6204471c51f5caf77f0a82222e8fca66f1e0f76fa83744924cf0 | [Tx](https://etherscan.io/tx/0xf9a44f58bac1bee523f8005d0170681deacda3c4a1a48d794e8701525f272a9c) | [Tx](https://etherscan.io/tx/0x6fd6177120755ddc3ce896c60e4a861c3a06196d26f385de13b470750651a6a1 |

## Deployed Address

Optimism [0xc3250A20F8a7BbDd23adE87737EE46A45Fe5543E](https://optimistic.etherscan.io/address/0xc3250a20f8a7bbdd23ade87737ee46a45fe5543e)
