# Aave Polygon -> Mainnet ERC20 Bridge

Currently, there is no built-in function to be able to bridge tokens held in contracts from Polygon to Ethereum mainnet. The reason is because the `ERC20::withdraw()` mechanism available on the PoS bridge, goes from the calling address to the same address on the other chain. There is no way to choose an address on withdraw for some tokens. The Polygon team is working on this with their FxPortal, but not all tokens exist and for USDC, this is the only way to bridge from Polygon to Mainnet.

The same contract exists on both chains with the same address, so this contract will receive funds from the Polygon Collector, then call to withdraw. After the Polygon checkpoint happens, the "burn proof" will be generated via API. At this point, the mainnet contract can be called. `exit()` will give the mainnet contract the tokens that were bridged over from Polygon. At this point, `withdrawToCollector()` can be called and the Ethereum mainnet Aave Collector will receive the USDC tokens.

## Functions

`function isTokenMapped(address l2token) external view returns(bool);`

Callable on Mainnet. Returns whether a token mapping exists between Polygon and Mainnet.

**DO NOT BRIDGE** if this function returns false, funds will be lost forever.

Here's a list of Polygon Aave V2 and Aave V3 tokens and whether they are mapped or not, and respective transactions showing a bridge.

| Token | Is Mapped | Burn | Exit |
| --- | --- | --- | --- |
| USDC | yes | [Tx](https://polygonscan.com/tx/0xd670439927d5b067b742e79a2c2f8ac375f38ac0fe77b77bfcdd5a4d7b60f8b7) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| DAI | yes | [Tx](https://polygonscan.com/tx/0x3827bda3f18f117b1b216b2152465708a6e72dfb8bbb2f91c0dcf7a19f817fcc) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| LINK | yes | [Tx](https://polygonscan.com/tx/0x5cbe8749bb496627ab6f53c3ef7f8b451c2f9a3e7933c0231f09d70696615e20) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| WBTC | yes | [Tx](https://polygonscan.com/tx/0xd95ba8488fb67146b7a5946977db3c74433928c0cf1ef08802e46b40cd8a53d6) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| CRV | yes | [Tx](https://polygonscan.com/tx/0x144f5532d1bf88bbdbd914c9d79caaf7e3861aefb0412db69fd46136a4232246) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| BAL | yes | [Tx](https://polygonscan.com/tx/0xafa75edc210566b4d9e3b0986c433f77531eae8a3fb51d4b4e27bf0b241782bb) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| USDT | yes | [Tx](https://polygonscan.com/tx/0xfd091ad2753435126d09c88168234a0c8d536ebc1c942359f02081f8a9d595a2) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) | [Tx](https://polygonscan.com/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| WETH | yes | [Tx](https://polygonscan.com/tx/0x813c4821f5da822a0f60db31070ca025f57ff81953f42f95270a77bc941b266d) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| WMATIC | NO | NO | NO |
| AAVE | yes | [Tx](https://polygonscan.com/tx/0x338f0b763cd4f4080cb0f54a8b76172cd750a21d3f2960ef6e19960a0e9c7df2) | [Tx](https://etherscan.io/tx/0x5b410b2d35acefe23785fca64242521503720c89540cba7580a96c7d48de65ff) |
| GHST | yes | | |
| DPI | yes | | |
| SUSHI | yes | | |
| EURS | yes | | |
| jEUR | NO | NO | NO |
| agEUR | yes | | |
| miMATIC | NO | NO | NO |
| stMATIC | yes | | |
| MaticX  | yes | | |
| wstETH  | yes | [Tx](https://polygonscan.com/tx/0x30a6f403211fea0edcd2fcd89e505eb0bd6b584a375482e80beec21537a20291) | [Tx](https://etherscan.io/tx/0xa521582be2bb589055827d1556acc4255dad981286ec01942a991b0d31edceaa) |

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

Here's a sample transaction: https://polygonscan.com/tx/0xafa75edc210566b4d9e3b0986c433f77531eae8a3fb51d4b4e27bf0b241782bb

The log topic to use is the `Transfer` function to the zero address (aka. burn).

https://polygonscan.com/tx/0xafa75edc210566b4d9e3b0986c433f77531eae8a3fb51d4b4e27bf0b241782bb#eventlog

TRANSACTION_HASH: 0xafa75edc210566b4d9e3b0986c433f77531eae8a3fb51d4b4e27bf0b241782bb
EVENT_SIGNATURE: 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

And the generated proof: https://proof-generator.polygon.technology/api/v1/matic/exit-payload/0xafa75edc210566b4d9e3b0986c433f77531eae8a3fb51d4b4e27bf0b241782bb?eventSignature=0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef

The result is the bytes data that is later passed to `exit()`.

If doing multiple burns in one transaction, each proof has to be generated individually. To get a specific logIndex to generate the correct proof when doing multiple, you can append to the API URL `&tokenIndex=[INDEX_OF_TARGET_LOG]`. The Index of the target log is the # of the `Transfer()` function, with a 0 based index. A sample transaction with multiple burns can be seen [here.](https://polygonscan.com/tx/0xc73b85175045e272161abe38b25eac76546eea20247d0947926d7ef4e901b567#eventlog)
An array of proofs can be passed to the `exit(bytes[] memory proofs)` function to do all withdrawals in a single transaction instead of the regular `exit(bytes memory proof)` method, on the Mainnet contract.

## Deployed Addresses

Mainnet: [0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36](https://etherscan.io/address/0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36)
Polygon: [0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36](https://polygonscan.com/address/0x1C2BA5b8ab8e795fF44387ba6d251fa65AD20b36)
