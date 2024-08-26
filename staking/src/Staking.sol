// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Staking is Ownable {
    struct Stake {
        uint256 createdAt;
        uint256 stakedAmount;
    }

    mapping(address => Stake) public stakes;
    address[] public stakeHolders;

    ERC20 public token;

    error StakingAmountZero();
    error InsufficientTokenBalance();
    error InsufficientOwnerBalance();
    error InsufficientTokenAllowance();
    error InsufficientRedeemAmount();
    error TransferFailed();
    error RewardTransferFailed();
    error NoContributionToReward();
    error NoStakedTokens();
    error RedeemAmountZero();
    error OnlyOwnerFunctional();
    error IndexOutOfBounds();

    event StakeTokens(address indexed contributor, uint256 amount);
    event ClaimInterest(address indexed contributor, uint256 rewards);
    event Redeem(address indexed contributor, uint256 amount);
    event Sweep(uint256 amount);

    constructor(address _token) Ownable(msg.sender) {
        token = ERC20(_token);
    }

    // Allows users to stake tokens
    function stake(uint256 amount) public {
        if (amount == 0) revert StakingAmountZero();
        if (token.balanceOf(msg.sender) < amount)
            revert InsufficientTokenBalance();
        if (token.allowance(msg.sender, address(this)) < amount)
            revert InsufficientTokenAllowance();

        Stake storage userStake = stakes[msg.sender];

        if (userStake.stakedAmount == 0) {
            stakeHolders.push(msg.sender);
        }

        if (userStake.stakedAmount > 0) {
            // Transfer accumulated rewards before updating the stake
            _claimRewards(msg.sender);
        }

        if (!token.transferFrom(msg.sender, address(this), amount))
            revert TransferFailed();

        userStake.stakedAmount += amount;
        userStake.createdAt = block.timestamp;

        emit StakeTokens(msg.sender, amount);
    }

    // Allows users to redeem staked tokens
    function redeem(uint256 amount) public {
        if (amount == 0) revert RedeemAmountZero();
        Stake storage userStake = stakes[msg.sender];
        uint256 stakedTokens = userStake.stakedAmount;
        if (amount > stakedTokens) revert InsufficientRedeemAmount();

        userStake.stakedAmount -= amount;
        if (userStake.stakedAmount == 0) {
            _removeStakeHolder(msg.sender);
        }

        if (!token.transfer(msg.sender, amount)) revert TransferFailed();

        emit Redeem(msg.sender, amount);
    }

    // Transfers rewards to staker
    function claimInterest() public {
        Stake storage userStake = stakes[msg.sender];
        if (userStake.stakedAmount == 0) revert NoContributionToReward();

        _claimRewards(msg.sender);
    }

    // Returns the accrued interest
    function getAccruedInterest(address user) public view returns (uint256) {
        Stake memory stakeInfo = stakes[user];
        if (stakeInfo.stakedAmount == 0) revert NoStakedTokens();

        return _calculateRewards(stakeInfo.stakedAmount, stakeInfo.createdAt);
    }

    // Allows owner to collect all the staked tokens
    function sweep() public onlyOwner {
        uint256 stakedAmount = token.balanceOf(address(this));

        clearAllStakes();

        if (!token.transfer(owner(), stakedAmount)) revert TransferFailed();

        emit Sweep(stakedAmount);
    }

    //----------------------------helpers---------------------------//
    function _calculateRewards(
        uint256 stakedAmount,
        uint256 createdAt
    ) private view returns (uint256 rewards) {
        uint256 timePassed = block.timestamp - createdAt;
        if (timePassed < 1 days) return 0;
        if (timePassed < 1 weeks) return (stakedAmount * 1) / 100;
        if (timePassed < 30 days) return (stakedAmount * 10) / 100;
        return (stakedAmount * 50) / 100;
    }

    function _claimRewards(address staker) private {
        Stake storage userStake = stakes[staker];
        uint256 rewards = _calculateRewards(
            userStake.stakedAmount,
            userStake.createdAt
        );

        if (rewards > 0) {
            if (token.balanceOf(address(this)) < rewards) {
                revert InsufficientOwnerBalance();
            }
            if (!token.transfer(staker, rewards)) revert RewardTransferFailed();
            emit ClaimInterest(staker, rewards);
        }
        userStake.createdAt = block.timestamp;
    }

    function _removeStakeHolder(address staker) private {
        for (uint256 i = 0; i < stakeHolders.length; i++) {
            if (stakeHolders[i] == staker) {
                stakeHolders[i] = stakeHolders[stakeHolders.length - 1];
                stakeHolders.pop();
                return;
            }
        }
    }

    // this function also used for testing purpose
    function clearAllStakes() public onlyOwner {
        for (uint256 i = 0; i < stakeHolders.length; i++) {
            address stakeHolder = stakeHolders[i];
            delete stakes[stakeHolder];
        }
        delete stakeHolders;
    }

    //----------------------------only for testing-----------------------//
    function getStakeItem()
        external
        view
        returns (uint256 createdAt, uint256 stakedAmount)
    {
        Stake memory stakeItem = stakes[msg.sender];
        return (stakeItem.createdAt, stakeItem.stakedAmount);
    }

    function getStakeHoldersCount() external view returns (uint256) {
        return stakeHolders.length;
    }

    function getStakeHolder(uint256 index) external view returns (address) {
        if (index > stakeHolders.length) revert IndexOutOfBounds();
        return stakeHolders[index];
    }
}
