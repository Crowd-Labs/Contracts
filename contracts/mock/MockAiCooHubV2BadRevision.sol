// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {MockBeCrowdStorageV2} from "./MockBeCrowdStorageV2.sol";
import {VersionedInitializable} from "../upgradeability/VersionedInitializable.sol";
import {BeCrowdBaseState} from "../core/base/BeCrowdBaseState.sol";
import {IBeCrowdHub} from "../interfaces/IBeCrowdHub.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IDerivedNFT} from "../interfaces/IDerivedNFT.sol";
import {IDerivedRuleModule} from "../interfaces/IDerivedRuleModule.sol";

contract MockAiCooHubV2BadRevision is
    VersionedInitializable,
    BeCrowdBaseState,
    MockBeCrowdStorageV2
{
    uint256 internal constant REVISION = 1;

    function initialize(uint256 newValue) external initializer {
        _additionalValue = newValue;
    }

    function setAdditionalValue(uint256 newValue) external {
        _additionalValue = newValue;
    }

    function getAdditionalValue() external view returns (uint256) {
        return _additionalValue;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
