# Finance Steward Smart Contracts

## Summary

The Finance Steward enables trusted execution of pre-approved and budgeted financial operations on behalf of the DAO, streamlining the management of its funds. The contracts provide role-based control for frequent financial tasks, while maintaining strict guardrails and decentralization. With a modular approach, the different contracts can be deployed independently of each other in different networks, depending on the needs and capabilities of said network.

The initial three modules are:

- Finance Steward, which handles some of the basic financial capabilities such as approvals, transfers and streams.
- PoolSteward, which handles interacting with Aave pools directly.
- MainnetSwapSteward, which handles swapping tokens.

Additionally, a 'vault' type contract is to be deployed to hold a balance of aTokens that's virtual untouchable and always in control of the DAO. The idea behind holding a minimum amount of aTokens is to prevent any index tricks on the market and also to keep some funds in order to cover bad debt should it arise.

## Motivation

The Aave DAO requires a more efficient way to manage funds without frequent on-chain voting for pre-approved proposals. The Finance Steward:

- Acts as a funds admin of the Collector (Treasury) smart contract, granting guardians (a DAO-specified multisig) specific financial permissions.
- Allows execution of common operations like asset migration, token transfers, and asset swapping within DAO-defined limits.
- Maintains decentralization and security by enforcing strict role-based permissions and budgets.

## Specification

### Overview

- **Owner**: Aave DAO
- **Guardian**: DAO-specified multisig address
- **Collector Contract**: Upgraded to support role-based permissions

**Key Actions**:

- Asset migration from v2 to v3
- Swapping tokens via approved AaveSwapper
- Token transfers and streaming to pre-approved addresses
- Withdrawals and deposits into Aave V3

**On-chain Limitations**:

- Approved addresses for transfers
- Pre-defined budgets for tokens

### Contracts and Functions

#### 1. FinanceSteward.sol

**Purpose**: Enables the Guardian to execute approved financial operations on the Aave Collector. The FinanceSteward is granted a certain budget via a governance vote and is limited in its operations to the remaining budget per token. The budgets must be reset via governance once expired.

**Key Functions**

`approve(address token, address to, uint256 amount) external onlyOwnerOrGuardian`

Approves token allowances. The spender must have been previously allowed by the DAO. Amount cannot exceed remaining budget.

`transfer(address token, address to, uint256 amount) external onlyOwnerOrGuardian`

Transfers tokens to a given address. The receiver must have been previously allowed by the DAO. Amount cannot exceed remaining budget.

`createStream(address to, StreamData memory stream) external onlyOwnerOrGuardian`

Creates a token stream to distribute tokens over time. The receiver must have been previously allowed by the DAO. Amount cannot exceed remaining budget.

`cancelStream(uint256 streamId) external onlyOwnerOrGuardian`

Cancels an active token stream.

`increaseBudget(address token, uint256 amount) external onlyOwner`

Increases the spending budget for a given token. Only callable by the DAO.

`decreaseBudget(address token, uint256 amount) external onlyOwner`

Decreases the spending budget for a given token. Only callable by the DAO.

`setWhitelistedReceiver(address to) external onlyOwner`

Adds an approved address for token transfers, streams and approvals.

---

#### 2. MainnetSwapSteward.sol

**Purpose**: Facilitates token swaps on behalf of the DAO Treasury using the Aave Swapper. Funds must be present in the Swapper in order for them to be executed. The tokens that are to be swapped from/to are to be pre-approved via governance previously.

Having previously set and validated oracles avoids mistakes that are easy to make when always passing the necessary parameters to swap.

**Key Functions**

`tokenSwap(address sellToken, uint256 amount, address buyToken, uint256 slippage) external onlyOwnerOrGuardian`

Swaps tokens within approved parameters. Performs validation on oracles for both buy and sell token.

`setSwappableToken(address token, address priceFeedUSD) external onlyOwner`

Approves a token for swapping and links their price feed.

`setPriceChecker(address newPriceChecker) external onlyOwner`

Updates the Chainlink price checker contract address. This contract validates swaps and prices according to the oracle values returned.

`setMilkman(address newMilkman) external onlyOwner`

Updates the Milkman instance for swaps. Milkman is the underlying contract by COW Swap that permits the swap of tokens with MEV protection.

**On-chain Validations**:

- Approved tokens only
- Slippage cannot exceed 10%
- Price feeds must be active and compatible.

---

#### 3. PoolV3FinSteward.sol

**Purpose**: Manages deposits, withdrawals, and asset migrations between Aave V2 and Aave V3 pools.

**Key Functions**

**Deposits and Withdrawals**:

`depositV3(address pool, address reserve, uint256 amount) external onlyOwnerOrGuardian`

Deposits tokens into an Aave V3 pool. The pool must have previously been approved by the DAO.

`withdrawV3(address pool, address reserve, uint256 amount) external onlyOwnerOrGuardian`

Withdraws tokens from an Aave V3 pool and sends to the Collector.

- `withdrawV2(address pool, address reserve, uint256 amount) external onlyOwnerOrGuardian`

Withdraws tokens from an Aave V2 pool and sends to the Collector.

**Migrations**:

`migrateBetweenV3(address fromPool, address toPool, address reserve, uint256 amount) external onlyOwnerOrGuardian`

Migrates assets between different Aave V3 pools (ie: Mainnet to Lido). Pools must have been previously approved by the DAO.

`migrateV2toV3(address v2Pool, address v3Pool, address reserve, uint256 amount) external onlyOwnerOrGuardian`

Migrates assets from an Aave V2 pool to a specific Aave V3 pool. The pools must have been previously approved by the DAO.

**Admin Actions**:

`approvePool(address pool, bool isVersion3) external onlyOwner`

Approves an Aave pool for deposits/withdrawals. Both V2 and V3 pools can be approved.

`revokePool(address pool, bool isVersion3) external onlyOwner`

Revokes permissions to perform actions with a given pool.

---

### Roles and Permissions

- **Owner**: Full control over budgets, receivers, and pool approvals. The owner is the DAO (Executor LVL 1).
- **Guardian**:
  - Executes pre-approved actions like transfers, swaps, and asset migrations.
  - Adheres to DAO-enforced budgets and limitations.
- **Collector Contract**:
  - Maintains balances, permissions, and roles (`FUNDS_ADMIN`).

---

### Deployment Notes

- Deploy the `TokenVault` contract and move minimum-allowed balances from Collector to it. The DAO is the owner of this contract.
- Deploy the `FinanceSteward` contract with the DAO as the Owner and a multisig as the Guardian.
- Deploy `MainnetSwapSteward` for token swapping with the DAO as the Owner and a multisig as the Guardian.
- Deploy `PoolV3FinSteward` for Aave-specific deposits, withdrawals, and migrations with the DAO as the Owner and a multisig as the Guardian..
- Configure budgets, whitelisted addresses, minimum balances, and approved pools as required via Governance vote.
