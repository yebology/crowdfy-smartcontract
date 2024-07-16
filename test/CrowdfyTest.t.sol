// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Crowdfy} from "../src/Crowdfy.sol";
import {CrowdfyDeploy} from "../script/CrowdfyDeploy.s.sol";

contract CrowdfyTest is Test {
    //
    CrowdfyDeploy crowdfyDeploy;
    Crowdfy crowdfy;

    uint256 private constant SEND_ETH = 0.1 ether; 
    address private constant BOB = address(1);
    address private constant ALICE = address(2);

    modifier createCampaign() {
        vm.startPrank(ALICE);
        vm.deal(ALICE, 2 ether);
        crowdfy.createCampaign(
            "Cancer Donation",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 5 minutes,
            1 ether,
            0 ether
        );
        vm.stopPrank();
        _;
    }

    function setUp() public {
        crowdfyDeploy = new CrowdfyDeploy();
        crowdfy = crowdfyDeploy.run();
    }

    function testSuccessfullyGetCampaigns() public createCampaign() {
        uint256 expectedCampaignTotal = 1;
        uint256 actualCampaignTotal = crowdfy.getCampaigns().length;
        assertEq(expectedCampaignTotal, actualCampaignTotal);
    }

    function testSuccessfullyParticipateInCampaign() public createCampaign() {
        uint256 expectedCampaignParticipant = 1;
        vm.startPrank(BOB);
        vm.deal(BOB, 2 ether);
        crowdfy.checkAndChangeCampaignStatus();
        crowdfy.participateCampaign{
            value: SEND_ETH
        }(0);
        vm.stopPrank();
        uint256 actualCampaignParticipant = crowdfy.getParticipant(0).length;
        assertEq(expectedCampaignParticipant, actualCampaignParticipant);
    }
    //
}
