// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {ChainlinkCCIP} from "../../src/Diamond/CCIP/ChainlinkCCIP.sol";
import {BalanceChecker} from "../../src/Diamond/chainlinkAutomations/BalanceChecker.sol";

import "forge-std/Script.sol";

contract CCIPTest is Script {
    address diamond = 0x6D4d585fd7172Ab7B8BC2c5B981e51785f16d653;

    address routerAvax = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;

    address avaxBnM = 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;
    address opBnM = 0xaBfE9D11A2f1D61990D1d253EC98B5Da00304F16;
    address mumbaiBnM = 0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40;

    uint64 fujiChainSelector = 14767482510784806043;
    uint64 mumbaiChainSelector = 12532609583862916517;
    uint64 opChainSelector = 2664363617261496610;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        bytes memory ccipCallbackBase = abi.encodeCall(
            ChainlinkCCIP.ccipSend,
            (fujiChainSelector, bytes(""), mumbaiBnM, 1e18, 500_000)
        );
        bytes memory ccipCallbackOp = abi.encodeCall(
            ChainlinkCCIP.ccipSend,
            (fujiChainSelector, bytes(""), opBnM, 1e18, 500_000)
        );

        bytes[] memory data = new bytes[](3);

        data[0] = abi.encodeCall(
            ChainlinkCCIP.ccipSend,
            (mumbaiChainSelector, ccipCallbackBase, address(0), 0, 500_000)
        );
        data[1] = abi.encodeCall(
            ChainlinkCCIP.ccipSend,
            (opChainSelector, ccipCallbackOp, address(0), 0, 500_000)
        );
        data[2] = abi.encodeCall(
            BalanceChecker.initizlize,
            (3e18, avaxBnM, 1e18)
        );

        vm.startBroadcast(pk);
        MulticallFacet(diamond).multicall(data);
    }
}
