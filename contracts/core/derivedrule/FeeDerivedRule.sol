// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IDerivedRuleModule} from "../../interfaces/IDerivedRuleModule.sol";
import {ValidationBaseRule} from "./base/ValidationBaseRule.sol";
import {FeeModuleBase} from "./base/FeeModuleBase.sol";
import {ModuleBase} from "./base/ModuleBase.sol";
import {Errors} from "../../libraries/Errors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param amount The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param recipient The recipient address associated with this publication.
 */
struct DerivedRuleData {
    uint256 mintLimit;
    uint256 alreadyMint;
    uint256 amount;
    address currency;
    address recipient;
    uint40 endTimestamp;
}

/**
 * @title FeeDerivedRule
 * @author Lens Protocol
 *
 * @notice This is a simple Lens CollectModule implementation, inheriting from the ICollectModule interface and
 * the FeeCollectModuleBase abstract contract.
 *
 * This module works by allowing unlimited collects for a publication at a given price.
 */
contract FeeDerivedRule is
    FeeModuleBase,
    ValidationBaseRule,
    IDerivedRuleModule
{
    using SafeERC20 for IERC20;

    mapping(uint256 => DerivedRuleData)
        internal _dataByDerivedRuleByCollectionId;

    constructor(
        address hubAddr,
        address moduleGlobals
    ) FeeModuleBase(moduleGlobals) ModuleBase(hubAddr) {}

    function initializeDerivedRuleModule(
        uint256 collectionId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            uint256 mintLimit,
            uint256 endTime,
            uint256 amount,
            address currency,
            address recipient
        ) = abi.decode(data, (uint256, uint256, uint256, address, address));
        if (
            !_currencyWhitelisted(currency) ||
            recipient == address(0) ||
            amount == 0 ||
            endTime <= block.timestamp ||
            mintLimit > 10000
        ) revert Errors.InitParamsInvalid();

        _dataByDerivedRuleByCollectionId[collectionId].mintLimit = mintLimit;
        _dataByDerivedRuleByCollectionId[collectionId].amount = amount;
        _dataByDerivedRuleByCollectionId[collectionId].currency = currency;
        _dataByDerivedRuleByCollectionId[collectionId].recipient = recipient;
        _dataByDerivedRuleByCollectionId[collectionId].endTimestamp = uint40(
            endTime
        );

        return data;
    }

    function processDerived(
        address collector,
        uint256 collectionId,
        bytes calldata data
    ) external payable virtual override onlyHub {
        _checkEndTimestamp(
            _dataByDerivedRuleByCollectionId[collectionId].endTimestamp
        );
        _checkMintLimit(
            _dataByDerivedRuleByCollectionId[collectionId].alreadyMint,
            _dataByDerivedRuleByCollectionId[collectionId].mintLimit
        );

        _processDerived(collector, collectionId, data);
    }

    function processBurn(
        uint256 collectionId,
        address collectionOwner,
        address refundAddr
    ) external payable virtual override onlyHub {
        if (
            address(0x1) ==
            _dataByDerivedRuleByCollectionId[collectionId].currency
        ) {
            uint256 mintPrice = _dataByDerivedRuleByCollectionId[collectionId]
                .amount;
            if (mintPrice == 0) {
                return;
            }
            if (msg.value >= mintPrice) {
                (bool success, ) = payable(refundAddr).call{value: mintPrice}(
                    ""
                );
                if (success) {
                    revert Errors.SendETHFailed();
                }
                if (msg.value > mintPrice) {
                    (bool success1, ) = payable(collectionOwner).call{
                        value: msg.value - mintPrice
                    }("");
                    if (success1) {
                        revert Errors.SendETHFailed();
                    }
                }
            } else {
                revert Errors.NotEnoughEth();
            }
        } else {
            IERC20(_dataByDerivedRuleByCollectionId[collectionId].currency)
                .safeTransferFrom(
                    collectionOwner,
                    refundAddr,
                    _dataByDerivedRuleByCollectionId[collectionId].amount
                );
        }
    }

    function getPublicationData(
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

    function getMintPrice(
        uint256 collectionId
    ) external view returns (uint256) {
        return _dataByDerivedRuleByCollectionId[collectionId].amount;
    }

    function getCurrency(uint256 collectionId) external view returns (address) {
        return _dataByDerivedRuleByCollectionId[collectionId].currency;
    }

    function getWhiteListRootHash(uint256) external pure returns (bytes32) {
        return bytes32(0x0);
    }

    function _processDerived(
        address collector,
        uint256 collectionId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByDerivedRuleByCollectionId[collectionId].amount;
        address currency = _dataByDerivedRuleByCollectionId[collectionId]
            .currency;
        _validateDataIsExpected(data, currency, amount);

        (address treasury, uint16 treasuryFee) = _treasuryData();
        address recipient = _dataByDerivedRuleByCollectionId[collectionId]
            .recipient;
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;

        if (address(0x1) == currency) {
            if (msg.value >= amount) {
                (bool success, ) = recipient.call{value: adjustedAmount}("");
                (bool success1, ) = treasury.call{value: treasuryAmount}("");
                if (!success || !success1) {
                    revert Errors.SendETHFailed();
                }
                if (msg.value > amount) {
                    (bool success2, ) = collector.call{
                        value: msg.value - amount
                    }("");
                    if (success2) {
                        revert Errors.SendETHFailed();
                    }
                }
            } else {
                revert Errors.NotEnoughFunds();
            }
        } else {
            IERC20(currency).safeTransferFrom(
                collector,
                recipient,
                adjustedAmount
            );
            if (treasuryAmount > 0)
                IERC20(currency).safeTransferFrom(
                    collector,
                    treasury,
                    treasuryAmount
                );
        }

        ++_dataByDerivedRuleByCollectionId[collectionId].alreadyMint;
    }
}
