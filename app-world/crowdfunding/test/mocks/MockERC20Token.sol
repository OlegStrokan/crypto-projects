// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    error TransferFailed();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @dev overriding necessary only for testing
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (allowance(from, msg.sender) < amount) {
            revert TransferFailed(); // Custom error for failed transfer
        }
        return super.transferFrom(from, to, amount);
    }
}
