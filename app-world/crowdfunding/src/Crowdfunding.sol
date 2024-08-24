// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Crowdfunding is Ownable {
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

    //---------------------------custom errors--------------------------//

    error CampaignAmountZero();
    error CampaignShortDuration();
    error CampaignNotActive();
    error CreatorCannotContribute();
    error CampaignEnded();
    error InvalidContributionAmount();
    error CampaignNotFound();
    error NotCampaignCreator();
    error CampaignNotEnded();
    error GoalNotReached();
    error GoalReached();
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
     * @notice Constructor initializes the Crowdfunding contract with a token and owner.
     * @param _token The address of the ERC20 token used for contributions.
     * @param _owner The address of the contract owner.
     */
    constructor(address _token, address _owner) Ownable(_owner) {
        token = ERC20(_token);
    }

    /**
     * @notice Allows anyone to create a new crowdfunding campaign.
     * @param _goal The amount of funds to be raised (in tokens).
     * @param _duration The duration of the campaign in seconds.
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
     * @notice Allows anyone to contribute to an active campaign.
     * @param _id The ID of the campaign.
     * @param _amount The amount of tokens to contribute.
     */
    function contribute(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        if (!campaign.isActive) revert CampaignNotActive();
        if (block.timestamp >= campaign.endTime) revert CampaignEnded();
        if (_amount == 0) revert InvalidContributionAmount();
        if (msg.sender == campaign.creator) revert CreatorCannotContribute();

        if (!token.transferFrom(msg.sender, address(this), _amount))
            revert TransferFailed();
        campaign.totalFunds += _amount;
        contributions[_id][msg.sender] += _amount;

        emit ContributionMade(_id, msg.sender, _amount);
    }

    /**
     * @notice Allows contributors to cancel their contribution before the campaign ends.
     * @param _id The ID of the campaign.
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
     * @notice Allows the campaign creator to withdraw funds if the goal is reached and the campaign has ended.
     * @param _id The ID of the campaign.
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
     * @notice Allows contributors to receive a refund if the campaign fails to reach its goal.
     * @param _id The ID of the campaign.
     */
    function refund(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];
        if (block.timestamp < campaign.endTime) revert CampaignNotEnded();
        if (campaign.totalFunds == campaign.goal) revert GoalReached();
        uint256 contribution = contributions[_id][msg.sender];
        if (contribution == 0) revert NoContributionToRefund();

        contributions[_id][msg.sender] = 0;
        campaign.totalFunds -= contribution;

        if (campaign.totalFunds == 0) campaign.isActive = false;
        if (!token.transfer(msg.sender, contribution)) revert TransferFailed();

        emit RefundIssued(_id, msg.sender, contribution);
    }

    /**
     * @notice Returns the contribution amount of a specific contributor for a campaign.
     * @param _id The ID of the campaign.
     * @param _contributor The address of the contributor.
     * @return The contribution amount in tokens.
     */
    function getContribution(
        uint256 _id,
        address _contributor
    ) public view returns (uint256) {
        return contributions[_id][_contributor];
    }

    /**
     * @notice Returns the details of a specific campaign.
     * @param _id The ID of the campaign.
     * @return goal The fundraising goal of the campaign (in tokens).
     * @return totalFunds The total funds raised by the campaign (in tokens).
     * @return endTime The end time of the campaign as a Unix timestamp.
     * @return creator The address of the campaign creator.
     * @return isActive A boolean indicating whether the campaign is active.
     */
    function getCampaign(
        uint256 _id
    )
        external
        view
        returns (
            uint256 goal,
            uint256 totalFunds,
            uint256 endTime,
            address creator,
            bool isActive
        )
    {
        Campaign memory campaign = campaigns[_id];

        return (
            campaign.goal,
            campaign.totalFunds,
            campaign.endTime,
            campaign.creator,
            campaign.isActive
        );
    }
}
