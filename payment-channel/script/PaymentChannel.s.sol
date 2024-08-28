// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PaymentChannel.sol";

contract DeployPaymentChannel is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address recipientAddress = vm.envAddress("RECIPIENT_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        PaymentChannel paymentChannel = new PaymentChannel(recipientAddress);

        vm.stopBroadcast();

        console.log(
            "PaymentChannel Contract Address:",
            address(paymentChannel)
        );
    }
}
