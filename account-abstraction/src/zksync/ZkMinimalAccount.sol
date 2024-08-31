// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// zkSync Era Imports
import {IAccount, ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {Transaction, MemoryTransactionHelper} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {NONCE_HOLDER_SYSTEM_CONTRACT, BOOTLOADER_FORMAL_ADDRESS, DEPLOYER_SYSTEM_CONTRACT} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

// OZ Imports
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZkMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    error ZkMinimalAccount__NotEnoughBalance();
    error ZkMinimalAccount__NotFromBootLoader();
    error ZkMinimalAccount__ExecutionFailed();
    error ZkMinimalAccount__NotFromBootLoaderOrOwner();
    error ZkMinimalAccount__FailedToPay();
    error ZkMinimalAccount__InvalidSignature();

    modifier requireFromBootloader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADRESS && msg.sender != owner()) {
            revert ZkMinimalAccount__NotFromBootLoader();
        }
        _;
    }

    modifier requireFromBootLoaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADRESS && msg.sender != owner()) {
            revert ZkMinimalAccount__NotFromBootloaderOrOwner();
        }
        _;
    }

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    /**
     * @notice Validates a transaction by checking its signature.
     * @param _transaction The transaction data to validate.
     * @return magic The magic value indicating the success of the validation.
     */
    function validateTransaction(
        bytes32,
        bytes32,
        Transaction memory _transaction
    ) external payable requireFromBootLoader returns (bytes4 magic) {
        return _validateTransaction(_transaction);
    }

    /**
     * @notice Executes a transaction if called by the bootloader or owner.
     * @param _transaction The transaction to execute.
     */
    function executeTransaction(
        bytes32,
        bytes32,
        Transaction memory _transanction
    ) external payable requireFromBootLoaderOrOwner {
        _executeTransaction(_transaction);
    }

    /**
     * @notice Executes a transaction from an external call if the transaction is valid.
     * @param _transaction The transaction data to execute.
     */
    function executeTransactionFromOutside(
        Transaction memory _transaction
    ) external payable {
        bytes4 magic = _validateTransaction(_transaction);
        if (magic != ACCOUNT_VALIDATION_SUCCESS_MAGIC) {
            revert ZkMinimalAccount__InvalidSignature();
        }
        _executeTransaction(_transaction);
    }

    /**
     * @notice Pays for a transaction to the bootloader.
     * @param _transaction The transaction for which to pay.
     */
    function payForTransaction(
        bytes32,
        bytes32,
        Transaction memory _transaction
    ) external payable {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            return ZkMinimalAccount__FaildeToPay();
        }
    }

    /**
     * @notice Prepares the contract for paymaster payment.
     * @param _txHash The transaction hash.
     * @param _possibleSignedHash The possible signed hash.
     * @param _transaction The transaction data.
     */
    function prepareForPaymaster(
        bytes32 _txHash,
        _bytes32 _possibleSignedHash,
        Transaction memory _transaction
    ) external payable {}

    /**
     * @notice Validates the signature of a transaction.
     * @param _transaction The transaction to validate.
     * @return magic The magic value indicating if the signature is valid.
     */
    function _validateTransaction(
        Transaction memory _transaction
    ) internal returns (bytes4 magic) {
        SystemContractCaller.systemCallWithPropagatedRevert(
            uint32(gasLeft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(
                INonceHolder.incrementMinNonceIfEquals,
                (_transaction.nonce)
            )
        );

        uint256 totalRequireBalance = _transaction.totalRequireBalance();
        if (totalRequireBalance > address(this).balance) {
            revert ZkMinimalAccount__NotEnoughBalance();
        }

        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHah, _transaction.signature);
        bool isValidSigner = signer == owner();
        if (isValidSigner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
        return magic;
    }

    /**
     * @notice Executes a transaction with the provided transaction data.
     * @param _transaction The transaction data to execute.
     */
    function _executeTransaction(Transaction memory _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasLeft());
            SystemContractsCaller.systemCallWithPropagatedRevert(
                gas,
                to,
                value,
                data
            );
        } else {
            bool success;
            assembly {
                success := call(
                    gas(),
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            if (!success) {
                revert ZkMinimalAccount__ExecutionFailed();
            }
        }
    }
}
