// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";
import {BeCrowdStorage} from "../core/storage/BeCrowdStorage.sol";

/**
 * @title IBeCrowdHub
 *
 * @notice This is the interface for the contract, the main entry point for the protocol.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface IBeCrowdHub {
    function initialize(
        address newGovernance,
        address stakeYieldAddress
    ) external;

    function setGovernance(address newGovernance) external;

    function setEmergencyAdmin(address newEmergencyAdmin) external;

    function setStakeEthAmountForInitialCollection(
        uint256 createCollectionFee
    ) external;

    function setStakeAndYieldContractAddress(address contractAddr) external;

    function setState(DataTypes.State newState) external;

    function setMaxRoyalty(uint256 maxRoyalty) external;

    function setHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) external;

    function whitelistDerviedModule(
        address derviedModule,
        bool whitelist
    ) external;

    function whitelistNftModule(address nftModule, bool whitelist) external;

    function createNewCollection(
        DataTypes.CreateNewCollectionData calldata vars
    ) external payable returns (uint256);

    function commitNewNFTIntoCollection(
        DataTypes.CreateNewNFTData calldata vars
    ) external payable returns (uint256);

    function limitBurnTokenByCollectionOwner(
        DataTypes.LimitBurnToken calldata vars
    ) external returns (bool);

    function claimStakeEth(uint256 collectionId) external;

    function setNewRoundReward(
        uint256 rewardAmount,
        bytes32 merkleRoot
    ) external;

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (BeCrowdStorage.DervideCollectionStruct memory);

    function balanceOf(address owner) external view returns (uint256);
}
