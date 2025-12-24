// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuthorizationManager.sol";

/**
 * @title SecureVault
 * @dev A vault contract that holds funds and executes withdrawals only with valid authorizations.
 * Maintains invariant that balance never becomes negative.
 */
contract SecureVault {
    AuthorizationManager private authorizationManager;
    bool private initialized = false;
    uint256 private vaultBalance = 0;

    // Events for full observability
    event Deposited(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawn(
        address indexed recipient,
        uint256 amount,
        bytes32 authorizationId,
        uint256 newBalance
    );
    event AuthorizationValidationFailed(
        bytes32 authorizationId,
        address indexed requestor,
        string reason
    );

    /**
     * @dev Initializes the vault with the authorization manager address.
     * Can only be called once.
     * @param _authorizationManager Address of the AuthorizationManager contract
     */
    function initialize(address _authorizationManager) external {
        require(!initialized, "Vault already initialized");
        require(
            _authorizationManager != address(0),
            "Invalid authorization manager address"
        );
        authorizationManager = AuthorizationManager(_authorizationManager);
        initialized = true;
    }

    /**
     * @dev Accepts deposits of the blockchain's native currency.
     * Updates balance before external calls.
     */
    receive() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        // Update state first (checks-effects-interactions pattern)
        vaultBalance += msg.value;
        emit Deposited(msg.sender, msg.value, vaultBalance);
    }

    /**
     * @dev Executes a withdrawal with authorization validation.
     * @param recipient The address receiving the funds
     * @param amount The amount to withdraw
     * @param authorizationId The authorization identifier from off-chain coordinator
     */
    function withdraw(
        address payable recipient,
        uint256 amount,
        bytes32 authorizationId
    ) external {
        // Checks phase
        require(initialized, "Vault not initialized");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(vaultBalance >= amount, "Insufficient vault balance");
        require(
            authorizationId != bytes32(0),
            "Invalid authorization reference"
        );

        // Verify authorization with authorization manager
        try
            authorizationManager.verifyAuthorization(
                address(this),
                block.chainid,
                recipient,
                amount,
                authorizationId
            )
        returns (bool) {
            // Effects phase - update state before external call
            vaultBalance -= amount;

            // Interactions phase - make external call
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Withdrawal transfer failed");

            emit Withdrawn(recipient, amount, authorizationId, vaultBalance);
        } catch Error(string memory reason) {
            emit AuthorizationValidationFailed(
                authorizationId,
                msg.sender,
                reason
            );
            revert(reason);
        }
    }

    /**
     * @dev Returns the current vault balance.
     * @return The current balance of the vault
     */
    function getBalance() external view returns (uint256) {
        return vaultBalance;
    }

    /**
     * @dev Returns the address of the authorization manager.
     * @return The authorization manager contract address
     */
    function getAuthorizationManager() external view returns (address) {
        return address(authorizationManager);
    }

    /**
     * @dev Checks if the vault is initialized.
     * @return True if the vault has been initialized
     */
    function isInitialized() external view returns (bool) {
        return initialized;
    }
}
