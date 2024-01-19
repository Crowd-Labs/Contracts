// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IDerivedRuleModule {
    function initializeDerivedRuleModule(
        uint256 collectionId,
        bytes calldata data
    ) external returns (bytes memory);

    function processDerived(
        address collector,
        uint256 collectionId,
        bytes calldata data
    ) external payable;

    function processBurn(
        uint256 collectionId,
        address collectionOwner,
        address refundAddr
    ) external;

    function getAlreadyMint(
        uint256 collectionId
    ) external view returns (uint256);

    function getMintLimit(uint256 collectionId) external view returns (uint256);

    function getMintExpired(
        uint256 collectionId
    ) external view returns (uint256);

    function getMintPrice(uint256 collectionId) external view returns (uint256);

    function getWhiteListRootHash(
        uint256 collectionId
    ) external view returns (bytes32);
}
