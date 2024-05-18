# Chainlink Auto Stake

This is a smart contract that monitors the Chainlink staking pool for withdrawals and uses [Chainlink Automation](https://automation.chain.link/) to make deposits.

[Video Demonstration](https://www.youtube.com/watch?v=1wUCTC_FNNE)

[Tutorial video](https://www.youtube.com/watch?v=HLrTLMZpdoM)

## Table of Contents

- [Chainlink Auto Stake](#chainlink-auto-stake)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Usage](#usage)
  - [Deployment Instructions](#deployment-instructions)
  - [Deployments/Transactions](#deploymentstransactions)
  - [License](#license)

## Overview

The Chainlink [v0.2 Community Staking Pool](https://staking.chain.link/) recently opened for early access and filled up in a matter of hours. Unlike the v0.1 iteration, v0.2 gives participants the option to _unstake_ their tokens, freeing up space for other participants.

**Chainlink Auto Stake** is a contract that uses [Chainlink Automation](https://automation.chain.link/) to monitor the [Community Staking Pool contract](https://etherscan.io/address/0xbc10f2e862ed4502144c7d632a3459f49dfcdb5e#code) for available space and immediately deposit LINK tokens into it when that space appears.

[Custom Logic Automation](https://docs.chain.link/chainlink-automation/overview/getting-started) is used.

The `checkUpkeep()` function returns true if the amount returned by the staking pool contract's `getTotalPrincipal()` function returns less than its `getMaxPoolSize()` function.

The `performUpkeep()` function calls the `transferAndCall()` function on the LINK token contract to stake LINK tokens with the staking pool contract. The amount of tokens staked depends on the available space in the staking pool and the balance of the contract. If the available space is less than the balance, an amount equivalent to the available space will be staked. Whereas if the available space is more than the balance, the full balance will be staked.

An `ICommunityStakingPool` interface is used for interacting with the staking pool contract.

`onlyOwner` modifiers are used to ensure only the owner of a contract can migrate, unstake and withdraw their LINK tokens.

## Usage

To use this contract it must be funded with LINK tokens and registered with Chainlink Custom Logic Automation.

## Deployment Instructions

You should have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed.

Please provide a `.env` file that includes a `$PRIVATE_KEY` and `$RPC_URL`.

Then to deploy the _Chainlink Auto Stake_ contract run the following command:

```
forge script script/DeployChainlinkAutoStake.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

The _Mock Staking Pool_ contract can be deployed for testing purposes with the following command:

```
forge script script/DeployMockStakingPool.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Deployments/Transactions

[MockStakingPool on Sepolia](https://sepolia.etherscan.io/address/0x3141b5d66daed0a04eb7bb19c27f49a1c8a9f0b1)

[ChainlinkAutoStake on Sepolia](https://sepolia.etherscan.io/address/0x93502f3f744ce4a314748d9da36c06040ed67b06#code)

[Tx of Automation depositing into staking pool when space available](https://sepolia.etherscan.io/tx/0xcc5b6479166091bf08ae3acdf1a71e159c833dcbd043335170bc709559ad68b5)

[Automation registration](https://automation.chain.link/sepolia/45454482563271285584554812367543082606141135359646937590532192170177916350762)

## License

This project is licensed under the [MIT License](https://opensource.org/license/mit/).
