// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdFundEasy {
    ERC20 public token;

    struct Investor {
        uin256 id;
        uint256 amountInvested;
        address addr;
    }

    mapping(uint256 => Investor) public investors;

    struct Campaign {
        uint256 goal;
        uint256 duration;
        uint256 totalFunds;
        mapping(uin256 => investorId) investors;
    }

    mapping(uint256 => Campaign) campaings;

    //---------------------------custom erros--------------------------//
    error CampaignAmountZero();
    error CampaignDurationTooShort();

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
        require(_goal > 0, CampaignAmountZero());
        require(_duration >= 1 days, CampaignDurationTooShort());

        Campaign memory campaign = new Campaign({
            id: campaings.length + 1,
            duration: _duration,
            goal: _goal,
            totalFunds: 0,
            investors: []
        });

        campaings.push(campaign);
    }

    /**
     * @dev contribute allows anyone to contribute to a campaign
     * @param _id the id of the campaign
     * @param _amount the amount of tokens to contribute
     */
    function contribute(uint256 _id, uint256 _amount) external {}

    /**
     * @dev cancelContribution allows anyone to cancel their contribution
     * @param _id the id of the campaign
     */
    function cancelContribution(uint256 _id) external {}

    /**
     * @notice withdrawFunds allows the creator of the campaign to withdraw the funds
     * @param _id the id of the campaign
     */

    function withdrawFunds(uint256 _id) external {}

    /**
     * @notice refund allows the contributors to get a refund if the campaign failed
     * @param _id the id of the campaign
     */
    function refund(uint256 _id) external {}

    /**
     * @notice getContribution returns the contribution of a contributor in USD
     * @param _id the id of the campaign
     * @param _contributor the address of the contributor
     */
    function getContribution(
        uint256 _id,
        address _contributor
    ) public view returns (uint256) {}

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
    {}
}
