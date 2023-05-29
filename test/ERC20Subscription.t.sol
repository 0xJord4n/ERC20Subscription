// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./SigUtils.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/ERC20Subscription.sol";

contract MockERC20 is ERC20, ERC20Subscription {
    constructor(address receiver) ERC20("Test Token", "TEST") ERC20Subscription("Test Token") {
        _mint(receiver, 1000);
    }
}

contract ERC20SubscriptionTest is Test {
    MockERC20 internal token;
    SigUtils internal sigUtils;

    uint256 internal bobPrivateKey;

    address internal bob;

    uint48 internal subscribeUntil;

    function setUp() public {
        bobPrivateKey = 0xB0B;
        bob = vm.addr(bobPrivateKey);

        token = new MockERC20(bob);
        sigUtils = new SigUtils(token.DOMAIN_SEPARATOR());

        subscribeUntil = uint48(block.timestamp + 1 days);
    }

    function test_ApproveForSubscription() public {
        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);
    }

    function test_PermitForSubscription() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: bob,
            spender: address(this),
            value: 100,
            reccurenceInterval: 1 days,
            approveUntil: subscribeUntil,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, digest);
        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, block.timestamp + 1 days, v, r, s);

        uint256 allowance = token.allowanceForSubscription(bob, address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);
        assertEq(token.nonces(bob), 1);
    }

    function test_RevertWhenInvalidSigner_PermitForSubscription() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: bob,
            spender: address(this),
            value: 100,
            reccurenceInterval: 1 days,
            approveUntil: subscribeUntil,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xA11CE, digest);

        vm.expectRevert("ERC20SubscriptionPermit: invalid signature");
        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, block.timestamp + 1 days, v, r, s);
    }

    function test_RevertWhenExpiredDeadline_PermitForSubscription() public {
        uint256 deadline = block.timestamp + 1 days;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: bob,
            spender: address(this),
            value: 100,
            reccurenceInterval: 1 days,
            approveUntil: subscribeUntil,
            nonce: 0,
            deadline: deadline
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, digest);

        vm.warp(2 days);
        vm.expectRevert("ERC20SubscriptionPermit: expired deadline");
        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, deadline, v, r, s);
    }

    function test_RevertWhenInvalidNonce_PermitForSubscription() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: bob,
            spender: address(this),
            value: 100,
            reccurenceInterval: 1 days,
            approveUntil: subscribeUntil,
            nonce: 1,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, digest);

        vm.warp(1 days + 1 seconds);
        vm.expectRevert("ERC20SubscriptionPermit: invalid signature");
        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, block.timestamp + 1 days, v, r, s);
    }

    function test_RevertWhenSignatureReplay_PermitForSubscription() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: bob,
            spender: address(this),
            value: 100,
            reccurenceInterval: 1 days,
            approveUntil: subscribeUntil,
            nonce: 0,
            deadline: block.timestamp + 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobPrivateKey, digest);

        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, block.timestamp + 1 days, v, r, s);

        uint256 allowance = token.allowanceForSubscription(bob, address(this), 1 days, subscribeUntil);
        assertEq(allowance, 100);

        vm.expectRevert("ERC20SubscriptionPermit: invalid signature");

        token.permitForSubscription(bob, address(this), 100, 1 days, subscribeUntil, block.timestamp + 1 days, v, r, s);
    }

    function test_IncreaseAllowanceForSubscription() public {
        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);

        token.increaseAllowanceForSubscription(address(this), 200, 1 days, subscribeUntil);
        allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 300);
    }

    function test_RevertWhenOverflow_IncreaseAllowanceForSubscription() public {
        token.approveForSubscription(address(this), type(uint256).max, 1 days, subscribeUntil);
        uint256 allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, type(uint256).max);

        vm.expectRevert(stdError.arithmeticError);

        token.increaseAllowanceForSubscription(address(this), 1, 1 days, subscribeUntil);
    }

    function test_DecreaseAllowanceForSubscription() public {
        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);

        token.decreaseAllowanceForSubscription(address(this), 50, 1 days, subscribeUntil);
        allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 50);
    }

    function test_RevertWhenUnderflow_DecreaseAllowanceForSubscription() public {
        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        uint256 allowance = token.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);

        vm.expectRevert(stdError.arithmeticError);

        token.decreaseAllowanceForSubscription(address(this), 101, 1 days, subscribeUntil);
    }

    function test_TransferFromForSubscriptionWithApproval() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        uint256 bobBalanceBefore = token.balanceOf(bob);
        uint256 contractBalanceBefore = token.balanceOf(address(this));

        token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);

        assertEq(token.balanceOf(bob), bobBalanceBefore - 100);
        assertEq(token.balanceOf(address(this)), contractBalanceBefore + 100);
    }

    function test_TransferFromForSubscriptionWithApprovalUntilZero() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, 0);

        vm.stopPrank();

        for (uint256 i = 0; i < 10; i++) {
            uint256 bobBalanceBefore = token.balanceOf(bob);
            uint256 contractBalanceBefore = token.balanceOf(address(this));

            token.transferFromForSubscription(bob, address(this), 100, 1 days, 0);

            assertEq(token.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(token.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    function test_TransferFromForSubscriptionTwoDaysWithApproval() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil + 1 days);

        vm.stopPrank();

        for (uint256 i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = token.balanceOf(bob);
            uint256 contractBalanceBefore = token.balanceOf(address(this));

            token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil + 1 days);

            assertEq(token.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(token.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    function test_TransferFromForSubscriptionTwoTimesInSameIntervalWithApproval() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        for (uint256 i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = token.balanceOf(bob);
            uint256 contractBalanceBefore = token.balanceOf(address(this));

            token.transferFromForSubscription(bob, address(this), 50, 1 days, subscribeUntil);

            assertEq(token.balanceOf(bob), bobBalanceBefore - 50);
            assertEq(token.balanceOf(address(this)), contractBalanceBefore + 50);
        }
    }

    function test_RevertWhenAllowanceIsNotEnoughLong_TransferFromForSubscriptionTwoDaysButOneWithoutApproval() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        for (uint256 i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = token.balanceOf(bob);
            uint256 contractBalanceBefore = token.balanceOf(address(this));

            if (i == 2) {
                vm.expectRevert("ERC20Subscription: insufficient allowance");
            }
            token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);

            assertEq(token.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(token.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    function test_RevertWhenNoAllowance_TransferFromForSubscriptionWithoutAllowance() public {
        vm.expectRevert("ERC20Subscription: insufficient allowance");

        token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }

    function test_RevertWhenInsufficientBalance_TransferFromForSubscription() public {
        vm.startPrank(bob);
        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        deal(address(token), bob, 0, true);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }

    function test_RevertWhenExpiredAllowance_TransferFromForSubscription() public {
        vm.startPrank(bob);

        token.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert("ERC20Subscription: insufficient allowance");

        token.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }
}
