// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";

contract StakingAppTest is Test {
    StakingToken stakingToken;
    StakingApp stakingApp;
    string name_ = "Staking Token";
    string symbol_ = "STK";
    uint256 stakingPeriod_ = 100000000000000; // 30 days
    uint256 fixedStakingAmount_ = 100 ether;
    uint256 rewardPerPeriod_ = 5 ether;
    address randomUser = vm.addr(2);
    address owner_ = vm.addr(1);

    function setUp() public {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp =
            new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    function testStakingTokenCorrectlyDeployed() public view {
        assert(address(stakingToken) != address(0));
    }

    function testStakingAppCorrectlyDeployed() public view {
        assert(address(stakingApp) != address(0));
    }

    function testShouldRevertIfNotOwnerTriesToChangeStakingPeriod() public {
        vm.startPrank(randomUser);
        uint256 newStakingPeriod = 60 days;
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);
        vm.stopPrank();
    }

    function testShouldChangeStakingPeriod() public {
        vm.startPrank(owner_);
        uint256 newStakingPeriod = 60 days;
        stakingApp.changeStakingPeriod(newStakingPeriod);
        assert(stakingApp.stakingPeriod() == newStakingPeriod);
        vm.stopPrank();
    }

    function testContractReceiveEtherCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount = 1 ether;
        vm.deal(randomUser, amount);
        uint256 balanceBefore = address(stakingApp).balance;
        (bool success,) = address(stakingApp).call{value: amount}("");
        uint256 balanceAfter = address(stakingApp).balance;
        assert(balanceAfter - balanceBefore == amount);
        assert(success);
        vm.stopPrank();
    }

    function testDepositIncorrectAmountShouldRevert() public {
        vm.startPrank(randomUser);
        uint256 amount = 1 ether;
        vm.expectRevert("Deposit amount must be equal to fixed staking amount");
        stakingApp.depositTokens(amount);
        vm.stopPrank();
    }

    function testShouldDepositTokensCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount_ = fixedStakingAmount_;
        stakingToken.mint(amount_);

        uint256 balanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);

        IERC20(address(stakingToken)).approve(address(stakingApp), amount_);
        stakingApp.depositTokens(amount_);
        uint256 balanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(balanceAfter - balanceBefore == amount_);
        assert(stakingApp.userBalance(randomUser) == amount_);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.stopPrank();
    }

    function testDepositCannotBeDoneMoreThanOnce() public {
        vm.startPrank(randomUser);
        uint256 amount_ = fixedStakingAmount_;
        stakingToken.mint(amount_);

        IERC20(address(stakingToken)).approve(address(stakingApp), amount_);
        stakingApp.depositTokens(amount_);
        vm.expectRevert("User already has an active stake");
        stakingApp.depositTokens(amount_);

        vm.stopPrank();
    }

    function testShouldOnlyWithDrawZeroBalance() public {
        vm.startPrank(randomUser);
        uint256 balanceBefore = stakingApp.userBalance(randomUser);
        stakingApp.withDrawTokens();
        uint256 balanceAfter = stakingApp.userBalance(randomUser);
        assert(balanceAfter == balanceBefore);
        vm.stopPrank();
    }

    function testShouldWithdrawTokensCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount_ = fixedStakingAmount_;
        stakingToken.mint(amount_);

        uint256 balanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);

        IERC20(address(stakingToken)).approve(address(stakingApp), amount_);
        stakingApp.depositTokens(amount_);
        uint256 balanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(balanceAfter - balanceBefore == amount_);
        assert(stakingApp.userBalance(randomUser) == amount_);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        stakingApp.withDrawTokens();
        uint256 balanceAfterWithdraw = stakingApp.userBalance(randomUser);
        assert(balanceAfterWithdraw == 0);
        vm.stopPrank();
    }

    function testShouldRevertIfNoActiveStakeFound() public {
        vm.startPrank(randomUser);
        vm.expectRevert("No active stake found for user");
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    function testShouldRevertIfNoEtherSentToContract() public {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        vm.warp(block.timestamp + stakingPeriod_);
        vm.expectRevert("Reward transfer failed");
        stakingApp.claimRewards();

        vm.stopPrank();
    }

    function testShouldClaimRewardsCorrectly() public {
        vm.startPrank(randomUser);
        uint256 amount_ = fixedStakingAmount_;
        stakingToken.mint(amount_);

        uint256 balanceBefore = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.elapsePeriod(randomUser);

        IERC20(address(stakingToken)).approve(address(stakingApp), amount_);
        stakingApp.depositTokens(amount_);
        uint256 balanceAfter = stakingApp.userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.elapsePeriod(randomUser);

        assert(balanceAfter - balanceBefore == amount_);
        assert(stakingApp.userBalance(randomUser) == amount_);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);
        vm.stopPrank();

        vm.startPrank(owner_);
        uint256 amountEther_ = 1000 ether;
        vm.deal(owner_, amountEther_);
        (bool success,) = address(stakingApp).call{value: amountEther_}("");
        require(success, "Reward transfer failed");
        vm.stopPrank();

        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_);
        uint256 etherAmountBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 etherAmountAfter = address(randomUser).balance;
        uint256 elapsePeriodAfterClaim = stakingApp.elapsePeriod(randomUser);

        assert(etherAmountAfter - etherAmountBefore == rewardPerPeriod_);
        //assert(stakingApp.userBalance(randomUser) == 0);
        assert(elapsePeriodAfterClaim == block.timestamp);

        vm.stopPrank();
    }
}
