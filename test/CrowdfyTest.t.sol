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
            "Cancer Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 5 minutes,
            1 ether
        );
        vm.stopPrank();
        _;
    }

    function setUp() public {
        crowdfyDeploy = new CrowdfyDeploy();
        crowdfy = crowdfyDeploy.run();
    }

    function testSuccessfullyGetCampaigns() public createCampaign {
        uint256 expectedCampaignTotal = 1;
        uint256 actualCampaignTotal = crowdfy.getCampaigns().length;
        assertEq(expectedCampaignTotal, actualCampaignTotal);
    }

    function testSuccessfullyParticipateInCampaign()
        public
        payable
        createCampaign
    {
        vm.startPrank(BOB);
        vm.deal(BOB, 2 ether);
        crowdfy.checkAndChangeCampaignStatus();
        crowdfy.participateCampaign{value: SEND_ETH}(0);
        vm.stopPrank();
        uint256 expectedCampaignParticipant = 1;
        uint256 actualCampaignParticipant = crowdfy.getParticipant(0).length;
        uint256 expectedSenderBalance = 1.9 ether;
        uint256 actualSenderBalance = address(BOB).balance;
        uint256 expectedRecipientBalance = 2.1 ether;
        uint256 actualRecipientBalance = address(ALICE).balance;
        assertEq(expectedCampaignParticipant, actualCampaignParticipant);
        assertEq(expectedSenderBalance, actualSenderBalance);
        assertEq(expectedRecipientBalance, actualRecipientBalance);
    }

    function testSuccessfullyRevertIfCampaignIsClosed() public {
        crowdfy.createCampaign(
            "Smoke Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp + 1 minutes,
            block.timestamp + 6 minutes,
            1 ether
        );
        vm.expectRevert(
            abi.encodeWithSelector(Crowdfy.CampaignIsClosed.selector, 0)
        );
        crowdfy.participateCampaign(0);
    }

    function testSuccessfullyRevertIfInvalidTime() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Crowdfy.InvalidTime.selector,
                (block.timestamp + 2 minutes),
                (block.timestamp + 1 minutes)
            )
        );
        crowdfy.createCampaign(
            "Poverty Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp + 2 minutes,
            block.timestamp + 1 minutes,
            1 ether
        );
    }

    function testSuccessfullyRevertIfAmountNotGreaterThanZero() public {
        crowdfy.createCampaign(
            "Animal Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 1 minutes,
            1 ether
        );
        crowdfy.checkAndChangeCampaignStatus();
        uint256 invalidSendAmount = 0 ether;
        vm.expectRevert(
            abi.encodeWithSelector(
                Crowdfy.AmountMustBeGreaterThanZero.selector,
                invalidSendAmount
            )
        );
        crowdfy.participateCampaign{value: invalidSendAmount}(0);
    }

    function testSuccessfullyRevertIfInsufficientBalance() public {
        crowdfy.createCampaign(
            "Business Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 1 minutes,
            1 ether
        );
        crowdfy.checkAndChangeCampaignStatus();
        vm.deal(BOB, 0.1 ether);
        vm.startPrank(BOB);
        vm.expectRevert(Crowdfy.InsufficientBalance.selector);
        crowdfy.participateCampaign{value: SEND_ETH}(0);
        vm.stopPrank();
    }

    function testSuccessfullyRevertIfCampaignNotFound() public {
        crowdfy.createCampaign(
            "Vegan Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 1 minutes,
            1 ether
        );
        crowdfy.checkAndChangeCampaignStatus();
        vm.expectRevert(
            abi.encodeWithSelector(Crowdfy.CampaignNotFound.selector, 1)
        );
        crowdfy.participateCampaign{value: SEND_ETH}(1);
    }

    function testSuccessfullyRevertIfTransferFailed() public {
        crowdfy.createCampaign(
            "Business Campaign",
            "Lorem ipsum dolor sit amet",
            block.timestamp,
            block.timestamp + 1 minutes,
            1 ether
        );
        crowdfy.checkAndChangeCampaignStatus();
        vm.startPrank(BOB);
        vm.deal(BOB, 1 ether);
        vm.expectRevert(
            abi.encodeWithSelector(Crowdfy.TransferFailed.selector, 0, SEND_ETH)
        );
        crowdfy.participateCampaign{value: SEND_ETH}(0);
        vm.stopPrank();
    }

    function testSuccessfullyRevertIfEmptyFieldExist() public {
        vm.expectRevert(Crowdfy.EmptyFieldExist.selector);
        crowdfy.createCampaign(
            "",
            "Lorem ipsum dolor sit amet",
            0,
            1,
            1 ether
        );
    }

    //
}
