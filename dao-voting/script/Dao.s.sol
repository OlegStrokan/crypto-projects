// script/DeployDAO.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/DAO.sol";

contract DeployDAO is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DAO dao = new DAO();
        console.log("DAO contract deployed to:", address(dao));

        vm.stopBroadcast();
    }
}
