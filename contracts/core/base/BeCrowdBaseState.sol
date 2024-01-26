// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Events} from "../../libraries/Events.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

abstract contract BeCrowdBaseState {
    DataTypes.State public _state;
    address public _royaltyAddress;
    uint32 public _royaltyPercentage;
    uint32 public _maxRoyalty;
    uint256 public _stakeEthAmountForInitialCollection;
    address public _stakeAndYieldContractAddress;

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    function getState() external view returns (DataTypes.State) {
        return _state;
    }

    function _setState(DataTypes.State newState) internal {
        DataTypes.State prevState = _state;
        _state = newState;
        emit Events.StateSet(msg.sender, prevState, newState);
    }

    function _setMaxRoyalty(uint256 newRoyalty) internal {
        uint32 prevMaxRoyalty = _maxRoyalty;
        _maxRoyalty = uint32(newRoyalty);
        emit Events.MaxRoyaltySet(msg.sender, prevMaxRoyalty, _maxRoyalty);
    }

    function _setStakeEthAmountForInitialCollection(
        uint256 newStakerEthAmount
    ) internal {
        uint256 prevStakeEthAmountForInitialCollection = _stakeEthAmountForInitialCollection;
        _stakeEthAmountForInitialCollection = newStakerEthAmount;
        emit Events.CreateCollectionStakeEthAmountSet(
            msg.sender,
            prevStakeEthAmountForInitialCollection,
            _stakeEthAmountForInitialCollection
        );
    }

    function _setStakeAndYieldContractAddress(
        address newCollectionFeeAddress
    ) internal {
        if (newCollectionFeeAddress == address(0x0))
            revert Errors.InitParamsInvalid();
        address prevCollectionFeeAddress = _stakeAndYieldContractAddress;
        _stakeAndYieldContractAddress = newCollectionFeeAddress;
        emit Events.StakeAndYieldContractAddressSet(
            msg.sender,
            prevCollectionFeeAddress,
            _stakeAndYieldContractAddress
        );
    }

    function _setHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) internal {
        if (newRoyaltyAddress == address(0x0))
            revert Errors.InitParamsInvalid();
        _royaltyAddress = newRoyaltyAddress;
        _royaltyPercentage = uint32(newRoyaltyRercentage);
        emit Events.RoyaltyDataSet(
            msg.sender,
            _royaltyAddress,
            _royaltyPercentage
        );
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.State.Paused) revert Errors.Paused();
        if (
            _maxRoyalty == 0 ||
            _royaltyAddress == address(0x0) ||
            _royaltyPercentage == 0
        ) revert Errors.InitParamsInvalid();
    }
}
