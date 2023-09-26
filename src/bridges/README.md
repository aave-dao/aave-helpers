# Aave Polygon -> Mainnet ERC20 Bridge

Currently, there is no built-in function to be able to bridge tokens held in contracts from Polygon to Ethereum mainnet. The reason is because the `ERC20::withdraw()` mechanism available on the PoS bridge, goes from the calling address to the same address on the other chain. There is no way to choose an address on withdraw for some tokens. The Polygon team is working on this with their FxPortal, but not all tokens exist and for USDC, this is the only way to bridge from Polygon to Mainnet.

The same contract exists on both chains with the same address, so this contract will receive funds from the Polygon Collector, then call to withdraw. After the Polygon checkpoint happens, the "burn proof" will be generated via API. At this point, the mainnet contract can be called. `exit()` will give the mainnet contract the tokens that were bridged over from Polygon. At this point, `withdrawToCollector()` can be called and the Ethereum mainnet Aave Collector will receive the USDC tokens.

## Functions

`function bridge(address token, uint256 amount) external;`

Callable on Polygon to withdraw ERC20 token. It withdraws `amount` of passed `token` to mainnet.

`function exit(bytes calldata burnProof) external;`

Callable on Mainnet to finish the withdrawal process. Callable 30-90 minutes after `bridge()` is called and proof is available via API.

`function withdrawToCollector(address token) external;`

Callable on Mainnet. Withdraws balance of held token to the Aave Collector.

`function rescueTokens(address[] calldata tokens) external;`

Callable on Polygon. Withdraws tokens from bridge contract back to Aave Collector on Polygon.

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

## Deployed Addresses

Mainnet:
Polygon:
