// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";
import {ModuleBase} from "./ModuleBase.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ValidationBaseRule is ModuleBase {
    function _checkMintLimit(
        uint256 alreadyMint,
        uint256 mintLimit
    ) internal pure {
        if (alreadyMint >= mintLimit) revert Errors.MintLimitExceeded();
    }

    function _checkEndTimestamp(uint40 endTimeStamp) internal view {
        if (uint40(block.timestamp) > endTimeStamp) revert Errors.MintExpired();
    }
}
