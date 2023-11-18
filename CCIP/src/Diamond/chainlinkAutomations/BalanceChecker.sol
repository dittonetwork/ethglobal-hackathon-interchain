// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AutomationCompatibleInterface} from "ccip/src/v0.8/automation/AutomationCompatible.sol";
import {BaseContract} from "../libraries/BaseContract.sol";

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);

    function cancelUpkeep(uint256 id) external;
}

contract BalanceChecker is AutomationCompatibleInterface, BaseContract {
    IERC20 public immutable i_link;
    AutomationRegistrarInterface public immutable i_registrar;
    AutomationRegistrarInterface public immutable automationRegistrar2_1;

    constructor(
        address _i_link,
        address _i_registrar,
        address _automationRegistrar2_1
    ) {
        i_link = IERC20(_i_link);
        i_registrar = AutomationRegistrarInterface(_i_registrar);
        automationRegistrar2_1 = AutomationRegistrarInterface(
            _automationRegistrar2_1
        );
    }

    struct BalanceCheckerStorage {
        uint256 balanceNeeded;
        address token;
        uint256 upkeepID;
    }

    bytes32 immutable storagePointer =
        keccak256("balance checker storage pointer");

    function _getLocalStorage()
        internal
        view
        returns (BalanceCheckerStorage storage s)
    {
        bytes32 POINTER = storagePointer;
        assembly ("memory-safe") {
            s.slot := POINTER
        }
    }

    function initizlize(
        uint256 balanceNeeded,
        address token,
        uint96 linkAmountForAutomations
    ) external onlyOwnerOrDiamondItself {
        BalanceCheckerStorage storage s = _getLocalStorage();

        s.balanceNeeded = balanceNeeded;
        s.token = token;

        IERC20(i_link).approve(
            address(automationRegistrar2_1),
            linkAmountForAutomations
        );

        RegistrationParams memory params = RegistrationParams({
            name: "balance checker",
            encryptedEmail: bytes(""),
            upkeepContract: address(this),
            gasLimit: 250_000,
            adminAddress: address(this),
            triggerType: 0,
            checkData: abi.encodeCall(this.checkUpkeep, (bytes(""))),
            triggerConfig: bytes(""),
            offchainConfig: bytes(""),
            amount: linkAmountForAutomations
        });

        uint256 upkeepID = automationRegistrar2_1.registerUpkeep(params);
        if (upkeepID != 0) {
            s.upkeepID = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        BalanceCheckerStorage storage s = _getLocalStorage();

        upkeepNeeded =
            IERC20(s.token).balanceOf(address(this)) >= s.balanceNeeded;

        return (upkeepNeeded, "");
    }

    event DittoCollectedTokenAndExecutedAction();

    function performUpkeep(bytes calldata /* performData */) external override {
        BalanceCheckerStorage storage s = _getLocalStorage();
        if (IERC20(s.token).balanceOf(address(this)) >= s.balanceNeeded) {
            i_registrar.cancelUpkeep(s.upkeepID);

            emit DittoCollectedTokenAndExecutedAction();
        }
    }

    function getCheckerStorage()
        external
        view
        returns (BalanceCheckerStorage memory s)
    {
        s = _getLocalStorage();
    }
}
