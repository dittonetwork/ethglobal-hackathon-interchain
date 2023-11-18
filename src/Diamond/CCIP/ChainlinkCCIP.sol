// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {IRouterClient} from "ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {BaseContract} from "../libraries/BaseContract.sol";

contract ChainlinkCCIP is CCIPReceiver, BaseContract {
    address immutable linkAddress;

    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        bytes payload,
        address token,
        uint256 tokenAmount,
        uint256 fees
    );

    constructor(
        address _linkAddress,
        address routerClient
    ) CCIPReceiver(routerClient) {
        linkAddress = _linkAddress;
    }

    function withdrawToken(
        address beneficiary,
        address token
    ) external onlyOwnerOrDiamondItself {
        if (token == address(0)) {
            (bool success, ) = beneficiary.call{value: address(this).balance}(
                ""
            );
            require(success, "transfer failed");
        } else {
            uint256 amount = IERC20(token).balanceOf(address(this));

            if (amount == 0) revert("Nothing to withdraw");

            IERC20(token).transfer(beneficiary, amount);
        }
    }

    function ccipSend(
        uint64 dstChainSelector,
        bytes calldata payload,
        address token,
        uint256 tokenAmount,
        uint256 extraGas
    ) external onlyOwnerOrDiamondItself {
        if (token == address(0)) {
            require(tokenAmount == 0, "Token not provided");
        }

        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            payload,
            token,
            tokenAmount,
            extraGas
        );

        uint256 fees = IRouterClient(i_router).getFee(
            dstChainSelector,
            evm2AnyMessage
        );

        if (fees > IERC20(linkAddress).balanceOf(address(this)))
            revert("Not enougth link for fees");

        IERC20(linkAddress).approve(i_router, fees);

        if (token != address(0)) {
            IERC20(token).approve(i_router, tokenAmount);
        }

        bytes32 messageId = IRouterClient(i_router).ccipSend(
            dstChainSelector,
            evm2AnyMessage
        );

        emit MessageSent(
            messageId,
            dstChainSelector,
            payload,
            token,
            tokenAmount,
            fees
        );
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        address sender = abi.decode(message.sender, (address));
        if (sender != address(this)) revert("sender is not valid");

        // self call
        (bool success, ) = address(this).call(message.data);
        require(success);
    }

    struct EVMExtraArgsV1 {
        uint256 gasLimit;
        bool strict;
    }

    function _buildCCIPMessage(
        bytes calldata payload,
        address token,
        uint256 tokenAmount,
        uint256 gasLimit
    ) internal view returns (Client.EVM2AnyMessage memory) {
        Client.EVMTokenAmount[] memory tokenAmounts;

        if (token != address(0)) {
            tokenAmounts = new Client.EVMTokenAmount[](1);
            tokenAmounts[0] = Client.EVMTokenAmount({
                token: token,
                amount: tokenAmount
            });
        }

        return
            Client.EVM2AnyMessage({
                receiver: abi.encode(address(this)),
                data: payload,
                tokenAmounts: tokenAmounts,
                extraArgs: abi.encodeWithSelector(
                    Client.EVM_EXTRA_ARGS_V1_TAG,
                    EVMExtraArgsV1({gasLimit: gasLimit, strict: false})
                ),
                feeToken: linkAddress
            });
    }
}
