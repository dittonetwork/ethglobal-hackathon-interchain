// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {CelerBridge} from "../../src/Diamond/Celer/CelerBridge.sol";
import {CelerCircleBridge} from "../../src/Diamond/Celer/CelerCircleBridge.sol";
import {GelatoAutomateBalanceChecker} from "../../src/Diamond/gelatoAutomations/GelatoAutomateBalanceChecker.sol";
import {HyperlaneMessanger} from "../../src/Diamond/hyperlane/HyperlaneMessanger.sol";

import "forge-std/Script.sol";

contract HyperlaneTest is Script {
    address diamond = 0xF25907327E9E4144291D43024b720Bc32055cda0;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        bytes[] memory data = new bytes[](3);

        bytes memory opCallback = abi.encodeCall(
            CelerCircleBridge.sendCelerCircleMessage,
            (43114, 3000000)
        );

        bytes memory zkEVMCallback = abi.encodeCall(
            CelerBridge.sendCelerMessage,
            (43114, 0.0051e18, 1)
        );

        data[0] = abi.encodeCall(HyperlaneMessanger.dispatch, (10, opCallback));
        data[1] = abi.encodeCall(
            HyperlaneMessanger.dispatch,
            (1101, zkEVMCallback)
        );

        address[] memory tokens = new address[](2);
        tokens[0] = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E; // usdc avax
        tokens[1] = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB; // weth.e
        uint256[] memory balanceNeeded = new uint256[](2);
        balanceNeeded[0] = 2700000;
        balanceNeeded[1] = 0.0035e18; // fee and slippage

        data[2] = abi.encodeCall(
            GelatoAutomateBalanceChecker.createTask,
            (tokens, balanceNeeded)
        );

        vm.startBroadcast(pk);
        MulticallFacet(diamond).multicall{value: 0.15e18}(data);
    }
}
