//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/PaymentChannel.sol";

contract PaymentChannelTest is Test {
    PaymentChannel public paymentChannel;
    address payable public owner;
    address payable public recipient;

    function setUp() public {
        owner = payable(address(0x123));
        recipient = payable(address(0x456));
        vm.startPrank(owner);
        paymentChannel = new PaymentChannel(recipient);
        vm.stopPrank();
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();

        assertEq(paymentChannel.checkBalance(), depositAmount);
        assertEq(paymentChannel.depositedAmount(), depositAmount);
    }
}
