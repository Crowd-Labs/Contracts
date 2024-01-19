// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {BeCrowdStorage} from "./storage/BeCrowdStorage.sol";
import {VersionedInitializable} from "../upgradeability/VersionedInitializable.sol";
import {BeCrowdBaseState} from "./base/BeCrowdBaseState.sol";
import {IBeCrowdHub} from "../interfaces/IBeCrowdHub.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IDerivedNFT} from "../interfaces/IDerivedNFT.sol";
import {IDerivedRuleModule} from "../interfaces/IDerivedRuleModule.sol";

contract BeCrowdHub is
    VersionedInitializable,
    BeCrowdBaseState,
    BeCrowdStorage,
    IBeCrowdHub
{
    uint256 internal constant ONE_WEEK = 7 days;
    uint256 internal constant REVISION = 1;

    address internal immutable MODULE_GLOBALS;
    address internal immutable DERIVED_NFT_IMPL;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    constructor(address derivedNFTImpl, address module_globals) {
        if (derivedNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        MODULE_GLOBALS = module_globals;
        DERIVED_NFT_IMPL = derivedNFTImpl;
    }

    function initialize(address newGovernance) external override initializer {
        _setState(DataTypes.State.Paused);
        _setGovernance(newGovernance);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function setEmergencyAdmin(
        address newEmergencyAdmin
    ) external override onlyGov {
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    function setCreateCollectionFee(
        uint256 createCollectionFee
    ) external override onlyGov {
        _setCreateCollectionFee(createCollectionFee);
    }

    function setCollectionFeeAddress(
        address feeAddress
    ) external override onlyGov {
        _setCollectionFeeAddress(feeAddress);
    }

    function setMaxRoyalty(uint256 maxRoyalty) external override onlyGov {
        _setMaxRoyalty(maxRoyalty);
    }

    function setHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) external override onlyGov {
        _setHubRoyalty(newRoyaltyAddress, newRoyaltyRercentage);
    }

    function setState(DataTypes.State newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState != DataTypes.State.Paused)
                revert Errors.EmergencyAdminJustCanPause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    function whitelistDerviedModule(
        address derviedModule,
        bool whitelist
    ) external override onlyGov {
        _derivedRuleModuleWhitelisted[derviedModule] = whitelist;
        emit Events.DerivedRuleModuleWhitelisted(
            derviedModule,
            whitelist,
            block.timestamp
        );
    }

    /// ***************************************
    /// *****EXTERNAL FUNCTIONS*****
    /// ***************************************

    function createNewCollection(
        DataTypes.CreateNewCollectionData calldata vars
    ) external payable override whenNotPaused returns (uint256) {
        if (_createCollectionFee > 0) {
            if (msg.value < _createCollectionFee) {
                revert Errors.NotEnoughFunds();
            }
            payable(_collectionFeeAddress).transfer(_createCollectionFee);
            if (msg.value > _createCollectionFee) {
                payable(msg.sender).transfer(msg.value - _createCollectionFee);
            }
        }
        return _createCollection(msg.sender, vars);
    }

    function commitNewNFTIntoCollection(
        DataTypes.CreateNewNFTData calldata vars
    ) external payable override whenNotPaused returns (uint256) {
        checkParams(msg.sender, vars);

        uint256 tokenId = IDerivedNFT(
            _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
        ).mint(msg.sender, vars.derivedFrom, vars.nftInfoURI);
        IDerivedRuleModule(
            _collectionByIdCollInfo[vars.collectionId].derivedRuletModule
        ).processDerived{value: msg.value}(
            msg.sender,
            vars.collectionId,
            vars.derivedModuleData
        );
        _emitCreatedNFTEvent(tokenId, vars);
        return tokenId;
    }

    function limitBurnTokenByCollectionOwner(
        DataTypes.LimitBurnToken calldata vars
    ) external override returns (bool) {
        _validateNotPaused();
        if (_collectionByIdCollInfo[vars.collectionId].creator != msg.sender)
            revert Errors.NotCollectionOwner();
        if (vars.tokenId == 0) revert Errors.CanNotDeleteZeroNFT();
        if (
            block.timestamp >
            IDerivedNFT(
                _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
            ).getTokenMintTime(vars.tokenId) +
                ONE_WEEK
        ) {
            revert Errors.BurnExpiredOneWeek();
        }
        address ownerOfToken = IERC721(
            _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr
        ).ownerOf(vars.tokenId);

        IDerivedNFT(_collectionByIdCollInfo[vars.collectionId].derivedNFTAddr)
            .burnByCollectionOwner(vars.tokenId);

        IDerivedRuleModule(
            _collectionByIdCollInfo[vars.collectionId].derivedRuletModule
        ).processBurn(vars.collectionId, msg.sender, ownerOfToken);

        emit Events.BurnNFTFromCollection(
            vars.collectionId,
            vars.tokenId,
            msg.sender,
            ownerOfToken,
            block.timestamp
        );

        return true;
    }

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (DervideCollectionStruct memory) {
        return _collectionByIdCollInfo[collectionId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balance[owner];
    }

    function getHoldIndexes(
        address creator
    ) external view returns (uint256[] memory) {
        return _holdIndexes[creator];
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _createCollection(
        address creator,
        DataTypes.CreateNewCollectionData calldata vars
    ) internal returns (uint256) {
        _validateParams(vars.royalty);
        uint256 colltionId = _collectionCounter++;
        address derivedCollectionAddr = _deployDerivedCollection(
            creator,
            colltionId,
            vars
        );

        _setStateVariable(
            colltionId,
            creator,
            derivedCollectionAddr,
            vars.derivedRuleModule,
            vars.derivedRuleModuleInitData
        );
        _emitNewCollectionCreatedEvent(
            creator,
            colltionId,
            derivedCollectionAddr,
            vars
        );
        _emitNewCollectionInfo(vars.derivedRuleModule, colltionId);
        return colltionId;
    }

    function checkParams(
        address creator,
        DataTypes.CreateNewNFTData calldata vars
    ) internal view {
        if (!_exists(vars.collectionId)) {
            revert Errors.CollectionIdNotExist();
        }
        address derivedNFTAddr = _collectionByIdCollInfo[vars.collectionId]
            .derivedNFTAddr;
        if (IDerivedNFT(derivedNFTAddr).getLastTokenId() == 0) {
            if (
                creator != _collectionByIdCollInfo[vars.collectionId].creator ||
                vars.derivedFrom != 0
            ) {
                revert Errors.JustOwnerCanPublishRootNode();
            }
        } else {
            if (!IDerivedNFT(derivedNFTAddr).exists(vars.derivedFrom)) {
                revert Errors.DerivedFromNFTNotExist();
            }
        }
    }

    function _setStateVariable(
        uint256 colltionId,
        address creator,
        address collectionAddr,
        address ruleModule,
        bytes memory ruleModuleInitData
    ) internal returns (bytes memory) {
        if (!_derivedRuleModuleWhitelisted[ruleModule])
            revert Errors.DerivedRuleModuleNotWhitelisted();

        uint256 len = _allCollections.length;
        _balance[creator] += 1;
        _holdIndexes[creator].push(len);
        _collectionByIdCollInfo[colltionId] = DervideCollectionStruct({
            creator: creator,
            derivedNFTAddr: collectionAddr,
            derivedRuletModule: ruleModule
        });
        _allCollections.push(collectionAddr);

        return
            IDerivedRuleModule(ruleModule).initializeDerivedRuleModule(
                colltionId,
                ruleModuleInitData
            );
    }

    function _validateParams(uint256 baseRoyalty) internal view returns (bool) {
        if (baseRoyalty > _maxRoyalty) {
            revert Errors.RoyaltyTooHigh();
        }
        return true;
    }

    function _deployDerivedCollection(
        address collectionOwner,
        uint256 collectionId,
        DataTypes.CreateNewCollectionData calldata vars
    ) internal returns (address) {
        address derivedCollectionAddr = Clones.clone(DERIVED_NFT_IMPL);

        IDerivedNFT(derivedCollectionAddr).initialize(
            collectionOwner,
            collectionId,
            _royaltyAddress,
            _royaltyPercentage,
            vars.collName,
            vars.collSymbol,
            vars
        );

        return derivedCollectionAddr;
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    function getDerivedNFTImpl() external view override returns (address) {
        return DERIVED_NFT_IMPL;
    }

    function _exists(
        uint256 collectionId
    ) internal view virtual returns (bool) {
        return _collectionByIdCollInfo[collectionId].creator != address(0);
    }

    function _emitNewCollectionCreatedEvent(
        address creator,
        uint256 collectionId,
        address derivedCollectionAddr,
        DataTypes.CreateNewCollectionData calldata vars
    ) private {
        emit Events.NewCollectionCreated(
            creator,
            collectionId,
            vars.royalty,
            vars.collectionType,
            derivedCollectionAddr,
            vars.collInfoURI,
            vars.derivedRuleModule,
            block.timestamp
        );
    }

    function _emitNewCollectionInfo(
        address derivedRuleAddr,
        uint256 collectionId
    ) private {
        emit Events.NewCollectionMintInfo(
            collectionId,
            IDerivedRuleModule(derivedRuleAddr).getMintLimit(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getMintExpired(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getMintPrice(collectionId),
            IDerivedRuleModule(derivedRuleAddr).getWhiteListRootHash(
                collectionId
            )
        );
    }

    function _emitCreatedNFTEvent(
        uint256 tokenId,
        DataTypes.CreateNewNFTData calldata vars
    ) private {
        emit Events.NewNFTCreated(
            tokenId,
            vars.collectionId,
            vars.derivedFrom,
            msg.sender,
            vars.nftInfoURI
        );
    }
}
