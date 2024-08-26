// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "forge-std/Test.sol";
import "../src/Staking.sol";
import "./mocks/MockERC20Token.sol";

contract StackingTest is Test {
    MockERC20 public token;
    Staking public staking;
    address public owner;
    address public contributor;
    address public anotherContributor;

    address public deadAddress;

    function setUp() public {
        owner = vm.addr(1);
        contributor = vm.addr(2);
        anotherContributor = vm.addr(3);
        deadAddress = vm.addr(4);

        vm.startPrank(owner);

        token = new MockERC20("Miami E-Token", "METH");
        token.mint(contributor, 1 ether);
        token.mint(anotherContributor, 1 ether);

        staking = new Staking(address(token));

        vm.stopPrank();
    }

    //----------------------------stake tests---------------------------//

    function testStake() public {
        _stakeOrFail(contributor, 0.4 ether, bytes4(0));

        vm.prank(contributor);
        (uint256 createdAt, uint256 stakedAmount) = staking.getStakeItem();
        assertEq(token.balanceOf(address(staking)), 0.4 ether);
        assertEq(stakedAmount, 0.4 ether);
        assertEq(createdAt, block.timestamp);
        assertEq(token.balanceOf(contributor), 0.6 ether);

        vm.warp(1 weeks);

        _stakeOrFail(contributor, 0.6 ether, bytes4(0));
    }

    function testStakeAndClaimRewards() public {
        vm.prank(owner);
        token.mint(address(staking), 1 ether);

        _stakeOrFail(contributor, 0.4 ether, bytes4(0));

        vm.prank(contributor);
        (uint256 createdAt, uint256 stakedAmount) = staking.getStakeItem();
        assertEq(token.balanceOf(address(staking)), 1.4 ether);
        assertEq(stakedAmount, 0.4 ether);
        assertEq(createdAt, block.timestamp);
        assertEq(token.balanceOf(contributor), 0.6 ether);

        vm.warp(1 weeks);

        vm.prank(contributor);
        staking.claimInterest();
        assertEq(token.balanceOf(contributor), 0.604 ether);
        assertEq(token.balanceOf(address(staking)), 1.396 ether);
    }

    function testStakeFailsWhenAmountZero() public {
        _stakeOrFail(contributor, 0, Staking.StakingAmountZero.selector);
    }

    function testStakeFailsWhenInsufficientTokenBalance() public {
        vm.startPrank(contributor);
        token.approve(address(staking), 1 ether);
        token.transfer(deadAddress, 0.5 ether);
        vm.expectRevert(Staking.InsufficientTokenBalance.selector);
        staking.stake(1 ether);
        vm.stopPrank();
    }

    function testStakeFailsWhenInsufficientTokenAllowance() public {
        vm.startPrank(contributor);
        token.approve(address(staking), 0.9 ether);
        vm.expectRevert(Staking.InsufficientTokenAllowance.selector);
        staking.stake(1 ether);
        vm.stopPrank();
    }

    function testStakeFailsWhenTransferFailed() public {
        /* TODO - upderstand how to trigger TransferFailed error
        vm.startPrank(contributor);
        token.approve(address(staking), 0.9 ether);
        vm.expectRevert(Staking.InsufficientTokenAllowance.selector);
        staking.stake(1 ether);
        vm.stopPrank();
        */
    }

    //----------------------------redeem tests---------------------------//

    function testRedeem() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(contributor);
        staking.redeem(1 ether);
        (, uint256 stakedAmount) = staking.getStakeItem();
        assertEq(token.balanceOf(address(staking)), 0 ether);
        assertEq(stakedAmount, 0 ether);
        assertEq(token.balanceOf(contributor), 1 ether);
    }

    function testRedeemFailsWhenAmountZero() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(contributor);
        vm.expectRevert(Staking.RedeemAmountZero.selector);
        staking.redeem(0 ether);
    }

    function testRedeemFailsWhenInsufficientRedeemAmount() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(contributor);
        vm.expectRevert(Staking.InsufficientRedeemAmount.selector);
        staking.redeem(1.1 ether);
    }

    function testRedeemFailsWhenTransferFailed() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(address(staking));
        token.transfer(deadAddress, 0.5 ether);

        vm.prank(contributor);
        vm.expectRevert(Staking.TransferFailed.selector);
        staking.redeem(1 ether);
    }

    //-----------------------------claim intereset tests--------------------------//

    function testClaimInterest() public {
        vm.prank(owner);
        token.mint(address(staking), 1 ether);

        _stakeOrFail(contributor, 0.4 ether, bytes4(0));

        vm.warp(1 weeks);

        vm.prank(contributor);
        staking.claimInterest();
        assertEq(token.balanceOf(contributor), 0.604 ether);
        assertEq(token.balanceOf(address(staking)), 1.396 ether);
    }

    function testClaimInterestFailsWhenNoContributionToReward() public {
        vm.prank(owner);
        token.mint(address(staking), 1 ether);

        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(owner);
        staking.clearAllStakes();

        vm.prank(contributor);
        vm.expectRevert(Staking.NoContributionToReward.selector);
        staking.claimInterest();
    }

    function testClaimInterestFailedWhenInsufficionOwnerBalance() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(address(staking));
        token.transfer(deadAddress, 1 ether);

        vm.warp(1 weeks);

        vm.prank(contributor);
        vm.expectRevert(Staking.InsufficientOwnerBalance.selector);
        staking.claimInterest();
    }

    //-----------------------------claim intereset tests--------------------------//

    function testGetAccruedInterest() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.warp(1 weeks);
        uint256 rewards = staking.getAccruedInterest(contributor);

        assertEq(rewards, 0.01 ether);

        vm.warp(24 days);
        uint256 updatedRewards = staking.getAccruedInterest(contributor);

        assertEq(updatedRewards, 0.1 ether);
    }

    function testGetAccruedInterestFailsWhenNoStakedTokens() public {
        vm.expectRevert(Staking.NoStakedTokens.selector);
        staking.getAccruedInterest(contributor);
    }

    //--------------------------------sweep test----------------------------------//

    function testSweep() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(owner);
        staking.sweep();

        (, uint256 stakedAmount) = staking.getStakeItem();

        assertEq(token.balanceOf(owner), 1 ether);
        assertEq(token.balanceOf(address(staking)), 0 ether);
        assertEq(stakedAmount, 0 ether);
    }

    function testSweepFailsWhenTransferFailed() public {
        /*
        _stakeOrFail(contributor, 1 ether, bytes4(0));

        vm.prank(address(staking));
        token.transfer(deadAddress, 1 ether);

        vm.prank(owner);
        vm.expectRevert(Staking.TransferFailed.selector);
        staking.sweep();
        */
    }

    function testRemoveStakeHolder() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));
        _stakeOrFail(anotherContributor, 1 ether, bytes4(0));

        vm.prank(contributor);
        staking.redeem(1 ether);

        (, uint256 stakedAmount) = staking.getStakeItem();
        assertEq(stakedAmount, 0 ether);
        assertEq(token.balanceOf(contributor), 1 ether);

        uint256 stakeHoldersCount = staking.getStakeHoldersCount();
        assertEq(stakeHoldersCount, 1);

        address remainingStaker = staking.getStakeHolder(0);
        assertEq(remainingStaker, anotherContributor);
    }

    function testClearAllStakes() public {
        _stakeOrFail(contributor, 1 ether, bytes4(0));
        _stakeOrFail(anotherContributor, 1 ether, bytes4(0));

        vm.prank(owner);
        staking.clearAllStakes();

        (, uint256 stakedAmount) = staking.getStakeItem();
        assertEq(stakedAmount, 0 ether);

        uint256 stakeHoldersCount = staking.getStakeHoldersCount();
        assertEq(stakeHoldersCount, 0);
    }

    //-----------------------------------helpers----------------------------------//

    function _stakeOrFail(
        address _contributor,
        uint256 _amount,
        bytes4 _errMessage
    ) private {
        vm.startPrank(_contributor);
        token.approve(address(staking), _amount);
        if (_errMessage != bytes4(0)) {
            vm.expectRevert(_errMessage);
        }
        staking.stake(_amount);
        vm.stopPrank();
    }
}
