// SPDX-License-Inentifier: MIT
pragma solidity 0.8.10;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "account-abstraction/src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "account-abstraction/script/HelperConfig.s.sol";

contract DeployMinimal is Script {
    function run() public {}

    function deployMinimalAccount() public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        minimalAccount.transferOwnership(msg.sender);
        vm.stopBroadcast();
    }
}
