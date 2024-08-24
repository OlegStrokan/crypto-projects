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
    address public owner;

    error StackingAmountZero();
    error InsufficientTokenBalance();
    error InsufficientTokenAllowance();
    error InsufficientReedemAmount();
    error TransferFailed();
    error RewardTransferFailed();
    error NoContributionToReward();
    error NoStakedTokens();
    error ReedemAmountZero();
    error OnlyOwnerFunctional();

    event StakeTokens(address indexed contributor, uint256 amount);
    event ClaimInterest(address indexed contributor, uint256 rewards);
    event Reedem(address indexed contribuor, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwnerFunctional();
        _;
    }
    constructor(address _token) {
        token = ERC20(_token);
        owner = msg.sender;
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

        emit StakeTokens(msg.sender, amount);
    }

    // allows users to reedem staked tokens
    function reedem(uint256 amount) public {
        if (amount == 0) revert ReedemAmountZero();
        uint256 stakedTokens = stakes[msg.sender].stakedAmount;
        if (amount > stakedTokens) revert InsufficientReedemAmount();

        if (
            !token.transferFrom(
                address(this),
                msg.sender,
                stakes[msg.sender].stakedAmount
            )
        ) revert TransferFailed();

        stakes[msg.sender].stakedAmount = 0;

        emit Reedem(msg.sender, amount);
    }

    // transfers rewards to staker
    function claimInterest() public {
        if (stakes[msg.sender].stakedAmount == 0)
            revert NoContributionToReward();

        _claimRewards(stakes[msg.sender].stakedAmount, msg.sender);
        stakes[msg.sender].stakedAmount = 0;
    }

    // returns the accrued interest
    function getAccruedInterest(address user) public view returns (uint256) {
        Stake memory stakeInfo = stakes[user];
        if (stakeInfo.stakedAmount == 0) revert NoStakedTokens();

        uint256 rewards = _calculateRewards(
            stakeInfo.stakedAmount,
            stakeInfo.createdAt
        );
        return rewards;
    }

    // allows owner to collect all the staked tokens
    function sweep() public onlyOwner {
        uint256 stakedAmount = token.balanceOf(address(this));

        if (!token.transfer(owner, stakedAmount)) revert TransferFailed();
    }

    //----------------------------helpers---------------------------//
    function _calculateRewards(
        uint256 stakedAmount,
        uint256 createdAt
    ) private view returns (uint256 rewards) {
        uint256 timePassed = block.timestamp - createdAt;
        if (timePassed < 1 days) return 0;
        if (timePassed >= 1 days && timePassed < 1 weeks)
            return stakedAmount + ((stakedAmount * 1) / 100);
        if (timePassed >= 1 weeks && timePassed < 30 days)
            return stakedAmount + ((stakedAmount * 10) / 100);
        if (timePassed >= 30 days)
            return stakedAmount + ((stakedAmount * 50) / 100);
    }

    function _claimRewards(uint256 _stakedAmount, address _sender) private {
        uint256 createdAt = stakes[_sender].createdAt;
        uint256 rewards = _calculateRewards(_stakedAmount, createdAt);

        if (!token.transferFrom(address(this), _sender, rewards))
            revert RewardTransferFailed();

        emit ClaimInterest(_sender, rewards);
    }
}
