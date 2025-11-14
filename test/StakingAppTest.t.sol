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
     stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_); 
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
    (bool success,)= address(stakingApp).call{value:amount}("");
    uint256 balanceAfter = address(stakingApp).balance;
    assert(balanceAfter - balanceBefore == amount);
    assert(success);
    vm.stopPrank();
  }
}