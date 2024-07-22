# Aave Arbitrum -> Mainnet ERC20 Bridge

Arbitrum does offer a way to bridge directly from their network to Mainnet using their standard ArbERC20 tokens. There is a 'gateway' address that is used to bridge to mainnet. It can be called from the tokens themselves, however, it requires some domain knowledge. This contract facilitates the bridging of tokens in order to make managing Aave DAO's treasury easier.

The same contract exists on both chains with the same address, so this contract will receive funds from the Arbitrum Collector, then call to bridge the received tokens. After the Arbitrum rollup happens, the "burn proof" will be generated via API. At this point, the mainnet contract can be called. `exit()` will give the mainnet collector contract the tokens that were bridged over from Arbitrum.

In order to generate the proof for an exit, as well as the other required data, please install the `aave-cli` tool which can be found [here](https://github.com/bgd-labs/aave-cli).

In order to generate the proof, run the following command:

`aave-cli arbitrum-bridge-exit [TX_HASH] [INDEX] [ARBITRUM_BLOCK_OF_TX]`

Where the TX_HASH is the hash where the bridge was initiated on Arbitrum, the INDEX is the withdrawal index (ie: if there are 3 tokens bridged in the same transaction, the indexes will be 0, 1 and 2), and ARBITRUM_BLOCK_OF_TX, which is the block the bridge transaction happened at.

## Functions

```
function bridge(
    address token,
    address l1Token,
    address gateway,
    uint256 amount
  ) external;
```

Callable on Arbitrum to withdraw ERC20 token. It withdraws `amount` of passed `token` to mainnet. The gateway address can be found either in the token's read methods where it's called `l1gateway()` or `gateway()`, depending on the token. You can also refer to the Arbitrum [docs](https://docs.arbitrum.io/build-decentralized-apps/token-bridging/token-bridge-erc20#other-flavors-of-gateways) and the relevant [addresses](https://docs.arbitrum.io/build-decentralized-apps/reference/useful-addresses).

```
function exit(
    bytes32[] calldata proof,
    uint256 index,
    address l2sender,
    address to,
    uint256 l2block,
    uint256 l1block,
    uint256 l2timestamp,
    uint256 value,
    bytes calldata data
  ) external
```

Callable on Mainnet to finish the withdrawal process. Callable ~7 days after `bridge()` is called and proof is available via `aave-cli`. Arbitrum currently doesn't support getting this information via API (we have requested this feature).

`function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;`

Callable on Arbitrum. Withdraws tokens from bridge contract back to Aave Collector on Arbitrum.

## Burn Proof Generation

After you have called `bridge()` Arbitrum, it will take ~7 days for the withdrawal to be available (it's a rollup solution after all). Once it's available, a user can withdraw on Mainnet.

Here's a sample transaction: https://arbiscan.io/tx/0x726c0b903d77088af36e06dfe6fd40df318ba83b8a93726fa30fab018cb43357

https://arbiscan.io/tx/0x726c0b903d77088af36e06dfe6fd40df318ba83b8a93726fa30fab018cb43357#eventlog

The relevant log in this example is #7, from address `0x0000000000000000000000000000000000000064` which is an Arbitrum pre-compiled contract. Foundry does not currently support pre-compiled contracts in any networks other than Mainnet, so unfortunately a script cannot be used to run test commands. You can use the arbiscan.io UI as an alternative.

The exit transaction is here: https://etherscan.io/tx/0xa34c3725cc95773eedf96b03e9672ad77940b27fc5b1b94441e6587dec014ecd

You can see the input data which was retrieved via the Aave CLI tool.

## Deployed Addresses

Mainnet: [0x0335ffa9af5ce05590d6c9a75b645470e07744a9](https://etherscan.io/address/0x0335ffa9af5ce05590d6c9a75b645470e07744a9)
Arbitrum: [0x0335ffa9af5ce05590d6c9a75b645470e07744a9](https://arbiscan.io/address/0x0335ffa9af5ce05590d6c9a75b645470e07744a9)

Confirmed Bridges:

| Token            | Can Bridge | Burn                                                                                            | Exit                                                                                             |
| ---------------- | ---------- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| USDC (Native)    | NO         | N/A                                                                                             | N/A                                                                                              |
| USDC.e (Bridged) | YES        | [Tx](https://arbiscan.io/tx/0x4d64e1200e55d745428af2ad57af72c345dd47e736227b8ad1fefc9a6dde0bbe) | [Tx](https://etherscan.io/tx/0x43f861ded0892ea3f67bba45b331d3fc816546d1a6a4de59dce455d37d15c2e3) |
| WETH             | YES        | [Tx](https://arbiscan.io/tx/0xa466214026874d294dc1b2ec188ce29f44eda24917729841b96c9dbd53be3f4b) | [Tx](https://etherscan.io/tx/0x082ac47de76e638afd89f0c0dc9dd6a79f0bec61daa5f9280842fbfd583d18e5) |
| WBTC             | YES        | [Tx](https://arbiscan.io/tx/0x3f05e30984c67b21a9bce4866336bf0da6f90a29a9346f1f121f5adeb773c3df) | [Tx](https://etherscan.io/tx/0x0e8875142024a5243d48262b12df051eec32c04d5bf9512b0f92c7c8e27cecb8) |
| wstETH           | NO         | N/A                                                                                             | N/A                                                                                              |
| DAI              | YES        | [Tx](https://arbiscan.io/tx/0x1ce3cf0f0e6dc01fc2e78105cd3c0a24b3d517cef83b8e54c8321cdd177381c6) | [Tx](https://etherscan.io/tx/0xb2901150d654c2751d9624afbaf70386d38415d47e8b4fee512c09ea7503e38f) |
| EURS             | NO         | N/A                                                                                             | N/A                                                                                              |
| AAVE             | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| MAI              | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| rETH             | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| LUSD             | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| FRAX             | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| ARB              | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
| weETH            | YES        | [Tx]()                                                                                          | [Tx]()                                                                                           |
