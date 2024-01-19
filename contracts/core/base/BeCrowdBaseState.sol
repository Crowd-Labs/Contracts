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
    uint32 public _createCollectionFee;
    address public _collectionFeeAddress;

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
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _setMaxRoyalty(uint256 newRoyalty) internal {
        uint32 prevMaxRoyalty = _maxRoyalty;
        _maxRoyalty = uint32(newRoyalty);
        emit Events.MaxRoyaltySet(
            msg.sender,
            prevMaxRoyalty,
            _maxRoyalty,
            block.timestamp
        );
    }

    function _setCreateCollectionFee(uint256 newCreateCollectionFee) internal {
        uint32 prevCreateCollectionFee = _createCollectionFee;
        _createCollectionFee = uint32(newCreateCollectionFee);
        emit Events.CreateCollectionFeeSet(
            msg.sender,
            prevCreateCollectionFee,
            _createCollectionFee,
            block.timestamp
        );
    }

    function _setCollectionFeeAddress(
        address newCollectionFeeAddress
    ) internal {
        address prevCollectionFeeAddress = _collectionFeeAddress;
        _collectionFeeAddress = newCollectionFeeAddress;
        emit Events.CollectionFeeAddressSet(
            msg.sender,
            prevCollectionFeeAddress,
            _collectionFeeAddress,
            block.timestamp
        );
    }

    function _setHubRoyalty(
        address newRoyaltyAddress,
        uint256 newRoyaltyRercentage
    ) internal {
        _royaltyAddress = newRoyaltyAddress;
        _royaltyPercentage = uint32(newRoyaltyRercentage);
        emit Events.RoyaltyDataSet(
            msg.sender,
            _royaltyAddress,
            _royaltyPercentage,
            block.timestamp
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