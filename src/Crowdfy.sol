// SPDX-License-Indetifier : MIT

pragma solidity ^0.8.23;

import {console} from "forge-std/console.sol";

contract Crowdfy {
    //
    enum CampaignStatus {
        OPEN,
        CLOSED
    }

    struct Campaign {
        uint256 id;
        string campaignTitle;
        string campaignDescription;
        uint256 campaignStart;
        uint256 campaignEnd;
        address campaignCreator;
        uint256 fundsRequired;
        uint256 currentRaised;
        CampaignStatus status;
    }
    struct Participant {
        uint256 id;
        address user;
        uint256 donationAmount;
        uint256 timestamp;
    }

    Campaign[] private campaigns;

    mapping(uint256 => Participant[]) private campaignParticipants;

    event NewCampaignHasBeenCreated(
        uint256 indexed campaignId
    );
    event CampaignStatusChanged(
        uint256 indexed campaignId,
        CampaignStatus indexed status
    );
    event DonationReceived(
        uint256 indexed campaignId,
        address indexed participant
    );
    event FallbackCalled(
        address indexed sender,
        uint256 indexed amount,
        bytes indexed data
    );
    event ReceiveCalled(
        address indexed sender, 
        uint256 indexed amount
    );

    error CampaignIsClosed(uint256 campaignId); // done test
    error EmptyFieldExist(); // done test
    error InvalidTime(uint256 campaignStart, uint256 campaignEnd); // done test
    error AmountMustBeGreaterThanZero(uint256 amount); // done test
    error InsufficientBalance(); // done test
    error CampaignNotFound(uint256 searchId); // done test
    error TransferFailed(uint256 campaignId, uint256 amount); // done test

    modifier checkTime(uint256 _campaignStart, uint256 _campaignEnd) {
        if (
            _campaignStart < block.timestamp ||
            _campaignEnd < block.timestamp ||
            _campaignStart > _campaignEnd
        ) {
            revert InvalidTime(_campaignStart, _campaignEnd);
        }
        _;
    }

    modifier checkStatus(uint256 _campaignId) {
        if (campaigns[_campaignId].status == CampaignStatus.CLOSED) {
            revert CampaignIsClosed(_campaignId);
        }
        _;
    }

    modifier checkCampaign(uint256 _campaignId) {
        uint256 campaignTotal = campaigns.length;
        bool isFound = false;
        for (uint256 i = 0; i < campaignTotal; i++) {
            if (i == _campaignId) {
                isFound = true;
                break;
            }
        }
        if (!isFound) {
            revert CampaignNotFound(_campaignId);
        }
        _;
    }

    modifier checkUserBalance(uint256 _userBalance, uint256 _amount) {
        if (_userBalance < _amount) {
            revert InsufficientBalance();
        }
        _;
    }

    modifier checkFunds(uint256 _value) {
        if (_value == 0) {
            revert AmountMustBeGreaterThanZero(_value);
        }
        _;
    }

    modifier checkEmptyField(
        string memory _campaignTitle,
        string memory _campaignDescription,
        uint256 _campaignStart,
        uint256 _campaignEnd,
        uint256 _fundsRequired
    ) {
        if (
            bytes(_campaignTitle).length == 0 ||
            bytes(_campaignDescription).length == 0 ||
            _campaignStart == 0 ||
            _campaignEnd == 0 ||
            _fundsRequired == 0
        ) {
            revert EmptyFieldExist();
        }
        _;
    }

    // done test
    function createCampaign(
        string memory _campaignTitle,
        string memory _campaignDescription,
        uint256 _campaignStart,
        uint256 _campaignEnd,
        uint256 _fundsRequired
    )
        external
        checkEmptyField(
            _campaignTitle,
            _campaignDescription,
            _campaignStart,
            _campaignEnd,
            _fundsRequired
        )
        checkTime(_campaignStart, _campaignEnd)
    {
        campaigns.push(
            Campaign({
                id: campaigns.length,
                campaignTitle: _campaignTitle,
                campaignDescription: _campaignDescription,
                campaignStart: _campaignStart,
                campaignEnd: _campaignEnd,
                campaignCreator: msg.sender,
                fundsRequired: _fundsRequired,
                currentRaised: 0 ether,
                status: CampaignStatus.CLOSED
            })
        );
        checkAndChangeCampaignStatus();
        emit NewCampaignHasBeenCreated(campaigns.length - 1);
    }

    // done test
    function checkAndChangeCampaignStatus() public {
        uint256 campaignTotal = campaigns.length;
        for (uint256 i = 0; i < campaignTotal; i++) {
            CampaignStatus currentStatus = campaigns[i].status;

            if (
                block.timestamp >= campaigns[i].campaignStart &&
                campaigns[i].status == CampaignStatus.CLOSED &&
                block.timestamp < campaigns[i].campaignEnd
            ) {
                currentStatus = CampaignStatus.OPEN;
            } else if (
                block.timestamp >= campaigns[i].campaignEnd &&
                campaigns[i].status == CampaignStatus.OPEN
            ) {
                currentStatus = CampaignStatus.CLOSED;
            }

            if (campaigns[i].status != currentStatus) {
                campaigns[i].status = currentStatus;
                emit CampaignStatusChanged(i, currentStatus);
            }
        }
    }

    // done test
    function participateCampaign(
        uint256 _campaignId
    )
        external
        payable
        checkCampaign(_campaignId)
        checkStatus(_campaignId)
        checkUserBalance(address(msg.sender).balance, msg.value)
        checkFunds(msg.value)
    {
        address payable recipient = payable(
            campaigns[_campaignId].campaignCreator
        );
        bool success = recipient.send(msg.value);
        if (success) {
            campaigns[_campaignId].currentRaised += msg.value;
            _addParticipantToMapping(_campaignId, msg.sender, msg.value);
            emit DonationReceived(_campaignId, recipient);
        } else {
            revert TransferFailed(_campaignId, msg.value);
        }
    }

    // done test
    function _addParticipantToMapping(
        uint256 _campaignId,
        address _sender,
        uint256 _amount
    ) private {
        campaignParticipants[_campaignId].push(
            Participant({
                id: campaignParticipants[_campaignId].length,
                user: _sender,
                donationAmount: _amount,
                timestamp: block.timestamp
            })
        );
    }

    // done test
    function getCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    // done test
    function getParticipant(
        uint256 _campaignId
    ) external view returns (Participant[] memory) {
        Participant[] memory participants = campaignParticipants[_campaignId];
        return participants;
    }

    receive() external payable {
        emit ReceiveCalled(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.value, msg.data);
    }
    //
}
