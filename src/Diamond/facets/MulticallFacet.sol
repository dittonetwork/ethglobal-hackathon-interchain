// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BaseContract} from "../libraries/BaseContract.sol";

contract MulticallFacet is BaseContract {
    function multicall(
        bytes[] calldata data
    ) external payable onlyOwnerOrDiamondItself {
        uint256 length = data.length;

        bool success;

        for (uint256 i; i < length; ) {
            (success, ) = address(this).call(data[i]);

            // If unsuccess occured -> revert with original error message
            if (!success) {
                assembly ("memory-safe") {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            unchecked {
                ++i;
            }
        }
    }
}
