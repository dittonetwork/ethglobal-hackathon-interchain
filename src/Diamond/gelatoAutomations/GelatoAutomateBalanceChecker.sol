// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAutomate, ModuleData, Module, IOpsProxyFactory} from "automate/integrations/Types.sol";

import {BaseContract} from "../libraries/BaseContract.sol";

contract GelatoAutomateBalanceChecker is BaseContract {
    IAutomate internal immutable _automate;
    address private immutable _gelato;

    IOpsProxyFactory private constant OPS_PROXY_FACTORY =
        IOpsProxyFactory(0xC815dB16D4be6ddf2685C201937905aBf338F5D7);

    constructor(address automate, address gelato) {
        _automate = IAutomate(automate);
        _gelato = gelato;
    }

    struct GelatoAutomateBalanceCheckerStorage {
        bytes32 taskId;
        address[] token;
        uint256[] balanceNeeded;
    }

    bytes32 private immutable GELATO_AUTOMATIONS_STORAGE_POINTER =
        keccak256("diamond gelato");

    function _getStorage()
        internal
        view
        returns (GelatoAutomateBalanceCheckerStorage storage s)
    {
        bytes32 position = GELATO_AUTOMATIONS_STORAGE_POINTER;
        assembly ("memory-safe") {
            s.slot := position
        }
    }

    function canExecCheck() external view returns (bool, bytes memory) {
        GelatoAutomateBalanceCheckerStorage storage s = _getStorage();

        bool canExec;

        uint256 length = s.token.length;
        for (uint256 i; i < length; ) {
            canExec =
                IERC20(s.token[i]).balanceOf(address(this)) >=
                s.balanceNeeded[i];

            if (!canExec) {
                return (false, bytes(""));
            }

            unchecked {
                ++i;
            }
        }

        return (canExec, abi.encodeCall(this.runGelato, ()));
    }

    event DittoCollectedTokenAndExecutedAction();
    event GelatoTaskCancelled(bytes32 taskId);

    function runGelato() external {
        _onlyDedicatedMsgSender();

        GelatoAutomateBalanceCheckerStorage storage s = _getStorage();

        bytes32 taskId = s.taskId;

        s.taskId = bytes32(0);
        uint256 length = s.token.length;

        for (uint256 i; i < length; ) {
            s.token.pop();
            s.balanceNeeded.pop();

            unchecked {
                ++i;
            }
        }

        _automate.cancelTask(taskId);

        emit GelatoTaskCancelled(taskId);

        // Fetches the fee details from _automate during gelato automation process.
        (uint256 fee, ) = _automate.getFeeDetails();

        // feeToken is always Native currency
        // send fee to gelato
        (bool success, ) = _gelato.call{value: fee}("");
        require(success, "gelato fee transfer failed");
    }

    event GelatoTaskCreated(bytes32 taskId);

    function createTask(
        address[] calldata token,
        uint256[] calldata balanceNeeded
    ) external payable onlyOwnerOrDiamondItself returns (bytes32) {
        GelatoAutomateBalanceCheckerStorage storage s = _getStorage();

        if (s.taskId != bytes32(0)) {
            revert("task already started");
        }
        s.token = token;
        s.balanceNeeded = balanceNeeded;

        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.PROXY;

        moduleData.args[0] = _resolverModuleArg(
            address(this),
            abi.encodeWithSelector(this.canExecCheck.selector)
        );

        bytes memory execData = abi.encodeWithSelector(this.runGelato.selector);

        bytes32 taskId = _automate.createTask(
            address(this),
            execData,
            moduleData,
            0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        );

        // Set storage
        s.taskId = taskId;

        emit GelatoTaskCreated(taskId);

        return taskId;
    }

    function _onlyDedicatedMsgSender() internal view {
        (address dedicatedMsgSender, ) = OPS_PROXY_FACTORY.getProxyOf(
            address(this)
        );

        if (msg.sender != dedicatedMsgSender) {
            revert("msg sender is not dedicated");
        }
    }

    function _resolverModuleArg(
        address resolverAddress,
        bytes memory resolverData
    ) internal pure returns (bytes memory) {
        return abi.encode(resolverAddress, resolverData);
    }
}
