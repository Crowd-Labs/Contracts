// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title IStakeAndYield
 */
interface IStakeAndYield {
    function snedStakeEth(
        uint256 collectionId,
        address collectionInitiator
    ) external payable;

    function claimStakeEth(uint256 collectionId) external;

    function claimRedEnvelope(
        uint256 rewardId,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external;

    function claimMaxGas() external;

    function totalYieldAndGasReward() external returns (uint256);
}
