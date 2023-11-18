// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Diamond} from "../../src/Diamond/Diamond.sol";
import {DiamondCutFacet} from "../../src/Diamond/facets/DiamondCutFacet.sol";
import {MulticallFacet} from "../../src/Diamond/facets/MulticallFacet.sol";
import {OwnershipFacet} from "../../src/Diamond/facets/OwnershipFacet.sol";
import {ChainlinkCCIP} from "../../src/Diamond/CCIP/ChainlinkCCIP.sol";
import {CCIPReceiver} from "ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import {IDiamondCut} from "../../src/Diamond/interfaces/IDiamondCut.sol";

import "forge-std/Script.sol";

contract CCIPTest is Script {
    address routerMumbai = 0x70499c328e1E2a3c41108bd3730F6670a44595D1;

    address mumbaiLinkLink = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address mumbaiBnM = 0xf1E3A5842EeEF51F2967b3F05D45DD4f4205FF40;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();

        Diamond diamond = new Diamond(vm.addr(pk), address(diamondCutFacet));

        MulticallFacet multicallFacet = new MulticallFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        ChainlinkCCIP chainlinkCCIP = new ChainlinkCCIP(
            mumbaiLinkLink,
            routerMumbai
        );

        IDiamondCut.FacetCut[] memory facetCut = new IDiamondCut.FacetCut[](3);
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

        IDiamondCut(address(diamond)).diamondCut(
            facetCut,
            address(0),
            bytes("")
        );

        (bool success, ) = mumbaiBnM.call(
            abi.encodeWithSignature("drip(address)", address(diamond))
        );
        require(success);
    }
}
