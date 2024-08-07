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
import {IStakeAndYield} from "../interfaces/IStakeAndYield.sol";
import {IBlastPoints} from "../interfaces/IBlastPoints.sol";

contract BeCrowdHub is
    IBeCrowdHub,
    VersionedInitializable,
    BeCrowdBaseState,
    BeCrowdStorage
{
    uint256 internal constant ONE_WEEK = 7 days;
    uint256 internal constant REVISION = 1;
    address internal constant BLAST_POINTS_ADDRESS =
        address(0x2536FE9ab3F511540F2f9e2eC2A805005C3Dd800);

    address internal immutable DERIVED_NFT_IMPL;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    constructor(address derivedNFTImpl) {
        if (derivedNFTImpl == address(0)) revert Errors.InitParamsInvalid();
        DERIVED_NFT_IMPL = derivedNFTImpl;
    }

    function initialize(
        address newGovernance,
        address stakeYieldAddress
    ) external override initializer {
        _setState(DataTypes.State.OpenForAll);
        _setGovernance(newGovernance);
        _setMaxRoyalty(1000);
        _setStakeEthAmountForInitialCollection(0.001 ether);
        _setHubRoyalty(newGovernance, 1000);
        _setStakeAndYieldContractAddress(stakeYieldAddress);

        IBlastPoints(BLAST_POINTS_ADDRESS).configurePointsOperator(
            address(0xbEA60bE59EC2831823CB0302d75605c39d90a259)
        );
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function setStakeEthAmountForInitialCollection(
        uint256 stakeEthAmount
    ) external override onlyGov {
        _setStakeEthAmountForInitialCollection(stakeEthAmount);
    }

    function setStakeAndYieldContractAddress(
        address contractAddr
    ) external override onlyGov {
        _setStakeAndYieldContractAddress(contractAddr);
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

    function setState(DataTypes.State newState) external override onlyGov {
        _setState(newState);
    }

    function whitelistDerviedModule(
        address[] memory derviedModules,
        bool whitelist
    ) external override onlyGov {
        for (uint256 i = 0; i < derviedModules.length; i++) {
            if (derviedModules[i] == address(0x0)) {
                revert Errors.InitParamsInvalid();
            }
            _derivedRuleModuleWhitelisted[derviedModules[i]] = whitelist;
            emit Events.DerivedRuleModuleWhitelisted(
                derviedModules[i],
                whitelist
            );
        }
    }

    /// ***************************************
    /// *****EXTERNAL FUNCTIONS*****
    /// ***************************************

    function createNewCollection(
        DataTypes.CreateNewCollectionData calldata vars
    ) external payable override whenNotPaused returns (uint256) {
        if (_stakeEthAmountForInitialCollection > 0) {
            if (msg.value < _stakeEthAmountForInitialCollection) {
                revert Errors.NotEnoughEth();
            }
            IStakeAndYield(_stakeAndYieldContractAddress).sendStakeEth{
                value: _stakeEthAmountForInitialCollection
            }(_collectionCounter, msg.sender);

            if (msg.value > _stakeEthAmountForInitialCollection) {
                (bool success1, ) = msg.sender.call{
                    value: msg.value - _stakeEthAmountForInitialCollection
                }("");
                if (!success1) {
                    revert Errors.SendETHFailed();
                }
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
        _emitCreatedNFTEvent(
            tokenId,
            _collectionByIdCollInfo[vars.collectionId].derivedNFTAddr,
            vars
        );
        return tokenId;
    }

    function limitBurnTokenByCollectionOwner(
        DataTypes.LimitBurnToken calldata vars
    ) external payable override returns (bool) {
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
        ).processBurn{value: msg.value}(
            vars.collectionId,
            msg.sender,
            ownerOfToken
        );

        emit Events.BurnNFTFromCollection(
            vars.collectionId,
            vars.tokenId,
            msg.sender,
            ownerOfToken
        );

        return true;
    }

    function setNewRoundReward(
        uint256 rewardAmount,
        bytes32 merkleRoot
    ) external onlyGov {
        uint256 rewardId = IStakeAndYield(_stakeAndYieldContractAddress)
            ._nextRewardId();
        IStakeAndYield(_stakeAndYieldContractAddress).setNewRoundReward(
            rewardAmount,
            merkleRoot
        );
        emit Events.SetNewRoundReward(rewardId, rewardAmount, merkleRoot);
    }

    function getCollectionInfo(
        uint256 collectionId
    ) external view returns (DervideCollectionStruct memory) {
        return _collectionByIdCollInfo[collectionId];
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

        _collectionByIdCollInfo[colltionId] = DervideCollectionStruct({
            creator: creator,
            derivedNFTAddr: collectionAddr,
            derivedRuletModule: ruleModule
        });

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
        address derivedCollectionAddr = Clones.cloneDeterministic(
            DERIVED_NFT_IMPL,
            keccak256(abi.encodePacked(collectionId))
        );

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
        emit Events.GovernanceSet(msg.sender, prevGovernance, newGovernance);
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
            derivedCollectionAddr,
            vars.derivedRuleModule,
            IDerivedRuleModule(vars.derivedRuleModule).getCurrency(
                collectionId
            ),
            collectionId,
            vars.royalty,
            IDerivedRuleModule(vars.derivedRuleModule).getMintLimit(
                collectionId
            ),
            IDerivedRuleModule(vars.derivedRuleModule).getMintExpired(
                collectionId
            ),
            IDerivedRuleModule(vars.derivedRuleModule).getMintPrice(
                collectionId
            ),
            IDerivedRuleModule(vars.derivedRuleModule).getWhiteListRootHash(
                collectionId
            ),
            vars.collInfoURI,
            vars.collName
        );
    }

    function _emitCreatedNFTEvent(
        uint256 tokenId,
        address collectionAddr,
        DataTypes.CreateNewNFTData calldata vars
    ) private {
        emit Events.NewNFTCreated(
            tokenId,
            vars.collectionId,
            vars.derivedFrom,
            collectionAddr,
            msg.sender,
            vars.nftInfoURI
        );
    }
}
