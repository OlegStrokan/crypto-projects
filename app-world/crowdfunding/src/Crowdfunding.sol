// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CrowdFundEasy {
    ERC20 public token;

    struct Campaign {
        uint256 goal;
        uint256 totalFunds;
        uint256 endTime;
        address creator;
        bool isActive;
    }

    mapping(uint256 => Campaign) campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;

    uint256 public nextCampaignId;

    //---------------------------custom erros--------------------------//

    error CampaignAmountZero();
    error CampaignShortDuration();
    error CampaignNotActive();
    error CampaignEnded();
    error InvalidContributionAmount();
    error CampaignNotFound();
    error NotCampaignCreator();
    error CampaignNotEnded();
    error GoalNotReached();
    error NoContributionToCancel();
    error TransferFailed();
    error NoContributionToRefund();

    //-----------------------------events-----------------------------//

    event CampaignCreated(
        uint256 id,
        address creator,
        uint256 goal,
        uint256 duration
    );
    event ContributionMade(
        uint256 campaignId,
        address contributor,
        uint256 amount
    );
    event ContributionCancelled(
        uint256 campaignId,
        address contributor,
        uint256 amount
    );
    event FundsWithdrawn(uint256 campaignId, address creator, uint256 amount);
    event RefundIssued(uint256 campaignId, address donor, uint256 amount);

    /**
     * @param _token list of allowed token addresses
     */
    constructor(address _token) {
        token = ERC20(_token);
    }
    /**
     * @notice createCampaign allows anyone to create a campaign
     * @param _goal amount of funds to be raised in USD
     * @param _duration the duration of the campaign in seconds
     */
    function createCampaign(uint256 _goal, uint256 _duration) external {
        if (_goal <= 0) revert CampaignAmountZero();
        if (_duration <= 0) revert CampaignShortDuration();

        uint256 _endTime = block.timestamp + _duration;
        campaigns[nextCampaignId] = Campaign({
            creator: msg.sender,
            goal: _goal,
            endTime: _endTime,
            totalFunds: 0,
            isActive: true
        });

        emit CampaignCreated(nextCampaignId, msg.sender, _goal, _duration);
        nextCampaignId++;
    }

    /**
     * @dev contribute allows anyone to contribute to a campaign
     * @param _id the id of the campaign
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, uint256 _amount) external {
        if (_amount <= 0) revert InvalidContributionAmount();

        Campaign storage campaign = campaigns[_id];
        if (!campaign.isActive) revert CampaignNotActive();
        if (block.timestamp >= campaign.endTime) revert CampaignEnded();
        if (_amount == 0) revert InvalidContributionAmount();

        if (!token.transferFrom(msg.sender, address(this), _amount))
            revert TransferFailed();
        campaign.totalFunds += _amount;
        contributions[_id][msg.sender] += _amount;

        emit ContributionMade(_id, msg.sender, _amount);
    }

    /**
     * @dev cancelContribution allows anyone to cancel their contribution
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        if (!campaign.isActive) revert CampaignNotActive();
        if (block.timestamp >= campaign.endTime) revert CampaignEnded();
        uint256 contribution = contributions[_id][msg.sender];
        if (contribution == 0) revert NoContributionToCancel();

        campaign.totalFunds -= contribution;
        contributions[_id][msg.sender] = 0;

        if (!token.transfer(msg.sender, contribution)) revert TransferFailed();

        emit ContributionCancelled(_id, msg.sender, contribution);
    }

    /**
     * @notice withdrawFunds allows the creator of the campaign to withdraw the funds
     * @param _id the id of the campaign
     */

    function withdrawFunds(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        if (campaign.creator != msg.sender) revert NotCampaignCreator();
        if (block.timestamp < campaign.endTime) revert CampaignNotEnded();
        if (campaign.totalFunds < campaign.goal) revert GoalNotReached();

        uint256 amount = campaign.totalFunds;
        campaign.totalFunds = 0;
        campaign.isActive = false;

        if (!token.transfer(msg.sender, amount)) revert TransferFailed();

        emit FundsWithdrawn(_id, msg.sender, amount);
    }

    /**
     * @notice refund allows the contributors to get a refund if the campaign failed
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        if (block.timestamp < campaign.endTime) revert CampaignNotEnded();
        if (campaign.totalFunds >= campaign.goal) revert GoalNotReached();
        uint256 contribution = contributions[_id][msg.sender];
        if (contribution == 0) revert NoContributionToRefund();

        contributions[_id][msg.sender] = 0;

        if (!token.transfer(msg.sender, contribution)) revert TransferFailed();

        emit RefundIssued(_id, msg.sender, contribution);
    }

    /**
     * @notice getContribution returns the contribution of a contributor in USD
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(
        uint256 _id,
        address _contributor
    ) public view returns (uint256) {
        return contributions[_id][_contributor];
    }

    /**
     * @notice getCampaign returns details about a campaign
     * @param _id the id of the campaign
     * @return remainingTime the time (in seconds) when the campaign ends
     * @return goal the goal of the campaign (in USD)
     * @return totalFunds total funds (in USD) raised by the campaign
     */
    function getCampaign(
        uint256 _id
    )
        external
        view
        returns (uint256 remainingTime, uint256 goal, uint256 totalFunds)
    {
        Campaign memory campaign = campaigns[_id];
        if (block.timestamp >= campaign.endTime) {
            remainingTime = 0;
        } else {
            remainingTime = campaign.endTime - block.timestamp;
        }
        goal = campaign.goal;
        totalFunds = campaign.totalFunds;
    }
}
