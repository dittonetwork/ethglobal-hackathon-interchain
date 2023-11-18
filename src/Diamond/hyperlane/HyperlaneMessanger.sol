// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BaseContract} from "../libraries/BaseContract.sol";
import {Utils} from "../libraries/Utils.sol";

interface Mailbox {
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);
}

contract HyperlaneMessanger is BaseContract {
    using Utils for address;
    using Utils for bytes32;

    Mailbox immutable mailbox;

    constructor(address _mailbox) {
        mailbox = Mailbox(_mailbox);
    }

    modifier onlyMailbox() {
        require(
            msg.sender == address(mailbox),
            "MailboxClient: sender not mailbox"
        );
        _;
    }

    function dispatch(
        uint32 destinationDomain,
        bytes calldata messageBody
    ) external onlyOwnerOrDiamondItself {
        bytes32 recipientAddress = address(this).addressToBytes32();

        uint256 fee = mailbox.quoteDispatch(
            destinationDomain,
            recipientAddress,
            messageBody
        );

        require(fee >= address(this).balance, "not enough native for fees");

        mailbox.dispatch{value: fee}(
            destinationDomain,
            recipientAddress,
            messageBody
        );
    }

    function handle(
        uint32, // origin chain id
        bytes32 _sender,
        bytes calldata message
    ) external payable onlyMailbox {
        if (_sender.bytes32ToAddress() != address(this))
            revert("sender is not valid");

        // self call
        (bool success, ) = address(this).call(message);
        require(success);
    }
}
