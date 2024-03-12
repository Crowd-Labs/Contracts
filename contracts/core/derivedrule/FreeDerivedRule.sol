// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IDerivedRuleModule} from "../../interfaces/IDerivedRuleModule.sol";
import {ModuleBase} from "./base/ModuleBase.sol";
import {ValidationBaseRule} from "./base/ValidationBaseRule.sol";
import {Errors} from "../../libraries/Errors.sol";

contract FreeDerivedRule is ValidationBaseRule, IDerivedRuleModule {
    constructor(address hubAddr) ModuleBase(hubAddr) {}

    struct DerivedRuleData {
        uint256 mintLimit;
        uint208 alreadyMint;
        uint40 endTimestamp;
    }
    mapping(uint256 => DerivedRuleData)
        internal _dataByDerivedRuleByCollectionId;

    function initializeDerivedRuleModule(
        uint256 collectionId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (uint256 mintLimit, uint256 endTime) = abi.decode(
            data,
            (uint256, uint256)
        );
        if (endTime <= block.timestamp || mintLimit > 10000)
            revert Errors.InitParamsInvalid();

        _dataByDerivedRuleByCollectionId[collectionId] = DerivedRuleData(
            mintLimit,
            0,
            uint40(endTime)
        );
        return data;
    }

    function processDerived(
        address,
        uint256 collectionId,
        bytes calldata
    ) external payable override {
        _checkEndTimestamp(
            _dataByDerivedRuleByCollectionId[collectionId].endTimestamp
        );
        _checkMintLimit(
            _dataByDerivedRuleByCollectionId[collectionId].alreadyMint,
            _dataByDerivedRuleByCollectionId[collectionId].mintLimit
        );
        ++_dataByDerivedRuleByCollectionId[collectionId].alreadyMint;
    }

    function getDerivedRuleDataByCollectionId(
        uint256 collectionId
    ) external view returns (DerivedRuleData memory) {
        return _dataByDerivedRuleByCollectionId[collectionId];
    }

    function getAlreadyMint(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].alreadyMint;
    }

    function getMintLimit(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].mintLimit;
    }

    function getMintExpired(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].endTimestamp;
    }

    function getCurrency(uint256) external pure returns (address) {
        return address(0x0);
    }

    function getMintPrice(uint256) external pure returns (uint256) {
        return 0;
    }

    function getWhiteListRootHash(uint256) external pure returns (bytes32) {
        return bytes32(0x0);
    }

    function processBurn(
        uint256 collectionId,
        address collectionOwner,
        address refundAddr
    ) external virtual override onlyHub {}
}
