// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Diamond} from "../../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../../src/Diamond/facets/DiamondCutFacet.sol";
import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {OwnershipFacet} from "../../src/Diamond/facets/OwnershipFacet.sol";
import {HyperlaneMessanger} from "../../src/Diamond/hyperlane/HyperlaneMessanger.sol";
import {CelerCircleBridgeLogic} from "../../src/Diamond/Celer/CelerCircleBridge.sol";
import {GelatoAutomateBalanceChecker} from "../../src/Diamond/gelatoAutomations/GelatoAutomateBalanceChecker.sol";

import {IDiamondCut} from "../../src/Diamond/interfaces/IDiamondCut.sol";

import "forge-std/Script.sol";

contract HyperlaneTest is Script {
    address avaxMailbox = 0xFf06aFcaABaDDd1fb08371f9ccA15D73D51FeBD6;

    address celerCCTP = 0x9744ae566c64B6B6f7F9A4dD50f7496Df6Fef990;
    address avaxUSDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    address avaxGelato = 0x7C5c4Af1618220C090A6863175de47afb20fa9Df;
    address avaxGelatoAutomate = 0x8aB6aDbC1fec4F18617C9B889F5cE7F28401B8dB;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        Diamond diamond = new Diamond(vm.addr(pk), address(diamondCutFacet));

        MulticallFacet multicallFacet = new MulticallFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        HyperlaneMessanger hyperlaneMessanger = new HyperlaneMessanger(
            avaxMailbox
        );
        CelerCircleBridgeLogic celer = new CelerCircleBridgeLogic(
            celerCCTP,
            avaxUSDC
        );
        GelatoAutomateBalanceChecker gelatoAutomateBalanceChecker = new GelatoAutomateBalanceChecker(
                avaxGelatoAutomate,
                avaxGelato
            );

        IDiamondCut.FacetCut[] memory facetCut = new IDiamondCut.FacetCut[](5);
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

        facetCut[2].facetAddress = address(celer);
        facetCut[2].action = IDiamondCut.FacetCutAction.Add;
        facetCut[2].functionSelectors = new bytes4[](1);
        facetCut[2].functionSelectors[0] = CelerCircleBridgeLogic
            .sendCelerCircleMessage
            .selector;

        facetCut[3].facetAddress = address(hyperlaneMessanger);
        facetCut[3].action = IDiamondCut.FacetCutAction.Add;
        facetCut[3].functionSelectors = new bytes4[](2);
        facetCut[3].functionSelectors[0] = HyperlaneMessanger.dispatch.selector;
        facetCut[3].functionSelectors[1] = HyperlaneMessanger.handle.selector;

        facetCut[4].facetAddress = address(gelatoAutomateBalanceChecker);
        facetCut[4].action = IDiamondCut.FacetCutAction.Add;
        facetCut[4].functionSelectors = new bytes4[](3);
        facetCut[4].functionSelectors[0] = GelatoAutomateBalanceChecker
            .canExecCheck
            .selector;
        facetCut[4].functionSelectors[1] = GelatoAutomateBalanceChecker
            .runGelato
            .selector;
        facetCut[4].functionSelectors[2] = GelatoAutomateBalanceChecker
            .createTask
            .selector;

        IDiamondCut(address(diamond)).diamondCut(
            facetCut,
            address(0),
            bytes("")
        );
    }
}
