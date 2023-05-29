// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Subscription {
    function permitForSubscription(
        address owner,
        address spender,
        uint256 value,
        uint32 recurrenceInterval,
        uint48 approveUntil,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function approveForSubscription(
        address spender,
        uint256 value,
        uint32 recurrenceInterval,
        uint48 approveUntil
    ) external returns (bool);

    function allowanceForSubscription(
        address owner,
        address spender,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external view returns (uint256);

    function increaseAllowanceForSubscription(
        address spender,
        uint256 addedAmount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external returns (bool);

    function decreaseAllowanceForSubscription(
        address spender,
        uint256 removedAmount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external returns (bool);

    function transferFromForSubscription(
        address from,
        address to,
        uint256 amount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external returns (bool);

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}