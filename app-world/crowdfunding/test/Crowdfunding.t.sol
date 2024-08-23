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
    address payable public thirdContributor;

    function setUp() public {
        owner = payable(address(0x1));
        firstContributor = payable(address(0x2));
        secondContributor = payable(address(0x3));
        thirdContributor = payable(address(0x4));
        vm.startPrank(owner);

        token = new MockERC20("Test Token", "TST");

        // Mint tokens to contributors
        token.mint(firstContributor, 2 ether);
        token.mint(secondContributor, 2 ether);

        crowdfunding = new Crowdfunding(address(token), owner);
        vm.stopPrank();
    }

    //-------------------------campaign create tests------------------------//

    function testCreateCampaign() public {
        vm.prank(firstContributor);
        crowdfunding.createCampaign(3 ether, 1 days);

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
        assertEq(creator, firstContributor);
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
        vm.prank(owner);
        crowdfunding.createCampaign(2 ether, 1 days);

        _contribute(firstContributor, 0, 1 ether);
        _contribute(secondContributor, 0, 1 ether);

        (, uint256 totalFunds, , , ) = crowdfunding.getCampaign(0);
        assertEq(totalFunds, 2 ether);
    }

    //--------------------------------helpers---------------------------//
    function _contribute(
        address contributer,
        uint256 campaignId,
        uint256 amount
    ) private {
        vm.startPrank(contributer);
        token.approve(address(crowdfunding), amount);
        crowdfunding.contribute(campaignId, amount);
        vm.stopPrank();
    }
}
