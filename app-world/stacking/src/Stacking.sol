// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Staking {
    struct Stake {
        address contributor;
        uint256 createdAt;
        uint256 stakedAmount;
    }

    mapping(address => Stake) public stakes;

    ERC20 public token;
    address public poolAddress;

    error StackingAmountZero();
    error InsufficientTokenBalance();
    error InsufficientTokenAllowance();
    error TransferFailed();
    error RewardTransferFailed();
    error NoContributionToReward();
    error ReedemAmountZero();

    event Stake(address indexed contributor, uint256 amount);
    event ClaimInterest(address indexed contributor, uint256 rewards);

    constructor(address _token) {
        token = ERC20(_token);
    }

    // allows users to stake tokens
    function stake(uint256 amount) public {
        if (amount == 0) revert StackingAmountZero();
        if (token.balanceOf(msg.sender) < amount)
            revert InsufficientTokenBalance();
        if (token.allowance(msg.sender, address(this)) < amount)
            revert InsufficientTokenAllowance();
        if (stakes[msg.sender].stakedAmount > 0) {
            _claimRewards(stakes[msg.sender].stakedAmount, msg.sender);
            stakes[msg.sender].stakedAmount = 0;
        }

        if (!token.transferFrom(msg.sender, address(this), amount))
            revert TransferFailed();

        stakes[msg.sender].stakedAmount += amount;
        stakes[msg.sender].createdAt = block.timestamp;

        emit Stake(msg.sender, amount);
    }

    // allows users to reedem staked tokens
    function reedem(uint256 amount) public {
        if (amount == 0) revert ReedemAmountZero();
        uin256 stakedTokens = stakes[msg.sender].stakedToken;
        if (amount > stakedTokens) revert InsufficientReedemAmount();

        if(!token.transferFrom(stakes[msg.sender].stakedAmount, msg.sender)) revert TransferFailed();
    }

    // transfers rewards to staker
    function claimInterest() public {
        if (stakes[msg.sender].stakedAmount == 0) revert NoContributionToReward();

         _claimRewards(stales[msg.sender].stakedAmount, msg.sender);
        stakes[msg.sender].stakedAmount = 0;

    }

    // returns the accrued interest
    function getAccruedInterest(address user) public returns (uint256) {}

    // allows owner to collect all the staked tokens
    function sweep() public {}

    //----------------------------helpers---------------------------//
    function _calculateRewards(
        uint256 stakedAmount,
        uint256 createdAt
    ) private pure returns (uint256 rewards) {
        uint256 timePassed = block.timestamp - createdAt;
        if (timePassed < 1 days) return 0;
        if (timePassed >= 1 days && timePassed < 1 weeks)
            return amount + ((amount * 1) / 100);
        if (timePassed >= 1 weeks && timePassed < 30 days)
            return amount + ((amount * 10) / 100);
        if (timePassed >= 30 days) return amount + ((amount * 50) / 100);
    }

    function _claimRewards(
        uin256 stakedAmount,
        address sender
    ) private {
          uint256 stakedAmount = stakes[msg.sender].stakedAmount;
         uint256 rewards = _calculateRewards(stakedAmount, sender);

            if (!token.transferFrom(address(this), sender,, rewards))
                revert RewardTransferFailed();

        emit ClaimInterest(msg.sender, rewards);
    }
}
