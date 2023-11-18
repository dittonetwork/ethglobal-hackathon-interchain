// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BaseContract {
    modifier onlyOwnerOrDiamondItself() {
        _checkOnlyOwnerOrDiamondItself(msg.sender);

        _;
    }

    function _checkOnlyOwnerOrDiamondItself(
        address account
    ) internal view virtual {
        if (account == address(this)) {
            return;
        }

        if (account != LibDiamond.contractOwner()) {
            revert("Not owner or diamond");
        }
    }
}
