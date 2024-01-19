// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.18;

import "./ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721Enumerable {
    using Strings for uint256;

    struct TokenInfo {
        address creator;
        uint56 derivedFrom;
        uint40 timeStamp;
        string tokenUrl;
    }
    // Optional mapping for token URIs
    mapping(uint256 => TokenInfo) private _tokenInfo;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, IERC165) returns (bool) {
        return
            interfaceId == bytes4(0x49064906) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");

        string memory _tokenURI = _tokenInfo[tokenId].tokenUrl;
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenInfo(
        uint256 tokenId,
        uint256 _derivedfrom,
        string calldata _tokenURI,
        address _creator
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenInfo[tokenId].tokenUrl = _tokenURI;
        _tokenInfo[tokenId].creator = _creator;
        _tokenInfo[tokenId].derivedFrom = uint56(_derivedfrom);
        _tokenInfo[tokenId].timeStamp = uint40(block.timestamp);

        emit MetadataUpdate(tokenId);
    }

    function _getTokenCreator(uint256 tokenId) internal view returns (address) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        return _tokenInfo[tokenId].creator;
    }

    function _getTokenMintTime(
        uint256 tokenId
    ) internal view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        return _tokenInfo[tokenId].timeStamp;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenInfo[tokenId].tokenUrl).length != 0) {
            delete _tokenInfo[tokenId];
        }
    }
}
