// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../src/Crowdfunding.sol";
import "./mocks/MockERC20Token.sol";

contract CrowdfundingTest is Test {
    MockERC20 public token;
    Crowdfunding public crowdfunding;
    address payable public owner;
    address payable public firstContributor;
    address payable public secondContributor;

    function setUp() public {
        owner = payable(address(0x1));
        firstContributor = payable(address(0x2));
        secondContributor = payable(address(0x3));
        vm.startPrank(owner);

        token = new MockERC20("Test Token", "TST");

        // Mint tokens to contributors
        token.mint(firstContributor, 1 ether);
        token.mint(secondContributor, 1 ether);

        crowdfunding = new Crowdfunding(address(token), owner);
        vm.stopPrank();
    }

    //-------------------------campaign create tests------------------------//

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

    function testCreateCompaingFailsWhenAmountZero() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignAmountZero.selector);
        crowdfunding.createCampaign(0 ether, 1 days);
    }

    function testCreateCompaignFailsWhenShortDuration() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignShortDuration.selector);
        crowdfunding.createCampaign(1 ether, 0 days);
    }

    //---------------------------contribute tests--------------------------//

    function testContribute() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        (, uint256 totalFunds, , , ) = crowdfunding.getCampaign(0);
        assertEq(totalFunds, 2 ether);
    }

    function testContributeFailsWhenCampaignNotActive() public {
        _contributeOrFail(
            firstContributor,
            0,
            1 ether,
            Crowdfunding.CampaignNotActive.selector
        );
    }

    function testContributeFailsWhenCompaingEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 2 days);
        _contributeOrFail(
            firstContributor,
            0,
            1 ether,
            Crowdfunding.CampaignEnded.selector
        );
    }

    function testContributeFailsWhenInvalidContributionAmount() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(
            firstContributor,
            0,
            0 ether,
            Crowdfunding.InvalidContributionAmount.selector
        );
    }

    function testContributeFailsWhenCreatorContibuted() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(
            owner,
            0,
            1 ether,
            Crowdfunding.CreatorCannotContribute.selector
        );
    }

    function testContributeFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.startPrank(firstContributor);
        token.approve(address(crowdfunding), 0.5 ether);
        vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.contribute(0, 1 ether);
        vm.stopPrank();
    }

    //---------------------------cancel contribution tests--------------------------//

    function testCancelContribution() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(firstContributor);
        crowdfunding.cancelContribution(0);

        (, uint256 totalFunds, , , ) = crowdfunding.getCampaign(0);
        assertEq(totalFunds, 0 ether);
        // assertEq(address(firstContributor).balance, 1 ether);
    }

    function testCancelContributionFailsWhenNotActive() public {
        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignNotActive.selector);
        crowdfunding.cancelContribution(0);
    }

    function testCancelContributionFailsWhenWhenEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.CampaignEnded.selector);
        crowdfunding.cancelContribution(0);
    }

    function testCancelContributionFailsWhenNoContibution() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.NoContributionToCancel.selector);
        crowdfunding.cancelContribution(0);
    }

    function testCancelContributionFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);

        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(firstContributor);
        // TODO debug. we need to set something to fail cancelContibution transaction
        // but contribute should works
        // vm.expectRevert(Crowdfunding.TransferFailed.selector);
        crowdfunding.cancelContribution(0);
    }

    //---------------------------cancel contribution tests--------------------------//

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

    function testWidthdrawFundsFailsWhenNotCampaignCreator() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.NotCampaignCreator.selector);
        crowdfunding.withdrawFunds(0);
    }

    function testeWithdrawFundsFailsWhenCampaingNotEnded() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        crowdfunding.withdrawFunds(0);
    }

    function testeWithdrawFundsFailsWhenGoalNotReached() public {
        _createCampaignByOwner(2 ether, 1 days);

        vm.warp(block.timestamp + 1 days);

        vm.prank(owner);
        vm.expectRevert(Crowdfunding.GoalNotReached.selector);
        crowdfunding.withdrawFunds(0);
    }

    function testeWithdrawFundsFailsWhenTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        // TODO like  testCancelContributionFailsWhenTransferFailed
    }

    //----------------------------refund tests---------------------------//

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

    function testRefundsFailsWhenCampaingNotEnded() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.CampaignNotEnded.selector);
        crowdfunding.refund(0);
    }

    function testRefundFailsWhenGoalReached() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.GoalReached.selector);
        crowdfunding.refund(0);
    }

    function testRefundFailsWhenNoContributionRefund() public {
        _createCampaignByOwner(2 ether, 1 days);
        vm.warp(block.timestamp + 1 days);

        vm.prank(firstContributor);
        vm.expectRevert(Crowdfunding.NoContributionToRefund.selector);
        crowdfunding.refund(0);
    }

    function testeWithdrawFundsFailsTransferFailed() public {
        _createCampaignByOwner(2 ether, 1 days);
        _contributeOrFail(firstContributor, 0, 1 ether, bytes4(0));
        _contributeOrFail(secondContributor, 0, 1 ether, bytes4(0));

        vm.warp(block.timestamp + 1 days);

        // TODO like  testCancelContributionFailsWhenTransferFailed
    }

    //--------------------------------helpers---------------------------//

    function _contributeOrFail(
        address contributer,
        uint256 campaignId,
        uint256 amount,
        bytes4 errMessage
    ) private {
        vm.startPrank(contributer);
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
}
