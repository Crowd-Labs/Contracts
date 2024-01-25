// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IDerivedNFT
 *
 * @notice This is the interface for the DerivedNFT contract. Which is cloned upon the New NFT Collection
 *
 */
interface IDerivedNFT {
    function initialize(
        address collectionOwner,
        uint256 collectionId,
        address opTreeHubRoyaltyAddress,
        uint32 opTreeHubRoyaltyRercentage,
        string calldata name,
        string calldata symbol,
        DataTypes.CreateNewCollectionData calldata vars
    ) external;

    function mint(
        address to,
        uint256 derivedfrom,
        string calldata tokenURI
    ) external returns (uint256);

    function claimYieldAndGas() external;

    function burnByCollectionOwner(uint256 tokenId) external;

    function getLastTokenId() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function contractURI() external view returns (string memory);

    function getTokenMintTime(uint256 tokenId) external view returns (uint256);
}
