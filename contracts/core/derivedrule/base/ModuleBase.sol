// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";

abstract contract ModuleBase {
    address public immutable HUBADDR;

    modifier onlyHub() {
        if (msg.sender != HUBADDR) revert Errors.NotHub();
        _;
    }

    constructor(address hubAddr) {
        if (hubAddr == address(0)) revert Errors.InitParamsInvalid();
        HUBADDR = hubAddr;
        emit Events.ModuleBaseConstructed(hubAddr, block.timestamp);
    }
}
