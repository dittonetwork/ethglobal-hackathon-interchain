// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Diamond} from "../../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../../src/Diamond/facets/DiamondCutFacet.sol";
import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {OwnershipFacet} from "../../src/Diamond/facets/OwnershipFacet.sol";
import {HyperlaneMessanger} from "../../src/Diamond/hyperlane/HyperlaneMessanger.sol";
import {CelerBridge} from "../../src/Diamond/Celer/CelerBridge.sol";

import {IDiamondCut} from "../../src/Diamond/interfaces/IDiamondCut.sol";

import "forge-std/Script.sol";

contract HyperlaneTest is Script {
    address zkEVMMailbox = 0x3a464f746D23Ab22155710f44dB16dcA53e0775E;
    address zkEVMBridge = 0xD46F8E428A06789B5884df54E029e738277388D1;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        Diamond diamond = new Diamond(vm.addr(pk), address(diamondCutFacet));

        MulticallFacet multicallFacet = new MulticallFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        HyperlaneMessanger hyperlaneMessanger = new HyperlaneMessanger(
            zkEVMMailbox
        );
        CelerBridge celerBridge = new CelerBridge(zkEVMBridge);

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

        facetCut[2].facetAddress = address(hyperlaneMessanger);
        facetCut[2].action = IDiamondCut.FacetCutAction.Add;
        facetCut[2].functionSelectors = new bytes4[](3);
        facetCut[2].functionSelectors[0] = HyperlaneMessanger.dispatch.selector;
        facetCut[2].functionSelectors[1] = HyperlaneMessanger.handle.selector;
        facetCut[2].functionSelectors[2] = HyperlaneMessanger
            .interchainSecurityModule
            .selector;

        facetCut[3].facetAddress = address(celerBridge);
        facetCut[3].action = IDiamondCut.FacetCutAction.Add;
        facetCut[3].functionSelectors = new bytes4[](1);
        facetCut[3].functionSelectors[0] = CelerBridge
            .sendCelerMessage
            .selector;

        IDiamondCut(address(diamond)).diamondCut(
            facetCut,
            address(0),
            bytes("")
        );
    }
}
