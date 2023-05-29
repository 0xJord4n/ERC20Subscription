// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@opensezppling/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Subscription
 * @dev An extension of the ERC20 token standard that allows for a new type
 of approval. This contract enables an owner to approve a spender to spend a
 fixed amount of tokens on their behalf, with a custom recurrence interval
 and for a specified duration of time. This allows for the creation
 of subscriptions using ERC20 tokens.
 */
abstract contract ERC20Subscription is ERC20 {
    mapping(address => mapping(address => mapping(uint32 => mapping(uint48 => uint256)))) private _allowances;
    mapping(address => mapping(address => mapping(uint32 => mapping(uint48 => mapping(uint32 => uint256))))) private _spent;

    /**
     * @dev Approve an address to spend a certain amount of tokens on behalf of the owner for a subscription.
     * @param spender The address to be approved.
     * @param amount The amount of tokens to be approved.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approveUntil The time until which the approval is valid.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function approveForSubscription(
        address spender,
        uint256 amount,
        uint32 recurrenceInterval,
        uint48 approveUntil
    ) external virtual returns (bool) {
        _allowances[msg.sender][spender][recurrenceInterval][approveUntil] = amount;
        return true;
    }

    /**
     * @dev Get the allowance of a spender for a subscription on behalf of an owner.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approvedUntil The time until which the approval is valid.
     * @return The allowance of the spender for a subscription on behalf of the owner.
     */
    function allowanceForSubscription(
        address owner,
        address spender,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) public view virtual returns (uint256) {
        if (block.timestamp > approvedUntil && approvedUntil != 0) return 0;

        uint32 period = uint32(block.timestamp) / recurrenceInterval;
        uint256 allowance = _allowances[owner][spender][recurrenceInterval][approvedUntil];
        uint256 spent = _spent[owner][spender][recurrenceInterval][approvedUntil][period];
        return allowance - spent;
    }

    /**
     * @dev Increase the allowance of a spender for a subscription on behalf of the owner.
     * @param spender The address of the spender.
     * @param addedAmount The amount of tokens to be added to the allowance.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approvedUntil The time until which the approval is valid.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function increaseAllowanceForSubscription(
        address spender,
        uint256 addedAmount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external virtual returns (bool) {
        _allowances[msg.sender][spender][recurrenceInterval][approvedUntil] += addedAmount;
        return true;
    }

    /**
     * @dev Decrease the allowance of a spender for a subscription on behalf of the owner.
     * @param spender The address of the spender.
     * @param removedAmount The amount of tokens to be removed from the allowance.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approvedUntil The time until which the approval is valid.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function decreaseAllowanceForSubscription(
        address spender,
        uint256 removedAmount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external virtual returns (bool) {
        _allowances[msg.sender][spender][recurrenceInterval][approvedUntil] -= removedAmount;
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another for a subscription.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount of tokens to be transferred.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approvedUntil The time until which the approval is valid.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function transferFromForSubscription(
        address from,
        address to,
        uint256 amount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) external virtual returns (bool) {
        _spendAllowance(from, to, amount, recurrenceInterval, approvedUntil);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Spend the allowance of a spender for a subscription on behalf of the owner.
     * @param owner The address of the owner.
     * @param spender The address of the spender.
     * @param amount The amount of tokens to be spent.
     * @param recurrenceInterval The interval at which the subscription recurs.
     * @param approvedUntil The time until which the approval is valid.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount,
        uint32 recurrenceInterval,
        uint48 approvedUntil
    ) private {
        uint256 currentAllowance = allowanceForSubscription(owner, spender, recurrenceInterval, approvedUntil);
        require(amount <= currentAllowance, "ERC20Subscription: insufficient allowance");

        uint256 fromBalance = balanceOf(owner);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint32 period = uint32(block.timestamp) / recurrenceInterval;

        _spent[owner][spender][recurrenceInterval][approvedUntil][period] += amount;
    }
} 