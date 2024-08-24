// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Staking {
    address public liquidityPool;
    ERC20 public token;

    error StackingAmountZero();

    constructor(address _token) {
        _token = ERC20(_token);
    }

    // allows users to stake tokens
    function stake(uint256 amount) public {
        if (amount == 0) revert StackingAmountZero();
    }

    // allows users to reedem staked tokens
    function reedem(uint256 amount) public {}

    // transfers rewards to staker
    function claimInterest() public {}

    // returns the accrued interest
    function getAccruedInterest(address user) public returns (uint256) {}

    // allows owner to collect all the staked tokens
    function sweep() public {}
}
