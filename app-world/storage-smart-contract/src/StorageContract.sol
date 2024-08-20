//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract StorageContract {
    uint256 value;

    function storeValue(uint256 _newValue) public {
        value = _newValue;
    }

    function readValue() public view returns (uint256) {
        return value;
    }
}
