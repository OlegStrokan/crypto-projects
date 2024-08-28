// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/token/METHToken.sol";
import "../src/token/TokenManagment.sol";
import "../src/Staking.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy METHToken with initial supply of 1 million tokens
        METHToken token = new METHToken(1_000_000);

        // Define the sale price for tokens (e.g., 0.001 ETH per token)
        uint256 tokenSalePrice = 0.001 ether;

        // Deploy TokenManagment with token address and sale price
        TokenManagment ico = new TokenManagment(address(token), tokenSalePrice);

        // Transfer 500,000 tokens to the TokenManagment contract
        token.transfer(address(ico), 500_000 * 10 ** token.decimals());

        // Deploy Staking contract with the token address
        Staking staking = new Staking(address(token));

        vm.stopBroadcast();

        console.log("Token Address:", address(token));
        console.log("TokenManagment Contract Address:", address(ico));
        console.log("Staking Contract Address:", address(staking));
    }
}
