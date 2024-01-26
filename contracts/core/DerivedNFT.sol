// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IDerivedNFT} from "../interfaces/IDerivedNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Errors} from "../libraries/Errors.sol";
import {IBlast} from "../interfaces/IBlast.sol";
import {Events} from "../libraries/Events.sol";
import {DerivedNFTBase} from "./nftmodule/DerivedNFTBase.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {RoyaltySplitter} from "./royaltySplitter/RoyaltySplitter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DerivedNFT is RoyaltySplitter, DerivedNFTBase, Ownable, IDerivedNFT {
    address internal constant BLAST_ADDRESS =
        address(0x4300000000000000000000000000000000000002);
    address public immutable REWARD_CONTRACT_ADDR;
    address public immutable HUBADDR;
    address public _collectionOwner;
    uint256 public _collectionId;
    uint256 internal _tokenIdCounter;
    uint256 internal _royalty;
    string internal _collInfoURI;
    bool private _initialized;

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint16 internal constant BASIS_POINTS = 10000;

    // We create the CollectNFT with the pre-computed HUB address before deploying the hub proxy in order
    // to initialize the hub proxy at construction.
    constructor(address hubAddr, address rewardContractAddr) {
        if (hubAddr == address(0x0) || rewardContractAddr == address(0x0))
            revert Errors.InitParamsInvalid();
        REWARD_CONTRACT_ADDR = rewardContractAddr;
        HUBADDR = hubAddr;
        _initialized = true;
        IBlast(BLAST_ADDRESS).configureClaimableYield();
        IBlast(BLAST_ADDRESS).configureClaimableGas();
    }

    function initialize(
        address collectionOwner,
        uint256 collectionId,
        address hubRoyaltyAddr,
        uint32 hubRoyaltyPercentage,
        string calldata name,
        string calldata symbol,
        DataTypes.CreateNewCollectionData calldata vars
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        _collectionOwner = collectionOwner;
        _collectionId = collectionId;
        _hubProtocolFeeAddress = hubRoyaltyAddr;
        _fixedShare = hubRoyaltyPercentage;
        _royalty = vars.royalty;
        _collInfoURI = vars.collInfoURI;
        super._initialize(name, symbol);
        _transferOwnership(collectionOwner);
    }

    function claimYieldAndGas() external {
        uint256 claimableYield = IBlast(BLAST_ADDRESS).readClaimableYield(
            address(this)
        );
        (, uint256 gasEtherBalance, , ) = IBlast(BLAST_ADDRESS).readGasParams(
            address(this)
        );
        IBlast(BLAST_ADDRESS).claimMaxGas(address(0), REWARD_CONTRACT_ADDR);
        IBlast(BLAST_ADDRESS).claimAllYield(address(0), REWARD_CONTRACT_ADDR);

        emit Events.ClaimYieldAndGas(
            address(this),
            claimableYield,
            gasEtherBalance
        );
    }

    function mint(
        address to,
        uint256 derivedfrom,
        string calldata tokenURI
    ) external override returns (uint256) {
        if (msg.sender != HUBADDR) revert Errors.NotHub();
        unchecked {
            uint256 tokenId = _tokenIdCounter++;
            _mint(to, tokenId);
            _setTokenInfo(tokenId, derivedfrom, tokenURI, to);
            _addPayee(to, 1);
            return tokenId;
        }
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {
        return (address(this), (salePrice * _royalty) / BASIS_POINTS);
    }

    function getTokenMintTime(
        uint256 tokenId
    ) external view override returns (uint256) {
        return _getTokenMintTime(tokenId);
    }

    function exists(uint256 tokenId) external view virtual returns (bool) {
        return _exists(tokenId);
    }

    function getLastTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function burnByCollectionOwner(uint256 tokenId) external {
        if (msg.sender != HUBADDR) revert Errors.NotHub();
        if (ownerOf(tokenId) != _getTokenCreator(tokenId))
            revert Errors.AlreadyTrade();
        _burn(tokenId);
    }

    function contractURI() external view returns (string memory) {
        return _collInfoURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Upon transfers, we emit the transfer event in the hub.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
