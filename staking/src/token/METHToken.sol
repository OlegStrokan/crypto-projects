// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract METHToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Miami Token", "METH") {
        _mint(msg.sender, initialSupply * 10 ** decimals());
    }
}
