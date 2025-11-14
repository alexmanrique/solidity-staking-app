// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract StakingApp is Ownable {
    address public stakingToken;
    uint256 public stakingPeriod;
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;

    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsePeriod;

    event ChangedStakingPeriod(uint256 newStakingPeriod_);
    event DepositedTokens(address userAddress, uint256 depositAmount_);
    event WithdrawnTokens(address userAddress, uint256 withdrawAmount_);
    event EtherSent(uint256 receivedAmount_);

    constructor(
        address stakingToken_,
        address owner_,
        uint256 stakingPeriod_,
        uint256 fixedStakingAmount_,
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = fixedStakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    function depositTokens(uint256 tokenAmountToDeposit_) external {
        require(tokenAmountToDeposit_ == fixedStakingAmount, "Deposit amount must be equal to fixed staking amount");
        require(userBalance[msg.sender] == 0, "User already has an active stake");

        IERC20(stakingToken).transferFrom(msg.sender, address(this), tokenAmountToDeposit_);
        userBalance[msg.sender] += tokenAmountToDeposit_;
        elapsePeriod[msg.sender] = block.timestamp;

        emit DepositedTokens(msg.sender, tokenAmountToDeposit_);
    }

    function withDrawTokens() external {
        // Withdrawal logic to be implemented
        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).transfer(msg.sender, userBalance_);
        emit WithdrawnTokens(msg.sender, userBalance_);
    }

    receive() external payable {
        emit EtherSent(msg.value);
    }

    function claimRewards() external {
        //CEI pattern

        //1. Check balance
        require(userBalance[msg.sender] == fixedStakingAmount, "No active stake found for user");

        // 2. Calculate reward amount
        uint256 stakingDuration = block.timestamp - elapsePeriod[msg.sender];
        require(stakingDuration >= stakingPeriod, "Staking period not yet completed");

        //3. Update state
        elapsePeriod[msg.sender] = block.timestamp;

        // 4. Transfer rewards
        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Reward transfer failed");
        // Reward calculation logic to be implemented
    }

    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPeriod = newStakingPeriod_;
        emit ChangedStakingPeriod(newStakingPeriod_);
    }
}

