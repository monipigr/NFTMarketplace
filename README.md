# 🖼️ NFT Marketplace

## 📝 Overview

NFT Marketplace is a minimalist yet functional smart contract that enables users to list, buy, and cancel ERC-721 NFTs directly on-chain at a fixed price. The contract provides a simple and secure interface for peer-to-peer NFT trading using native ETH. Built with Solidity and tested using Foundry, the marketplace prioritizes security, correctness, and gas-efficiency.

## ✨ Features

- 🏷️ **List NFTs**: Owners can list their NFTs for a specific price.
- 💰 **Buy NFTs**: Buyers can purchase listed NFTs by paying the exact price.
- ❌ **Cancel Listings**: Sellers can cancel their active listings.
- 🔐 **Security Measures**:
  - Reentrancy protection using OpenZeppelin’s `ReentrancyGuard`
  - Checks for ownership and price correctness
- 📢 **Events**: Emits `NFTListed`, `NFTSold`, and `NFTCanceled` for front-end and analytics integration.

## 🧩🛡️ Contract Logic & Security Practices

- **Storage Layout**: Nested `mapping(address => mapping(uint256 => Listing))` for quick NFT listing lookups.
- **Structs**:
  - `Listing`: Stores seller, NFT address, token ID, and price.
- **Events**:
  - `NFTListed`, `NFTSold`, `NFTCanceled` to track contract activity.
- **Modifiers & Checks**:
  - Ownership verification with `IERC721.ownerOf`
  - `ReentrancyGuard` used to avoid reentrancy attacks
- **Design Patterns**:
  - CEI (Checks-Effects-Interactions)
  - Pull payment patern using `.call{value: msg.value}("")`
- **Gas Optimization**:
  - Minimal storage and logic to reduce execution costs.

## 🧪 Testing

The contract includes a complete suite of unit tests using Foundry’s `forge-std/Test.sol`. Tests validate core functionalities, expected behavior, and edge cases:

| **Test Function**                     | **Purpose**                                            |
| ------------------------------------- | ------------------------------------------------------ |
| `testMintNFT()`                       | Verifies NFT minting in test setup                     |
| `testShouldRevertIfPriceIsZero()`     | Prevents listing with price = 0                        |
| `testShouldRevertIfNotOwner()`        | Blocks non-owners from listing                         |
| `testListNFTCorrectly()`              | Confirms successful listing                            |
| `testListShouldRevertIfNotOwner()`    | Prevents cancellation by non-seller                    |
| `testCancelListShouldWorkCorrectly()` | Allows correct cancellation of listing                 |
| `testCanNotBuyUnlistedNFT()`          | Prevents unlisted NFT purchase                         |
| `testCanNotBuyWithIncorrectPay()`     | Validates exact payment enforcement                    |
| `testShouldBuyNFTCorrectly()`         | Confirms full purchase flow (ownership + ETH transfer) |

## ✅ Coverage Highlights

```
forge coverage
```

> 📈 **95%+ test coverage**, including listing, cancel listing, and buying.

| File                   | % Lines         | % Statements    | % Branches     | % Funcs       |
| ---------------------- | --------------- | --------------- | -------------- | ------------- |
| src/NFTMarketplace.sol | 100.00% (21/21) | 100.00% (20/20) | 91.67% (11/12) | 100.00% (3/3) |

### 🔍 Notes:

- ETH transfer `require(success, ...)` fallback path intentionally not tested (very low risk)

> The uncovered lines do not affect contract behavior or introduce security risk.

# 🛠 Technologies Used

- **Solidity**: Solidity `^0.8.24`
- **Testing**: Foundry (Forge)
- **NFT Standard**: ERC721
- **Security**: ReentrancyGuard (OpenZeppelin)

## 🔧 How to Use

### Prerequisites

- Install [Foundry](https://book.getfoundry.sh/)
- Install [OpenZeppelin](https://docs.openzeppelin)

### 🛠 Setup

```bash
git clone https://github.com/your-username/NFTMarketplace.git
cd NFTMarketplace
forge install
```

### Testing

```bash
forge test
forge --match-test testExample -vvvv
```

## 📜 License

This project is licensed under the MIT License.
