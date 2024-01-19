// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {IDerivedNFTBase} from "../../interfaces/IDerivedNFTBase.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";
import {ERC721Derived} from "../base/ERC721Derived.sol";
import {ERC721URIStorage} from "../base/ERC721URIStorage.sol";

abstract contract DerivedNFTBase is ERC721URIStorage, IDerivedNFTBase {
    /**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(
        string calldata name,
        string calldata symbol
    ) internal {
        ERC721Derived.__ERC721_Init(name, symbol);

        emit Events.BaseInitialized(name, symbol, block.timestamp);
    }

    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }
}
