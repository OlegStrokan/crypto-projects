//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/PaymentChannel.sol";

contract PaymentChannelTest is Test {
    PaymentChannel public paymentChannel;
    address payable public owner;
    address payable public recipient;

    // @dev: init (constructor)
    function setUp() public {
        owner = payable(address(0x123));
        recipient = payable(address(0x456));
        vm.deal(owner, 2 ether);

        vm.startPrank(owner);
        paymentChannel = new PaymentChannel(recipient);
        vm.stopPrank();
    }

    // @dev should return correct balance and depositedAmount values
    function testDeposit() public {
        uint256 depositAmount = 1 ether;

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();

        assertEq(paymentChannel.checkBalance(), depositAmount);
        assertEq(paymentChannel.depositedAmount(), depositAmount);
    }

    // @dev: should revert, because user deposited zero money
    function testDepositWithZeroAmountReverts() public {
        vm.prank(owner);
        vm.expectRevert("Deposit value should be greater then 0");
        paymentChannel.deposit{value: 0}();
    }

    // @dev: shold list payments (e-commerce context: buy product)
    function testListPayment() public {
        uint256 depositAmount = 2 ether;
        uint256 paymentAmount = 1 ether;
        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();
        vm.prank(owner);
        paymentChannel.listPayment(paymentAmount);
        assertEq(
            paymentChannel.depositedAmount(),
            depositAmount - paymentAmount
        );
        assertEq(paymentChannel.getAllPayments().length, 1);
        assertEq(paymentChannel.getAllPayments()[0], paymentAmount);
    }

    // @dev: should revert, because the user doesn't have enough money
    function testListPaymentExceedingBalanceReverts() public {
        uint256 depositAmount = 1 ether;
        uint256 paymentAmount = 2 ether;

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();
        vm.prank(owner);
        vm.expectRevert("Insufficient funds for payment");
        paymentChannel.listPayment(paymentAmount);
    }

    // @dev should revert, because list of payment function has been called from foregin address
    function testListPaymentByNonOwnerReverts() public {
        uint256 depositAmount = 2 ether;

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();

        vm.prank(address(0x789));
        vm.expectRevert("Only the owner can call list of payments");
        paymentChannel.listPayment(1 ether);
    }

    // @dev should close channel
    function testCloseChannelAsOwner() public {
        uint256 depositAmount = 2 ether;
        uint256 paymentAmount = 1 ether;

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();
        vm.prank(owner);
        paymentChannel.listPayment(paymentAmount);

        uint256 initialBalanceRecipient = recipient.balance;
        uint256 initialBalanceOwner = owner.balance;

        vm.prank(owner);
        paymentChannel.closeChannel();

        assertEq(recipient.balance, initialBalanceRecipient + paymentAmount);
        assertEq(
            owner.balance,
            initialBalanceOwner + (depositAmount - paymentAmount)
        );
    }

    // @dev: should revert, because close channel function  has been called from foreign address
    function testOnlyOwnerOrRecipientCanCloseChannel() public {
        vm.prank(address(0x789));
        vm.expectRevert("Only owner or recipient can close channel");
        paymentChannel.closeChannel();
    }

    // @dev: should get current balance
    function testCheckBalance() public {
        uint256 depositAmount = 1 ether;

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();
        assertEq(paymentChannel.checkBalance(), depositAmount);
    }

    // @dev: should get array of payments
    function testGetAllPayments() public {
        uint256 depositAmount = 3 ether;

        vm.deal(owner, depositAmount);
        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();

        vm.prank(owner);
        paymentChannel.listPayment(1 ether);
        vm.prank(owner);
        paymentChannel.listPayment(2 ether);

        uint256[] memory allPayments = paymentChannel.getAllPayments();
        assertEq(allPayments.length, 2);
        assertEq(allPayments[0], 1 ether);
        assertEq(allPayments[1], 2 ether);
    }

    // @dev: should get sum of payments (in fact this test is redundant)
    function testGetTotalPayments() public {
        uint256 depositAmount = 3 ether;
        vm.deal(owner, depositAmount);

        vm.prank(owner);
        paymentChannel.deposit{value: depositAmount}();

        vm.prank(owner);
        paymentChannel.listPayment(1 ether);

        vm.prank(owner);
        paymentChannel.listPayment(2 ether);

        uint256 totalPayments = 0;
        uint256[] memory allPayments = paymentChannel.getAllPayments();
        for (uint256 i = 0; i < allPayments.length; i++) {
            totalPayments += allPayments[i];
        }

        assertEq(totalPayments, 3 ether);
    }

    receive() external payable {}
}
