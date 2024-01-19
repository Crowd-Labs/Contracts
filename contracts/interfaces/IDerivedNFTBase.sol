// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDerivedNFTBase {
    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NFT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;
}
