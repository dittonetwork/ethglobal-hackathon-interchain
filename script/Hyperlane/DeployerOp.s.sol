// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Diamond} from "../../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../../src/Diamond/facets/DiamondCutFacet.sol";
import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {OwnershipFacet} from "../../src/Diamond/facets/OwnershipFacet.sol";
import {HyperlaneMessanger} from "../../src/Diamond/hyperlane/HyperlaneMessanger.sol";
import {CelerCircleBridgeLogic} from "../../src/Diamond/Celer/CelerCircleBridge.sol";

import {IDiamondCut} from "../../src/Diamond/interfaces/IDiamondCut.sol";

import "forge-std/Script.sol";

contract HyperlaneTest is Script {
    address opMailbox = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D;

    address celerCCTP = 0x697aC93c9263346c5Ad0412F9356D5789a3AA687;
    address opUSDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;

    address opGelato = 0x01051113D81D7d6DA508462F2ad6d7fD96cF42Ef;
    address opGelatoAutomate = 0x340759c8346A1E6Ed92035FB8B6ec57cE1D82c2c;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        Diamond diamond = new Diamond(vm.addr(pk), address(diamondCutFacet));

        MulticallFacet multicallFacet = new MulticallFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        HyperlaneMessanger hyperlaneMessanger = new HyperlaneMessanger(
            opMailbox
        );
        CelerCircleBridgeLogic celer = new CelerCircleBridgeLogic(
            celerCCTP,
            opUSDC
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

        IDiamondCut(address(diamond)).diamondCut(
            facetCut,
            address(0),
            bytes("")
        );
    }
}
