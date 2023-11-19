// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {BaseContract} from "../libraries/BaseContract.sol";
import {Utils} from "../libraries/Utils.sol";

interface IBridge {
    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;
}

contract CelerBridge is BaseContract {
    using Utils for address;

    IBridge private immutable bridge;

    constructor(address _bridge) {
        bridge = IBridge(_bridge);
    }

    function sendCelerMessage(
        uint64 dstChainId,
        uint256 exactAmount,
        uint64 nonce
    ) external onlyOwnerOrDiamondItself {
        bridge.sendNative{value: exactAmount}(
            address(this),
            exactAmount,
            dstChainId,
            nonce,
            100000 // 10% slippage
        );
    }
}
