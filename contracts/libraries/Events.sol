// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "./DataTypes.sol";

library Events {
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin
    );

    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance
    );

    event StateSet(
        address indexed caller,
        DataTypes.State indexed prevState,
        DataTypes.State indexed newState
    );

    event MaxRoyaltySet(
        address indexed caller,
        uint32 indexed prevMaxBaseRoyalty,
        uint32 indexed newMaxBaseRoyalty
    );

    event StakeAndYieldContractAddressSet(
        address indexed caller,
        address indexed prevStakeAndYieldContractAddress,
        address indexed newStakeAndYieldContractAddress
    );

    event CreateCollectionStakeEthAmountSet(
        address indexed caller,
        uint256 indexed prevStakeEthAmount,
        uint256 indexed newStakeEthAmount
    );

    event RoyaltyDataSet(
        address indexed caller,
        address indexed royaltyAddr,
        uint32 indexed percentage
    );

    event NewCollectionCreated(
        address indexed collectionOwner,
        address derivedCollectionAddr,
        address derivedRuleModule,
        uint256 collectionId,
        uint256 baseRoyalty,
        uint256 mintLimit,
        uint256 mintExpired,
        uint256 mintPrice,
        bytes32 whiteListRootHash,
        string collInfoURI,
        string name
    );

    event BurnNFTFromCollection(
        uint256 collectionId,
        uint256 nftId,
        address burner,
        address owner
    );

    event NewNFTCreated(
        uint256 indexed tokenId,
        uint256 indexed collectionId,
        uint256 derivedFrom,
        address collectionAddr,
        address creator,
        string nftInfoURI
    );

    event BaseInitialized(string name, string symbol);

    event DerivedRuleModuleWhitelisted(
        address derivedRuleModule,
        bool whitelist
    );

    /**
     * @notice Emitted when the ModuleGlobals governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     */
    event ModuleGlobalsGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     */
    event ModuleGlobalsTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury fee is set.
     *
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     */
    event ModuleGlobalsTreasuryFeeSet(
        uint16 indexed prevTreasuryFee,
        uint16 indexed newTreasuryFee
    );

    /**
     * @notice Emitted when a currency is added to or removed from the ModuleGlobals whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     */
    event ModuleGlobalsCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted
    );

    event SetNewRoundReward(
        uint256 rewardId,
        uint256 rewardAmount,
        bytes32 merkleRoot
    );

    event ClaimYieldAndGas(
        address contractAddr,
        uint256 claimableYield,
        uint256 gasEtherBalance
    );

    event ClaimStakeEth(address staker, uint256 claimAmount);
}
