// SPDX-License-Identitier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Staking} from "../src/Staking.sol";

contract DeployStaking is Script {
    function run() external {
        address tokenAddress = 0x5a1d6ecbbf9398314A3b6D4b1050c4adbEF0a14a;

        vm.startBroadcast();

        Staking stakingContract = new Staking(tokenAddress);

        console.log("Staking contract deployed at: ", address(stakingContract));

        vm.stopBroadcast();
    }
}
