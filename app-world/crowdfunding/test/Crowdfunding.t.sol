// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "./mocks/MockERC20Token.sol";

contract CrowdfundingTest is Test {
    MockERC20 public token;
    Crowdfunding public crowdfunding;
    address public owner;
    address public firstContributor;
    address public secondContributor;
    address public deadAddress;

    function setUp() public {
        owner = vm.addr(1);
        firstContributor = vm.addr(2);
        secondContributor = vm.addr(3);
        deadAddress = vm.addr(4);
        vm.startPrank(owner);

        token = new MockERC20("Test Token", "TST");

        // Mint tokens to contributors
        token.mint(firstContributor, 1 ether);
        token.mint(secondContributor, 1 ether);

        crowdfunding = new Crowdfunding(address(token), owner);
        vm.stopPrank();
    }

    //-------------------------campaign create tests------------------------//

    /// @notice Tests successful campaign creation.
    function testCreateCampaign() public {
        _createCampaignByOwner(3 ether, 1 days);

        (
            uint256 goal,
            uint256 totalFunds,
            uint256 endTime,
            address creator,
            bool isActive
        ) = crowdfunding.getCampaign(0);

        assertEq(goal, 3 ether);
        assertEq(endTime, block.timestamp + 1 days);
        assertEq(isActive, true);
        assertEq(totalFunds, 0);
        assertEq(creator, owner);
    }

    /// @notice Tests that creating a campaign with zero amount fails.
    function testCreateCampaignFailsWhenAmountZero() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignAmountZero.selector);
        crowdfunding.createCampaign(0 ether, 1 days);
    }

    /// @notice Tests that creating a campaign with a duration of zero days fails.
    function testCreateCampaignFailsWhenShortDuration() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignShortDuration.selector);
        crowdfunding.createCampaign(1 ether, 0 days);
    }

    //---------------------------contribute tests--------------------------//

    /// @notice Tests successful contribution to a campaign.
    function testContribute() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        (, uint256 totalFunds, , , ) = crowdfunding.getCampaign(0);
        assertEq(totalFunds, 2 ether);
    }

    /// @notice Tests that contributing to a non-active campaign fails.
    function testContributeFailsWhenCampaignNotActive() public {
        _contributeOrFail(
            firstContributor,
            0,
            1 ether,
            Crowdfunding.CampaignNotActive.selector
        );
    }

    /// @notice Tests that contributing to an ended campaign fails.
    function testContributeFailsWhenCampaignEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 2 days);
        _contributeOrFail(
            firstContributor,
            0,
            1 ether,
            Crowdfunding.CampaignEnded.selector
        );
    }

    /// @notice Tests that contributing with an invalid amount (zero) fails.
    function testContributeFailsWhenInvalidContributionAmount() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(
            firstContributor,
            0,
            0 ether,
            Crowdfunding.InvalidContributionAmount.selector
        );
    }

    /// @notice Tests that the campaign creator cannot contribute to their own campaign.
    function testContributeFailsWhenCreatorContributed() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(
            owner,
            0,
            1 ether,
            Crowdfunding.CreatorCannotContribute.selector
        );
    }

    /// @notice Tests that a contribution fails if token transfer fails.
    function testContributeFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.startPrank(firstContributor);
        token.approve(address(crowdfunding), 0.5 ether);
        vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.contribute(0, 1 ether);
        vm.stopPrank();
    }

    //---------------------------cancel contribution tests--------------------------//

    /// @notice Tests successful cancellation of a contribution.
    function testCancelContribution() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(firstContributor);
        crowdfunding.cancelContribution(0);

        (, uint256 totalFunds, , , ) = crowdfunding.getCampaign(0);
        assertEq(totalFunds, 0 ether);
        // assertEq(address(firstContributor).balance, 1 ether);
    }

    /// @notice Tests that canceling a contribution fails when the campaign is not active.
    function testCancelContributionFailsWhenNotActive() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignNotActive.selector);
        crowdfunding.cancelContribution(0);
    }

    /// @notice Tests that canceling a contribution fails when the campaign has ended.
    function testCancelContributionFailsWhenEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.CampaignEnded.selector);
        crowdfunding.cancelContribution(0);
    }

    /// @notice Tests that canceling a contribution fails when there was no contribution.
    function testCancelContributionFailsWhenNoContribution() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.NoContributionToCancel.selector);
        crowdfunding.cancelContribution(0);
    }

    /// @notice Tests that canceling a contribution fails if token transfer fails.
    function testCancelContributionFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(address(crowdfunding));
        token.transfer(deadAddress, 1 ether);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.cancelContribution(0);
    }

    //---------------------------withdraw funds tests--------------------------//

    /// @notice Tests successful withdrawal of funds by the campaign creator.
    function testWithdrawFunds() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        crowdfunding.withdrawFunds(0);
        (uint256 goal, uint256 totalFunds, , , bool isActive) = crowdfunding
            .getCampaign(0);

        assertEq(0 ether, totalFunds);
        assertEq(isActive, false);

        assertEq(token.balanceOf(owner), goal);
    }

    /// @notice Tests that a non-campaign creator cannot withdraw funds.
    function testWithdrawFundsFailsWhenNotCampaignCreator() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.NotCampaignCreator.selector);
        crowdfunding.withdrawFunds(0);
    }

    /// @notice Tests that withdrawing funds fails if the campaign has not ended.
    function testWithdrawFundsFailsWhenCampaignNotEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        crowdfunding.withdrawFunds(0);
    }

    /// @notice Tests that withdrawing funds fails if the campaign goal was not reached.
    function testWithdrawFundsFailsWhenGoalNotReached() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.GoalNotReached.selector);
        crowdfunding.withdrawFunds(0);
    }

    /// @notice Tests that withdrawing funds fails if token transfer fails.
    function testWithdrawFundsFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(address(crowdfunding));
        token.transfer(deadAddress, 1 ether);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.withdrawFunds(0);

        (, uint256 totalFunds, , , bool isActive) = crowdfunding.getCampaign(0);

        assertEq(2 ether, totalFunds);
        assertEq(isActive, true);

        assertEq(token.balanceOf(owner), 0 ether);
    }

    //----------------------------refund tests---------------------------//

    /// @notice Tests successful refund of contributions.
    function testRefund() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 0.8 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        crowdfunding.refund(0);

        (, uint256 totalFunds, , , bool isActive) = crowdfunding.getCampaign(0);

        assertEq(token.balanceOf(firstContributor), 1 ether);
        assertEq(totalFunds, 0.8 ether);
        assertEq(isActive, true);

        vm.prank(secondContributor);
        crowdfunding.refund(0);

        (
            ,
            uint256 totalFundsAfterSecondRefund,
            ,
            ,
            bool isActiveAfterSecondRefund
        ) = crowdfunding.getCampaign(0);

        assertEq(token.balanceOf(secondContributor), 0.8 ether + 0.2 ether);
        assertEq(totalFundsAfterSecondRefund, 0 ether);
        assertEq(isActiveAfterSecondRefund, false);
    }

    /// @notice Tests that refunding fails when the campaign has not ended.
    function testRefundFailsWhenCampaignNotEnded() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        crowdfunding.refund(0);
    }

    /// @notice Tests that refunding fails when the campaign goal was reached.
    function testRefundFailsWhenGoalReached() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.GoalReached.selector);
        crowdfunding.refund(0);
    }

    /// @notice Tests that refunding fails when there are no contributions to refund.
    function testRefundFailsWhenNoContributionToRefund() public {
        _createCampaignByOwner(2 ether, 1 days);
        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.NoContributionToRefund.selector);
        crowdfunding.refund(0);
    }

    /// @notice Tests that refunding funds fails if token transfer fails.
    function testRefundFundsFailsTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 0.5 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(address(crowdfunding));
        token.transfer(deadAddress, 1.5 ether);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.refund(0);
    }

    //--------------------------------helpers---------------------------//

    function _contributeOrFail(
        address contributor,
        uint256 campaignId,
        uint256 amount,
        bytes4 errMessage
    ) private {
        vm.startPrank(contributor);
        token.approve(address(crowdfunding), amount);
        if (errMessage != bytes4(0)) {
            vm.expectRevert(errMessage);
        }
        crowdfunding.contribute(campaignId, amount);
        vm.stopPrank();
    }

    function _createCampaignByOwner(uint256 amount, uint256 duration) private {
        vm.prank(owner);
        crowdfunding.createCampaign(amount, duration);
    }

    //---------------------------getContribution and getCampaign additional tests--------------------------//

    /// @notice Tests that `getContribution` returns zero if there was no contribution.
    function testGetContributionFailsWhenNoContribution() public {
        _createCampaignByOwner(2 ether, 1 days);

        uint256 contribution = crowdfunding.getContribution(
            0,
            firstContributor
        );
        assertEq(contribution, 0);
    }

    /// @notice Tests the `getCampaign` function with an invalid campaign ID.
    function testGetCampaignFailsWhenInvalidCampaignId() public view {
        // Simulate a scenario where the campaign ID is invalid (e.g., no such campaign)
        // You can only test this if your contract has some way of detecting invalid IDs
        // Currently, if there's no such campaign, getCampaign will return default values
        (
            uint256 goal,
            uint256 totalFunds,
            uint256 endTime,
            address creator,
            bool isActive
        ) = crowdfunding.getCampaign(999);
        assertEq(goal, 0);
        assertEq(totalFunds, 0);
        assertEq(endTime, 0);
        assertEq(creator, address(0));
        assertEq(isActive, false);
    }

    /// @notice Tests that `getCampaign` returns default values when the campaign does not exist.
    function testGetCampaignReturnsDefaultValuesWhenCampaignDoesNotExist()
        public
        view
    {
        (
            uint256 goal,
            uint256 totalFunds,
            uint256 endTime,
            address creator,
            bool isActive
        ) = crowdfunding.getCampaign(999);
        assertEq(goal, 0);
        assertEq(totalFunds, 0);
        assertEq(endTime, 0);
        assertEq(creator, address(0));
        assertEq(isActive, false);
    }
}
