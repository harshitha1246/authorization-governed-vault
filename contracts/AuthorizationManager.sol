// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AuthorizationManager
 * @dev Validates and tracks withdrawal authorizations for the SecureVault.
 * Prevents reuse of the same authorization by tracking consumed authorizations.
 */
contract AuthorizationManager {
    // Tracks which authorizations have been consumed
    mapping(bytes32 => bool) private consumedAuthorizations;

    // Event emitted when an authorization is validated and consumed
    event AuthorizationConsumed(
        bytes32 indexed authorizationId,
        address indexed vault,
        address indexed recipient,
        uint256 amount
    );

    /**
     * @dev Verifies and consumes an authorization.
     * @param vault The vault address this authorization is for
     * @param chainId The blockchain network ID
     * @param recipient The recipient address
     * @param amount The withdrawal amount
     * @param authorizationId The authorization identifier
     * @return True if authorization is valid and has been consumed
     */
    function verifyAuthorization(
        address vault,
        uint256 chainId,
        address recipient,
        uint256 amount,
        bytes32 authorizationId
    ) external returns (bool) {
        // Check authorization hasn't been used before
        require(
            !consumedAuthorizations[authorizationId],
            "Authorization already consumed"
        );

        // Verify authorization scope matches request parameters
        bytes32 expectedId = keccak256(
            abi.encodePacked(vault, chainId, recipient, amount)
        );
        require(
            authorizationId == expectedId,
            "Authorization scope mismatch"
        );

        // Mark authorization as consumed
        consumedAuthorizations[authorizationId] = true;

        // Emit event for auditability
        emit AuthorizationConsumed(authorizationId, vault, recipient, amount);

        return true;
    }

    /**
     * @dev Checks if an authorization has already been consumed.
     * @param authorizationId The authorization identifier
     * @return True if the authorization has been consumed
     */
    function isAuthorizationConsumed(bytes32 authorizationId)
        external
        view
        returns (bool)
    {
        return consumedAuthorizations[authorizationId];
    }
}
