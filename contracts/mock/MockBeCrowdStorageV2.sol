// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../libraries/DataTypes.sol" as DataTypes;

/**
 * @title MockAiCooStorageV2
 *
 * @notice This is an abstract contract that *only* contains storage for the contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract MockBeCrowdStorageV2 {
    struct DervideCollectionStruct {
        address creator;
        address derivedNFTAddr;
        address derivedRuletModule;
    }

    mapping(address => bool) internal _derivedRuleModuleWhitelisted;

    mapping(address => uint256) internal _balance;
    mapping(address => uint256[]) internal _holdIndexes;
    mapping(uint256 => DervideCollectionStruct)
        internal _collectionByIdCollInfo;
    address[] _allCollections;

    uint256 internal _collectionCounter;
    address internal _governance;
    address internal _emergencyAdmin;
    uint256 internal _additionalValue;
}
