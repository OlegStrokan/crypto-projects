// script/DeployCrowdfunding.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Crowdfunding.sol";

contract DeployCrowdfunding is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        Crowdfunding crowdfunding = new Crowdfunding(tokenAddress, msg.sender);
        console.log(
            "Crowdfunding contract deployed to:",
            address(crowdfunding)
        );

        vm.stopBroadcast();
    }
}
