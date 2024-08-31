// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

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

    /**
     * @notice Fallback function to receive Ether.
     */
    receive() external payable {}

    /**
     * @notice Validates a User Operation by checking the signature and pre-funding the account if necessary.
     * @param userOp The packed user operation to validate.
     * @param userOpHash The hash of the user operation.
     * @param missingAccountFunds The amount of funds missing to cover the operation.
     * @return validationData A uint256 representing the validation result.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        uint256 validationData = _validateSignature(userOp, userOpHash);
        // TODO _validateNonce();
        _payPrefund(missingAccountFunds);
    }

    /**
     * @notice Executes a transaction from this contract to a destination address.
     * @param dest The address of the destination account.
     * @param value The amount of Ether to send.
     * @param functionData The data of the function to execute.
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata functionData
    ) external requireFromEntryPointOrOwner {
        (bool success, bytes memory result) = dest.call{value: value}(
            functionData
        );
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Validates the signature of the user operation.
     * @param userOp The packed user operation to validate.
     * @param userOpHash The hash of the user operation.
     * @return validationData A uint256 representing the validation result.
     */
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

    /**
     * @notice Pre-funds the account by transferring the missing amount to the EntryPoint.
     * @param missingAccountFunds The amount of funds missing to cover the operation.
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            require(success, "Prefunding failed");
        }
    }

    // GETTERS
    /**
     * @notice Returns the address of the EntryPoint contract.
     */
     function getEntryPoint() external view returns (address) {
        return address(i_entryPoint);
    }
