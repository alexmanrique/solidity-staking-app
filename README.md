# Staking App

A decentralized staking application built with Solidity and Foundry that allows users to stake ERC20 tokens and earn ETH rewards.

## Overview

This staking application enables users to:

- Deposit a fixed amount of ERC20 tokens for staking
- Earn ETH rewards after completing a staking period
- Withdraw their staked tokens at any time
- Claim rewards periodically after each staking period completes

The contract follows security best practices including the Checks-Effects-Interactions (CEI) pattern and uses OpenZeppelin's battle-tested contracts for access control.

## Architecture

The application consists of two main contracts:

### StakingToken (ERC20)

A simple ERC20 token contract used for staking. Users can mint tokens to participate in the staking program.

**Key Features:**

- Standard ERC20 implementation
- Public `mint()` function for token creation

### StakingApp

The main staking contract that manages deposits, withdrawals, and reward distribution.

**Key Features:**

- Fixed staking amount requirement
- Configurable staking period
- ETH-based rewards
- One active stake per user
- Owner-controlled staking period updates

## Contract Details

### State Variables

- `stakingToken`: Address of the ERC20 token used for staking
- `stakingPeriod`: Minimum time (in seconds) tokens must be staked before rewards can be claimed
- `fixedStakingAmount`: Required amount of tokens for each stake
- `rewardPerPeriod`: ETH reward amount distributed per completed staking period
- `userBalance`: Mapping of user addresses to their staked token balance
- `elapsePeriod`: Mapping of user addresses to their last reward claim timestamp

### Functions

#### `depositTokens(uint256 tokenAmountToDeposit_)`

Deposits tokens for staking. Requirements:

- Deposit amount must equal `fixedStakingAmount`
- User must not have an active stake
- User must have approved the contract to spend their tokens

#### `withDrawTokens()`

Withdraws all staked tokens back to the user. Resets the user's balance to zero.

#### `claimRewards()`

Claims ETH rewards after completing a staking period. Requirements:

- User must have an active stake equal to `fixedStakingAmount`
- Staking period must have elapsed since last claim
- Contract must have sufficient ETH balance

#### `changeStakingPeriod(uint256 newStakingPeriod_)`

Owner-only function to update the staking period requirement.

#### `receive()`

Fallback function to receive ETH deposits for reward distribution.

## Events

- `ChangedStakingPeriod(uint256 newStakingPeriod_)`: Emitted when the staking period is updated
- `DepositedTokens(address userAddress, uint256 depositAmount_)`: Emitted when tokens are deposited
- `WithdrawnTokens(address userAddress, uint256 withdrawAmount_)`: Emitted when tokens are withdrawn
- `EtherSent(uint256 receivedAmount_)`: Emitted when ETH is received by the contract

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Solidity ^0.8.30

### Setup

1. Clone the repository:

```bash
git clone <repository-url>
cd staking-app
```

2. Install dependencies:

```bash
forge install
```

3. Build the contracts:

```bash
forge build
```

## Testing

Run all tests:

```bash
forge test
```

Run tests with verbose output:

```bash
forge test -vvv
```

Run a specific test:

```bash
forge test --match-test testShouldDepositTokensCorrectly
```

### Test Coverage

The test suite covers:

- ✅ Contract deployment
- ✅ Token deposits (correct and incorrect amounts)
- ✅ Multiple deposit prevention
- ✅ Token withdrawals
- ✅ Reward claiming (with and without sufficient ETH)
- ✅ Staking period updates (owner and non-owner)
- ✅ ETH reception by contract
- ✅ Edge cases and error conditions

## Usage Example

### 1. Deploy Contracts

```solidity
// Deploy StakingToken
StakingToken token = new StakingToken("Staking Token", "STK");

// Deploy StakingApp
StakingApp stakingApp = new StakingApp(
    address(token),
    ownerAddress,
    30 days,        // staking period
    100 ether,      // fixed staking amount
    5 ether         // reward per period
);
```

### 2. User Staking Flow

```solidity
// 1. Mint tokens
token.mint(100 ether);

// 2. Approve contract to spend tokens
token.approve(address(stakingApp), 100 ether);

// 3. Deposit tokens
stakingApp.depositTokens(100 ether);

// 4. Wait for staking period to complete
// (In production, this happens naturally over time)

// 5. Claim rewards
stakingApp.claimRewards();

// 6. Withdraw tokens (optional)
stakingApp.withDrawTokens();
```

### 3. Fund Rewards Pool

```solidity
// Owner sends ETH to contract for rewards
(bool success,) = address(stakingApp).call{value: 1000 ether}("");
require(success, "Transfer failed");
```

## Security Considerations

- **CEI Pattern**: The `claimRewards()` function follows the Checks-Effects-Interactions pattern to prevent reentrancy attacks
- **Access Control**: Uses OpenZeppelin's `Ownable` for secure ownership management
- **Fixed Amount**: Prevents manipulation by requiring a fixed staking amount
- **Single Stake**: Users can only have one active stake at a time
- **Safe Transfers**: Uses standard ERC20 `transferFrom` and `transfer` functions

## Development

### Format Code

```bash
forge fmt
```

### Gas Snapshots

```bash
forge snapshot
```

### Anvil (Local Node)

```bash
anvil
```

## Deployment

Deploy using Foundry scripts:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

## License

UNLICENSED

## Contributing

This is a learning project. Feel free to fork and experiment!
