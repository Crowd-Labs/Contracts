// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title IStakeAndYield
 */
interface IStakeAndYield {
    function sendStakeEth(
        uint256 collectionId,
        address collectionInitiator
    ) external payable;

    function claimStakeEth(uint256 collectionId) external;

    function claimReward(
        uint256 rewardId,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external;

    function setNewRoundReward(
        uint256 rewardAmount,
        bytes32 merkleRoot
    ) external;

    function _nextRewardId() external returns (uint256);

    function claimMaxGas() external;

    function totalYieldAndGasReward() external returns (uint256);
}
