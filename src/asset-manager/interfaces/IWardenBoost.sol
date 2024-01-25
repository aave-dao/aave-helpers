// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWardenBoost {
  struct BoostOffer {
    // Address of the user making the offer
    address user;
    // Price per vote per second, set by the user
    uint256 pricePerVote;
    // Max duration a Boost from this offer can last
    uint64 maxDuration;
    // Timestamp of expiry of the Offer
    uint64 expiryTime;
    // Minimum percent of users voting token balance to buy for a Boost
    uint16 minPerc; //bps
    // Maximum percent of users total voting token balance available to delegate
    uint16 maxPerc; //bps
    // Use the advised price instead of the Offer one
    bool useAdvicePrice;
  }

  /// @notice Claim rewards for selling boost
  function claim() external returns (bool);

  /// @notice Retrieve the veBoost address for Warden contract
  function delegationBoost() external returns (address);

  /// @param boostId Id of Boost to check offers for
  function offers(uint256 boostId) external returns (BoostOffer memory);

  /// @notice Registers a new user wanting to sell its delegation
  /// @dev Regsiters a new user, creates a BoostOffer with the given parameters
  /// @param pricePerVote Price of 1 vote per second (in wei)
  /// @param maxDuration Maximum duration (in weeks) that a Boost can last when taken from this Offer
  /// @param expiryTime Timestamp when this Offer is not longer valid
  /// @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
  /// @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
  /// @param useAdvicePrice True to use the advice Price instead of the given pricePerVote
  function register(
    uint256 pricePerVote,
    uint64 maxDuration,
    uint64 expiryTime,
    uint16 minPerc,
    uint16 maxPerc,
    bool useAdvicePrice
  ) external returns (bool);

  /// @notice Update an existing boost offer
  /// @param pricePerVote Price of 1 vote per second (in wei)
  /// @param maxDuration Maximum duration (in weeks) that a Boost can last when taken from this Offer
  /// @param expiryTime Timestamp when this Offer is no longer valid
  /// @param minPerc Minimum percent of users voting token balance to buy for a Boost (in BPS)
  /// @param maxPerc Maximum percent of users total voting token balance available to delegate (in BPS)
  /// @param useAdvicePrice True to use the advice Price instead of the given pricePerVote
  function updateOffer(
    uint256 pricePerVote,
    uint64 maxDuration,
    uint64 expiryTime,
    uint16 minPerc,
    uint16 maxPerc,
    bool useAdvicePrice
  ) external returns (bool);

  /// @notice Remove an existing boost offer
  function quit() external returns (bool);

  /// @notice Estimate current market feeds
  /// @param delegator Address of user to purchase boost from
  /// @param amount Amount of boost to purchase
  /// @param duration Number of weeks to purchase boost for
  function estimateFees(
    address delegator,
    uint256 amount,
    uint256 duration //in weeks
  ) external view returns (uint256);

  /// @notice Duration in weeks (ie: 1 for 1 Week)
  /// @param delegator Address of user to buy boost from
  /// @param receiver Address receiving the boost
  /// @param amount The amount of boost to purchase
  /// @param duration The number of weeks to buy boost for
  function buyDelegationBoost(
    address delegator,
    address receiver,
    uint256 amount,
    uint256 duration, //in weeks
    uint256 maxFeeAmount
  ) external returns (uint256);
}
