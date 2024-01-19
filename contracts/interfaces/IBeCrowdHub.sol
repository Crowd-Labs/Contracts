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
    function initialize(address newGovernance) external;

    function setGovernance(address newGovernance) external;

    function setEmergencyAdmin(address newEmergencyAdmin) external;

    function setCreateCollectionFee(uint256 createCollectionFee) external;

    function setCollectionFeeAddress(address feeAddress) external;

    function getDerivedNFTImpl() external view returns (address);

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

    function createNewCollection(
        DataTypes.CreateNewCollectionData calldata vars
    ) external payable returns (uint256);

    function commitNewNFTIntoCollection(
        DataTypes.CreateNewNFTData calldata vars
    ) external payable returns (uint256);

    function limitBurnTokenByCollectionOwner(
        DataTypes.LimitBurnToken calldata vars
    ) external returns (bool);

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (BeCrowdStorage.DervideCollectionStruct memory);

    function balanceOf(address owner) external view returns (uint256);
}
