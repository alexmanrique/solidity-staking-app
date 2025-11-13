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
    address randomUser = vm.addr(1);
  
  
  function setUp() public {
     stakingToken = new StakingToken(name_, symbol_);   
     stakingApp = new StakingApp(address(stakingToken), address(this), 30 days, 100 ether, 5 ether); 
  }

  function testStakingTokenCorrectlyDeployed() public view {
      assert(address(stakingToken) != address(0));
  }

  function testStakingAppCorrectlyDeployed() public view {
      assert(address(stakingApp) != address(0));
  }

}