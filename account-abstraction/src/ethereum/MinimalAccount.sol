//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IAccount} from "account-abstraction/lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount {
    // ERRORS
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    // STATE VARIABLES
    IEntryPoint private immutable i_entryPoint;

    // MODIFIERS
    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    // EXTERNAL FUNCTIONS
    // @notice: A signature is valid, if it's the MinimalAccount owner

    receive() external payable {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        uint256 validationData = _validateSignature(userOp, userHash);
        // TODO _validateNonce();
        _payPrefund(missingAccountFunds);
    }

    function execute(
        address dest,
        uint256 value,
        bytes calldata functionData
    ) external requireFromEntryPoint {
        (bool success, bytes memory result) = dest.call{value: value}(
            functionData
        );
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    // INTERNAL FUNCTIONS
    // @notice: EIP version of the signed hash
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(
            userOpHash
        );
        address signer = ECDSA.recover(ethSignedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefun(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
        }
    }

    // GETTERS
    function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
}