# Aave Polygon -> Mainnet ERC20 Bridge

Currently, there is no built-in function to be able to bridge tokens held in contracts from Polygon to Ethereum mainnet. The reason is because the `ERC20::withdraw()` mechanism available on the PoS bridge, goes from the calling address to the same address on the other chain. There is no way to choose an address on withdraw for some tokens. The Polygon team is working on this with their FxPortal, but not all tokens exist and for USDC, this is the only way to bridge from Polygon to Mainnet.

The same contract exists on both chains with the same address, so this contract will receive funds from the Polygon Collector, then call to withdraw. After the Polygon checkpoint happens, the "burn proof" will be generated via API. At this point, the mainnet contract can be called. `exit()` will give the mainnet contract the tokens that were bridged over from Polygon. At this point, `withdrawToCollector()` can be called and the Ethereum mainnet Aave Collector will receive the USDC tokens.

## Functions

`function isTokenMapped(address l2token) external view returns(bool);`

Callable on Mainnet. Returns whether a token mapping exists between Polygon and Mainnet.

**DO NOT BRIDGE** if this function returns false, funds will be lost forever.

Here's a list of Polygon Aave V2 and Aave V3 tokens and whether they are mapped or not, and respective transactions showing a bridge.

| Token   | Is Mapped | Burn                                                                                                | Exit                                                                                             |
| ------- | --------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| USDC    | yes       | [Tx](https://polygonscan.com/tx/0x954e823985e203318308073b0692e360ca9842ea0d29ed578eafc14b801621dc) | [Tx](https://etherscan.io/tx/0x7c54d6b96a7474300d64e2fdae042947aaa92dcc0a7af061f02f335839fdcb56) |
| DAI     | yes       | [Tx](https://polygonscan.com/tx/0x1c455d8f60f73a757ef5752a8cd3ed04b00ba25026dc7d596b4ee7d8b4a099c2) | [Tx](https://etherscan.io/tx/0x7c54d6b96a7474300d64e2fdae042947aaa92dcc0a7af061f02f335839fdcb56) |
| LINK    | yes       | [Tx](https://polygonscan.com/tx/0x4d5e59f05884fc4f56afcd04bc8705ae7ed12eed4eaef7852a673075011fb10b) | [Tx](https://etherscan.io/tx/0x342938e2a9d4f846cde15258c7aeffade7a42b729d97ee310308eeb912a734e8) |
| WBTC    | yes       | [Tx](https://polygonscan.com/tx/0x6fbabbf54aec01502db6739ce1616870ce3e3b6c0626b140c0b75a8c16fdfb19) | [Tx](https://etherscan.io/tx/0x342938e2a9d4f846cde15258c7aeffade7a42b729d97ee310308eeb912a734e8) |
| CRV     | yes       | [Tx](https://polygonscan.com/tx/0xc73b85175045e272161abe38b25eac76546eea20247d0947926d7ef4e901b567) | [Tx](https://etherscan.io/tx/0x70e4880529959951052a7f73bd91890c793ca4ba03a3b9571b75896968d3ef42) |
| BAL     | yes       | [Tx](https://polygonscan.com/tx/0xc73b85175045e272161abe38b25eac76546eea20247d0947926d7ef4e901b567) | [Tx](https://etherscan.io/tx/0x7cd55a0cf1f6dfb16dc7913271ae3f0cd8af78ad90c3c23a82112683e16ac574) |
| USDT    | yes       | [Tx](https://polygonscan.com/tx/0x67d7954f28d446a64aa3d4276d3329d3fc33ced155c9d82403a4d59ae248c0a7) | [Tx](https://etherscan.io/tx/0x693c1d2055319bc969291ef29b5ca1dfdae37193d71170ce700dac9b44e0ef33) | [Tx](https://polygonscan.com/tx/0x813c4821f5da822a0f60db31070ca025f57ff81953f42f95270a77bc941b266d) |
| WETH    | yes       |                                                                                                     | [Tx](https://etherscan.io/tx/0xcc48570ce89313e09a7b62867332f7f7415168500486aa4974c9748146dd7713) |
| WMATIC  | NO        | NO                                                                                                  | NO                                                                                               |
| AAVE    | yes       | [Tx](https://polygonscan.com/tx/0xba939d05ab27aedd931b015af970d9b8a73fa903e705be3e3c707ef3b8c91fb2) | [Tx](https://etherscan.io/tx/0x693c1d2055319bc969291ef29b5ca1dfdae37193d71170ce700dac9b44e0ef33) |
| GHST    | yes       |                                                                                                     |                                                                                                  |
| DPI     | yes       |                                                                                                     |                                                                                                  |
| SUSHI   | yes       |                                                                                                     |                                                                                                  |
| EURS    | yes       |                                                                                                     |                                                                                                  |
| jEUR    | NO        | NO                                                                                                  | NO                                                                                               |
| agEUR   | yes       |                                                                                                     |                                                                                                  |
| miMATIC | NO        | NO                                                                                                  | NO                                                                                               |
| stMATIC | yes       |                                                                                                     |                                                                                                  |
| MaticX  | yes       |                                                                                                     |                                                                                                  |
| wstETH  | yes       | [Tx](https://polygonscan.com/tx/0x1237237d8d9ef85fd395867121f22895102a92bde06d3ad3363026809a472fd2) | [Tx](https://etherscan.io/tx/0x693c1d2055319bc969291ef29b5ca1dfdae37193d71170ce700dac9b44e0ef33) |

`function bridge(address token, uint256 amount) external;`

Callable on Polygon to withdraw ERC20 token. It withdraws `amount` of passed `token` to mainnet.

`function exit(bytes calldata burnProof) external;`

Callable on Mainnet to finish the withdrawal process. Callable 30-90 minutes after `bridge()` is called and proof is available via API.

`function exit(bytes[] calldata burnProofs) external;`

Callable on Mainnet to finish the withdrawal process. Callable 30-90 minutes after `bridge()` is called and proof is available via API.
This function takes an array of proofs to do multiple burns in one transaction.

`function withdrawToCollector(address token) external;`

Callable on Mainnet. Withdraws balance of held token to the Aave Collector.

`function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;`

Callable on Polygon. Withdraws tokens from bridge contract back to Aave Collector on Polygon.

`receive() external payable;`

Function to receive Ether and forward it to Aave Collector. If not mainnet, it will revert.

## Burn Proof Generation

After you have called `bridge()` Polygon, it will take 30-90 minutes for a checkpoint to happen. Once the next checkpoint includes the burn transaction, you can withdraw the tokens on Mainnet.

The API endpoint used to generate the burn proof is as follows, where `TRANSACTION_HASH` is the transaction to `bridge()`. `EVENT_SIGNATURE` is the signature of the `Transfer` event.

https://proof-generator.polygon.technology/api/v1/matic/exit-payload/<TRANSACTION_HASH>?eventSignature=<EVENT_SIGNATURE>

Here's a sample transaction: https://polygonscan.com/tx/0x08365e09c94c5796ae300e706cc516714661a42c50dfff2fa1e9a01b036b21d6

The log topic to use is the `Transfer` function to the zero address (aka. burn).

https://polygonscan.com/tx/0x08365e09c94c5796ae300e706cc516714661a42c50dfff2fa1e9a01b036b21d6#eventlog

TRANSACTION_HASH: 0x08365e09c94c5796ae300e706cc516714661a42c50dfff2fa1e9a01b036b21d6
EVENT_SIGNATURE: 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

And the generated proof: https://proof-generator.polygon.technology/api/v1/matic/exit-payload/0x08365e09c94c5796ae300e706cc516714661a42c50dfff2fa1e9a01b036b21d6?eventSignature=0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

The result is the bytes data that is later passed to `exit()`.

If doing multiple burns in one transaction, each has to be processed individually via exit. To get a specific logIndex to generate the correct proof when doing multiple, you can append to the API URL `&tokenIndex=[INDEX_OF_TARGET_LOG]`.

## Deployed Addresses

Mainnet: [0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36](https://etherscan.io/address/0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36)
Polygon: [0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36](https://polygonscan.com/address/0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36)

Plasma
Mainnet: [0xc980508cC8866f726040Da1C0C61f682e74aBc39](https://etherscan.io/address/0xc980508cC8866f726040Da1C0C61f682e74aBc39)
Polygon: [0xc980508cC8866f726040Da1C0C61f682e74aBc39](https://polygonscan.com/address/0xc980508cC8866f726040Da1C0C61f682e74aBc39)
