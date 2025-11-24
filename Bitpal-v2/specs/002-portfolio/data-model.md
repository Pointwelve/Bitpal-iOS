# Data Model: Portfolio Feature

**Feature**: Manual Portfolio (002-portfolio)
**Date**: 2025-11-18

---

## Entity Overview

```
┌─────────────────┐     ┌─────────────────┐
│   Transaction   │────▶│      Coin       │
│  (Swift Data)   │     │   (Shared)      │
└─────────────────┘     └─────────────────┘
         │
         │ computed from
         ▼
┌─────────────────┐
│     Holding     │
│  (NOT stored)   │
└─────────────────┘
```

---

## 1. Transaction (Swift Data @Model)

User's recorded buy/sell action. Persisted permanently.

### Definition

```swift
import SwiftData
import Foundation

@Model
final class Transaction {
    // MARK: - Properties
    var id: UUID
    var coinId: String              // Reference to Coin.id (CoinGecko ID)
    var type: TransactionType       // Buy or Sell
    var amount: Decimal             // Quantity of coins
    var pricePerCoin: Decimal       // USD price at transaction time
    var date: Date                  // Transaction date
    var notes: String?              // Optional user notes

    // MARK: - Initialization
    init(
        id: UUID = UUID(),
        coinId: String,
        type: TransactionType,
        amount: Decimal,
        pricePerCoin: Decimal,
        date: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.coinId = coinId
        self.type = type
        self.amount = amount
        self.pricePerCoin = pricePerCoin
        self.date = date
        self.notes = notes
    }
}
```

### Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| id | UUID | Unique, auto-generated | Primary identifier |
| coinId | String | Required | CoinGecko coin ID (e.g., "bitcoin") |
| type | TransactionType | Required | Buy or Sell |
| amount | Decimal | > 0 | Quantity of coins |
| pricePerCoin | Decimal | > 0 | USD price per coin |
| date | Date | ≤ today | Transaction date |
| notes | String? | Optional | User-provided notes |

### Validation Rules

1. `amount > 0` - Quantity must be positive
2. `pricePerCoin > 0` - Price must be positive
3. `date <= Date()` - Cannot be future date
4. `coinId` must exist in coin database
5. For Sell: `amount ≤ current holding quantity`

### Relationships

- References `Coin` by `coinId` (not a direct Swift Data relationship)
- Future: Will include `portfolioId` field for Phase 2+ multi-portfolio support

### Design Notes

- Uses `Decimal` for all financial values (Constitution Principle IV)
- No direct relationship to Coin to avoid Swift Data complexity
- Designed for future `portfolioId` field without migration

---

## 2. TransactionType (Enum)

Enumeration of transaction directions.

### Definition

```swift
import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case buy
    case sell

    var displayName: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
}
```

### Values

| Value | Description | Effect on Holdings |
|-------|-------------|-------------------|
| buy | Purchase cryptocurrency | Adds to quantity, updates avg cost |
| sell | Sell cryptocurrency | Reduces quantity, no avg cost change |

---

## 3. Holding (Computed Struct)

Computed user position derived from transactions. NOT persisted.

### Definition

```swift
import Foundation

struct Holding: Identifiable, Equatable {
    // MARK: - Stored Properties
    let id: String              // coinId
    let coin: Coin              // Full coin data with current price
    let totalAmount: Decimal    // Computed total quantity
    let avgCost: Decimal        // Computed weighted average cost
    let currentValue: Decimal   // Computed: totalAmount × currentPrice

    // MARK: - Computed Properties
    var profitLoss: Decimal {
        currentValue - (totalAmount * avgCost)
    }

    var profitLossPercentage: Decimal {
        guard avgCost > 0 else { return 0 }
        return ((currentValue / (totalAmount * avgCost)) - 1) * 100
    }

    var totalCost: Decimal {
        totalAmount * avgCost
    }
}
```

### Attributes

| Attribute | Type | Source | Description |
|-----------|------|--------|-------------|
| id | String | coinId | Unique identifier (same as coinId) |
| coin | Coin | API | Full coin data including current price |
| totalAmount | Decimal | Calculated | Sum of buy amounts - sum of sell amounts |
| avgCost | Decimal | Calculated | Weighted average of buy prices |
| currentValue | Decimal | Calculated | totalAmount × coin.currentPrice |
| profitLoss | Decimal | Calculated | currentValue - (totalAmount × avgCost) |
| profitLossPercentage | Decimal | Calculated | ((currentValue / totalCost) - 1) × 100 |

### Calculation Logic

```swift
/// Compute holdings from transactions and current prices
func computeHoldings(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> [Holding] {
    // Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    return grouped.compactMap { (coinId, txs) -> Holding? in
        guard let coin = currentPrices[coinId] else { return nil }

        var totalAmount: Decimal = 0
        var totalCost: Decimal = 0

        for tx in txs {
            switch tx.type {
            case .buy:
                totalAmount += tx.amount
                totalCost += tx.amount * tx.pricePerCoin
            case .sell:
                totalAmount -= tx.amount
                // Sells don't affect total cost (for avg cost calculation)
            }
        }

        // Skip if no holdings remain
        guard totalAmount > 0 else { return nil }

        let avgCost = totalCost / totalAmount
        let currentValue = totalAmount * coin.currentPrice

        return Holding(
            id: coinId,
            coin: coin,
            totalAmount: totalAmount,
            avgCost: avgCost,
            currentValue: currentValue
        )
    }
}
```

### Why Not Persisted

1. **Data consistency**: Always derived from source-of-truth transactions
2. **No stale data**: Automatically reflects transaction changes
3. **Simpler model**: No need to maintain two data stores
4. **Performance**: Computation is fast (<100ms for 50 holdings, 500 transactions per SC-005)

---

## 4. PortfolioError (Error Type)

Domain-specific errors for Portfolio feature.

### Definition

```swift
import Foundation

enum PortfolioError: LocalizedError {
    case coinNotFound(String)
    case insufficientBalance(coinId: String, owned: Decimal, attempted: Decimal)
    case invalidAmount
    case invalidPrice
    case futureDateNotAllowed
    case transactionNotFound(UUID)
    case saveFailed(Error)
    case deleteFailed(Error)
    case priceDataUnavailable

    var errorDescription: String? {
        switch self {
        case .coinNotFound(let coinId):
            return "Cryptocurrency '\(coinId)' not found"
        case .insufficientBalance(let coinId, let owned, let attempted):
            return "You only own \(owned) \(coinId). Cannot sell \(attempted)."
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .invalidPrice:
            return "Price must be greater than zero"
        case .futureDateNotAllowed:
            return "Transaction date cannot be in the future"
        case .transactionNotFound(let id):
            return "Transaction \(id) not found"
        case .saveFailed(let error):
            return "Failed to save transaction: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete transaction: \(error.localizedDescription)"
        case .priceDataUnavailable:
            return "Price data is currently unavailable"
        }
    }
}
```

---

## 5. Coin (Shared Model - Reused)

Cryptocurrency market data. Shared with Watchlist feature.

**Path**: `Bitpal/Models/Coin.swift`

### Definition (Reference)

```swift
struct Coin: Identifiable, Codable, Equatable {
    let id: String              // CoinGecko ID (e.g., "bitcoin")
    let symbol: String          // Symbol (e.g., "btc")
    let name: String            // Full name (e.g., "Bitcoin")
    var currentPrice: Decimal   // Current USD price
    var priceChange24h: Decimal // 24h price change percentage
    var lastUpdated: Date       // Last price update timestamp
    var marketCap: Decimal?     // Market cap for sorting
}
```

### Usage in Portfolio

- Referenced by `Transaction.coinId`
- Included in `Holding.coin` for display
- Fetched via `CoinGeckoService.fetchMarketData(coinIds:)`

---

## 6. Swift Data Container Configuration

### BitpalApp.swift Update

```swift
import SwiftUI
import SwiftData

@main
struct BitpalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WatchlistItem.self,
            Transaction.self  // ADD: Portfolio transactions
        ])
    }
}
```

---

## 7. Queries and Predicates

### Fetch All Transactions

```swift
@Query(sort: \Transaction.date, order: .reverse)
private var allTransactions: [Transaction]
```

### Fetch Transactions for Specific Coin

```swift
@Query(filter: #Predicate<Transaction> { $0.coinId == "bitcoin" },
       sort: \Transaction.date, order: .reverse)
private var bitcoinTransactions: [Transaction]
```

### Get Unique Coin IDs with Holdings

```swift
func getHeldCoinIds(from transactions: [Transaction]) -> [String] {
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })
    return grouped.compactMap { (coinId, txs) -> String? in
        let total = txs.reduce(Decimal.zero) { sum, tx in
            switch tx.type {
            case .buy: return sum + tx.amount
            case .sell: return sum - tx.amount
            }
        }
        return total > 0 ? coinId : nil
    }
}
```

---

## 8. State Transitions

### Transaction Lifecycle

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Draft   │────▶│  Saved   │────▶│ Deleted  │
└──────────┘     └──────────┘     └──────────┘
     │                │                │
     │ User fills     │ Edit           │ User confirms
     │ form           │ transaction    │ deletion
     ▼                ▼                ▼
   Valid?          Updated          Removed from
   Save            Recalculate      Swift Data
```

### Holding Lifecycle

```
Holdings recalculate when:
1. Transaction added
2. Transaction edited
3. Transaction deleted
4. Prices refresh (every 30 seconds)
```

---

## 9. Data Precision Requirements

Per Constitution Principle IV and FR-019/FR-020:

| Data Type | Precision | Notes |
|-----------|-----------|-------|
| Quantity (amount) | 8 decimal places | e.g., 0.00000001 BTC |
| Price (pricePerCoin) | 2 decimal places | USD currency |
| Total values | 2 decimal places | Display only |
| P&L percentage | 2 decimal places | e.g., +25.34% |

### Decimal Usage

```swift
// ✅ CORRECT: Use Decimal for all financial values
var amount: Decimal
var pricePerCoin: Decimal
var profitLoss: Decimal

// ❌ FORBIDDEN: Never use Double/Float for money
var amount: Double  // NO
var price: Float    // NO
```

---

## 10. Validation Summary

### Transaction Validation

| Field | Rule | Error |
|-------|------|-------|
| coinId | Must exist in database | `.coinNotFound` |
| amount | > 0 | `.invalidAmount` |
| pricePerCoin | > 0 | `.invalidPrice` |
| date | ≤ today | `.futureDateNotAllowed` |
| amount (sell) | ≤ owned quantity | `.insufficientBalance` |

### Business Rules

1. **Weighted Average Cost**: Only buy transactions affect average cost
2. **Zero Holdings Hidden**: Holdings with totalAmount = 0 not displayed
3. **P&L Calculation**: Based on average cost vs current value
4. **Atomic Updates**: All values recalculate together to avoid inconsistency
