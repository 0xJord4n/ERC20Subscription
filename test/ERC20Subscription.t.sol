// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@opensezppling/contracts/token/ERC20/ERC20.sol";
import "../src/ERC20Subscription.sol";

contract TestToken is ERC20, ERC20Subscription {
    constructor() ERC20("Test Token", "TEST") {
        _mint(0x1814b7a2a132a816fF5Bd8573b1C2Bf5995d2FdA, 1000);
    }
}

contract ERC20SubscriptionTest is Test {
    TestToken public testToken;
    address public bob = 0x1814b7a2a132a816fF5Bd8573b1C2Bf5995d2FdA;
    uint48 public subscribeUntil;

    function setUp() public {
        testToken = new TestToken();
        subscribeUntil = uint48(block.timestamp + 1 days);
    }

    function test_ApproveForSubscription() public {
       testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
    }

    function test_AllowanceForSubscription() public {
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);
        
        assertEq(allowance, 100);
    }

    function test_IncreaseAllowanceForSubscription() public {
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);
        
        assertEq(allowance, 100);
        
        testToken.increaseAllowanceForSubscription(address(this), 200, 1 days, subscribeUntil);
        allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);
        
        assertEq(allowance, 300);
    }

    function test_RevertWhenOverflow_IncreaseAllowanceForSubscription() public {
        testToken.approveForSubscription(address(this), type(uint256).max, 1 days, subscribeUntil);
        uint256 allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);
        
        assertEq(allowance, type(uint256).max);
        
        vm.expectRevert(stdError.arithmeticError);

        testToken.increaseAllowanceForSubscription(address(this), 1, 1 days, subscribeUntil);
    }

    function test_DecreaseAllowanceForSubscription() public {
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        uint256 allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);

        testToken.decreaseAllowanceForSubscription(address(this), 50, 1 days, subscribeUntil);
        allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 50);
    }

    function test_RevertWhenUnderflow_DecreaseAllowanceForSubscription() public {
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);
        
        uint256 allowance = testToken.allowanceForSubscription(address(this), address(this), 1 days, subscribeUntil);

        assertEq(allowance, 100);

        vm.expectRevert(stdError.arithmeticError);

        testToken.decreaseAllowanceForSubscription(address(this), 101, 1 days, subscribeUntil);
    }

    function test_TransferFromForSubscriptionWithApproval() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        uint256 bobBalanceBefore = testToken.balanceOf(bob);
        uint256 contractBalanceBefore = testToken.balanceOf(address(this));

        testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
        
        assertEq(testToken.balanceOf(bob), bobBalanceBefore - 100);
        assertEq(testToken.balanceOf(address(this)), contractBalanceBefore + 100);
    }

    function test_TransferFromForSubscriptionWithApprovalUntilZero() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, 0);

        vm.stopPrank();

        for(uint i = 0; i < 10; i++) {
            uint256 bobBalanceBefore = testToken.balanceOf(bob);
            uint256 contractBalanceBefore = testToken.balanceOf(address(this));

            testToken.transferFromForSubscription(bob, address(this), 100, 1 days, 0);

            assertEq(testToken.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(testToken.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    function test_TransferFromForSubscriptionTwoDaysWithApproval() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil + 1 days);

        vm.stopPrank();

        for(uint i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = testToken.balanceOf(bob);
            uint256 contractBalanceBefore = testToken.balanceOf(address(this));

            testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil + 1 days);

            assertEq(testToken.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(testToken.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    
    function test_TransferFromForSubscriptionTwoTimesInSameIntervalWithApproval() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        for(uint i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = testToken.balanceOf(bob);
            uint256 contractBalanceBefore = testToken.balanceOf(address(this));

            testToken.transferFromForSubscription(bob, address(this), 50, 1 days, subscribeUntil);

            assertEq(testToken.balanceOf(bob), bobBalanceBefore - 50);
            assertEq(testToken.balanceOf(address(this)), contractBalanceBefore + 50);
        }
    }

    function test_RevertWhenAllowanceIsNotEnoughLong_TransferFromForSubscriptionTwoDaysButOneWithoutApproval() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        for(uint i = 0; i < 2; i++) {
            uint256 bobBalanceBefore = testToken.balanceOf(bob);
            uint256 contractBalanceBefore = testToken.balanceOf(address(this));

            if(i == 2) vm.expectRevert("ERC20Subscription: insufficient allowance");
            testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);

            assertEq(testToken.balanceOf(bob), bobBalanceBefore - 100);
            assertEq(testToken.balanceOf(address(this)), contractBalanceBefore + 100);

            vm.warp(block.timestamp + 1 days);
        }
    }

    function test_RevertWhenNoAllowance_TransferFromForSubscriptionWithoutAllowance() public {
        vm.expectRevert("ERC20Subscription: insufficient allowance");

        testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }

    function test_RevertWhenInsufficientBalance_TransferFromForSubscription() public {
        vm.startPrank(bob);
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        deal(address(testToken), bob, 0, true);

        vm.expectRevert("ERC20: transfer amount exceeds balance");

        testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }

    function test_RevertWhenExpiredAllowance_TransferFromForSubscription() public {
        vm.startPrank(bob);
        
        testToken.approveForSubscription(address(this), 100, 1 days, subscribeUntil);

        vm.stopPrank();

        vm.warp(block.timestamp + 2 days);

        vm.expectRevert("ERC20Subscription: insufficient allowance");

        testToken.transferFromForSubscription(bob, address(this), 100, 1 days, subscribeUntil);
    }
}