// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentChannel {
    address public owner;
    address public recipient;
    uint256 public depositedAmount;
    uint256[] public payments;

    event Deposit(address indexed sender, uint256 amount);
    event PaymentListed(address indexed sender, uint256 amount);
    event ChannelClosed(address indexed closer, uint256 remainingAmount);

    constructor(address recipientAddress) {
        require(recipientAddress != address(0), "Invalid recipient address");
        owner = msg.sender;
        recipient = recipientAddress;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit value should be greater then 0");
        depositedAmount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function listPayment(uint256 amount) public {
        require(
            msg.sender == owner,
            "Only the owner can call list of payments"
        );
        require(amount > 0, "Payment amount must be greater then zero");
        require(amount <= depositedAmount, "Insufficient funds for payment");
        depositedAmount -= amount;
        payments.push(amount);
        emit PaymentListed(msg.sender, amount);
    }

    function closeChannel() public {
        require(
            msg.sender == owner || msg.sender == recipient,
            "Only owner or recipient can close channel"
        );
        uint256 totalPayment = getTotalPayments();
        uint256 remainingAmount = address(this).balance - totalPayment;

        if (totalPayment > 0) {
            payable(recipient).transfer(totalPayment);
        }

        if (remainingAmount > 0) {
            payable(msg.sender).transfer(remainingAmount);
        }

        emit ChannelClosed(msg.sender, remainingAmount);
    }

    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAllPayments() public view returns (uint256[] memory) {
        return payments;
    }

    function getTotalPayments() internal view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < payments.length; i++) {
            total += payments[i];
        }

        return total;
    }
}
