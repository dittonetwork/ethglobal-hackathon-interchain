// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Diamond} from "../../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../../src/Diamond/facets/DiamondCutFacet.sol";
import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {OwnershipFacet} from "../../src/Diamond/facets/OwnershipFacet.sol";
import {ChainlinkCCIP} from "../../src/Diamond/CCIP/ChainlinkCCIP.sol";
import {CCIPReceiver} from "ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {BalanceChecker} from "../../src/Diamond/chainlinkAutomations/BalanceChecker.sol";

import {IDiamondCut} from "../../src/Diamond/interfaces/IDiamondCut.sol";

import "forge-std/Script.sol";

contract CCIPTest is Script {
    address routerAvax = 0x554472a2720E5E7D5D3C817529aBA05EEd5F82D8;

    address linkAvax = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address registrarAvax = 0x819B58A646CDd8289275A87653a2aA4902b14fe6;
    address registratAvax2_1 = 0xD23D3D1b81711D75E1012211f1b65Cc7dBB474e2;

    address avaxBnM = 0xD21341536c5cF5EB1bcb58f6723cE26e8D8E90e4;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        Diamond diamond = new Diamond(vm.addr(pk), address(diamondCutFacet));

        MulticallFacet multicallFacet = new MulticallFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ChainlinkCCIP chainlinkCCIP = new ChainlinkCCIP(linkAvax, routerAvax);
        BalanceChecker balanceChecker = new BalanceChecker(
            linkAvax,
            registrarAvax,
            registratAvax2_1
        );

        IDiamondCut.FacetCut[] memory facetCut = new IDiamondCut.FacetCut[](4);
        facetCut[0].facetAddress = address(multicallFacet);
        facetCut[0].action = IDiamondCut.FacetCutAction.Add;
        facetCut[0].functionSelectors = new bytes4[](1);
        facetCut[0].functionSelectors[0] = MulticallFacet.multicall.selector;

        facetCut[1].facetAddress = address(ownershipFacet);
        facetCut[1].action = IDiamondCut.FacetCutAction.Add;
        facetCut[1].functionSelectors = new bytes4[](2);
        facetCut[1].functionSelectors[0] = OwnershipFacet
            .transferOwnership
            .selector;
        facetCut[1].functionSelectors[1] = OwnershipFacet.owner.selector;

        facetCut[2].facetAddress = address(chainlinkCCIP);
        facetCut[2].action = IDiamondCut.FacetCutAction.Add;
        facetCut[2].functionSelectors = new bytes4[](3);
        facetCut[2].functionSelectors[0] = CCIPReceiver.ccipReceive.selector;
        facetCut[2].functionSelectors[1] = ChainlinkCCIP.ccipSend.selector;
        facetCut[2].functionSelectors[2] = CCIPReceiver
            .supportsInterface
            .selector;

        facetCut[3].facetAddress = address(balanceChecker);
        facetCut[3].action = IDiamondCut.FacetCutAction.Add;
        facetCut[3].functionSelectors = new bytes4[](4);
        facetCut[3].functionSelectors[0] = BalanceChecker.initizlize.selector;
        facetCut[3].functionSelectors[1] = BalanceChecker.checkUpkeep.selector;
        facetCut[3].functionSelectors[2] = BalanceChecker
            .performUpkeep
            .selector;
        facetCut[3].functionSelectors[3] = BalanceChecker
            .getCheckerStorage
            .selector;

        IDiamondCut(address(diamond)).diamondCut(
            facetCut,
            address(0),
            bytes("")
        );

        (bool success, ) = avaxBnM.call(
            abi.encodeWithSignature("drip(address)", address(diamond))
        );
        require(success);
    }
}
