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
    error ZeroSpender();
    error NotOwnerOrApproved();
    error SignatureExpired();
    error SignatureInvalid();
    error NotHub();
    error AlreadyTrade();
    error RoyaltyTooHigh();
    error DerivedRuleModuleNotWhitelisted();
    error FollowInvalid();

    error NotEnoughNFTToMint();
    error AlreadyExceedDeadline();
    error NotInWhitelist();
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
}
