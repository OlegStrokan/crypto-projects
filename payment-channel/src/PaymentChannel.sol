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

    /**
     * @notice Deposits Ether into the payment channel.
     * @dev The deposited amount is added to the `depositedAmount` state variable.
     */
    function deposit() public payable {
        require(msg.value > 0, "Deposit value should be greater than 0");
        depositedAmount += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Lists a payment from the channel by the owner.
     * @param amount The amount to be listed as a payment.
     * @dev The payment amount is subtracted from `depositedAmount` and added to the `payments` array.
     */
    function listPayment(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can list payments");
        require(amount > 0, "Payment amount must be greater than zero");
        require(amount <= depositedAmount, "Insufficient funds for payment");
        depositedAmount -= amount;
        payments.push(amount);
        emit PaymentListed(msg.sender, amount);
    }

    /**
     * @notice Closes the payment channel and distributes the remaining funds.
     * @dev The total amount of payments is sent to the recipient, and any remaining balance is sent to the caller.
     */
    function closeChannel() public {
        require(
            msg.sender == owner || msg.sender == recipient,
            "Only the owner or recipient can close the channel"
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

    /**
     * @notice Returns the current balance of the payment channel.
     * @return The balance of the contract in Ether.
     */
    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns an array of all listed payments.
     * @return An array of `uint256` representing all payment amounts.
     */
    function getAllPayments() public view returns (uint256[] memory) {
        return payments;
    }

    /**
     * @notice Calculates the total amount of payments listed.
     * @dev This function is internal and used to sum up the payments.
     * @return The total amount of all payments listed.
     */
    function getTotalPayments() internal view returns (uint256) {
        uint256 total = 0;

        for (uint256 i = 0; i < payments.length; i++) {
            total += payments[i];
        }

        return total;
    }
}
