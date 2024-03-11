// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library Errors {
    error EmergencyAdminJustCanPause();
    error NotGovernanceOrEmergencyAdmin();
    error NotGovernance();
    error NotCollectionOwner();

    error InitParamsInvalid();
    error CannotInitImplementation();
    error Initialized();
    error Paused();
    error NotOwnerOrApproved();
    error NotHub();
    error AlreadyTrade();
    error RoyaltyTooHigh();
    error DerivedRuleModuleNotWhitelisted();
    error NftModuleNotWhitelisted();

    error CollectionIdNotExist();
    error JustOwnerCanPublishRootNode();
    error ModuleDataMismatch();
    error MintLimitExceeded();
    error MintExpired();

    error BurnExpiredOneWeek();
    error DerivedFromNFTNotExist();
    error NotInWhiteList();

    error NotEnoughFunds();
    error CanNotDeleteZeroNFT();

    error EmptyMerkleRoot();
    error AlreadyFinish();
    error NotEnoughEth();
    error AlreadyClaimed();
    error MerkleProofVerifyFailed();
    error SendETHFailed();

    error NotArriveClaimTime();
    error ZeroAddress();
}
