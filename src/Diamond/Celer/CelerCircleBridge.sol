// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {BaseContract} from "../libraries/BaseContract.sol";
import {Utils} from "../libraries/Utils.sol";

interface ICelerCircleBridge {
    function depositForBurn(
        uint256 amount,
        uint64 dstChid,
        bytes32 mintRecipient,
        address burnToken
    ) external;
}

contract CelerCircleBridge is BaseContract {
    using Utils for address;

    ICelerCircleBridge private immutable celerCircleProxy;
    IERC20 private immutable usdc;

    constructor(address _celerCircleProxy, address _usdc) {
        celerCircleProxy = ICelerCircleBridge(_celerCircleProxy);
        usdc = IERC20(_usdc);
    }

    function sendCelerCircleMessage(
        uint64 dstChainId,
        uint256 exactAmount
    ) external onlyOwnerOrDiamondItself {
        usdc.approve(address(celerCircleProxy), exactAmount);

        celerCircleProxy.depositForBurn(
            exactAmount,
            dstChainId,
            address(this).addressToBytes32(),
            address(usdc)
        );
    }
}
