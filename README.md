## Introduction 🌟

The `Options` smart contract is an ERC20 token designed for speculative betting on Ethereum's price movement. It allows users to bet on the increase or decrease of ETH's price, using the WETH/USDT pair from Uniswap for price reference. This contract is built on Solidity and leverages OpenZeppelin's ERC20 standard and ReentrancyGuard for enhanced security and functionality.

## Contract Functions 🛠️

### Constructor 🏗️

- `constructor()`
  - Initializes the contract, mints 1,000,000 `OPTION` tokens to the contract itself, and sets up the Uniswap WETH/USDT pair for price checking.

### View Functions 👀

- `eth_price_check()`
  - 📈 Returns the current ETH price based on the Uniswap WETH/USDT pair's reserves.

### Transaction Functions 💰

- `buy()`
  - 📊 Allows a user to bet on the increase of ETH's price. When called, it requires the user to send 0.01 ETH and records the current ETH price as the user's `BuyPrice`.
  - 📝 Emits a `BuyPriceSet` event.

- `sell()`
  - 🔻 Allows a user to bet on the decrease of ETH's price. Similar to `buy()`, it requires 0.01 ETH and records the current price as the `SellPrice`.
  - 📝 Emits a `SellPriceSet` event.

### Getter Functions 📚

- `getBuyPrice()`
  - 📌 Returns the `BuyPrice` set by the calling user, if it exists.

- `getSellPrice()`
  - 📌 Returns the `SellPrice` set by the calling user, if it exists.

### Fallback and Receive Functions 🚨

- `fallback()`
  - A fallback function to handle ETH sent directly to the contract.

- `receive()`
  - A receive function to handle plain ETH transfers to the contract.

## Game Mechanics 🎮

Users of this contract can speculate on Ethereum's price movement. By calling `buy()` or `sell()`, users bet on the price going up or down, respectively. The contract uses the Uniswap WETH/USDT pair to determine the current price of ETH and compares it with the user's bet. Successful predictions can be integrated with reward mechanisms (not implemented in this contract).

## Security Measures 🔒

This contract employs `ReentrancyGuard` from OpenZeppelin to prevent reentrancy attacks, a common vulnerability in smart contracts dealing with financial transactions.

## Disclaimer ⚠️

This contract is a demonstration of ERC20 token functionality and speculative betting mechanics. Users should exercise caution and understand the risks involved in blockchain-based betting. The contract should be thoroughly audited before any real-world implementation.

---


