# Data Model: Closed Positions & Realized P&L

**Feature**: 003-closed-positions | **Date**: 2025-01-22

## Overview

This feature extends the Portfolio data model with computed models for closed trading positions. No new database storage is required - all data is derived from existing Transaction records.

**Design Principles**:
- Closed positions are computed on-the-fly (not persisted)
- Reuse existing Transaction model (@Model in Swift Data)
- Follow same calculation patterns as existing Holding model
- Use Decimal type for all financial values (Constitution Principle IV)

---

## Entity Definitions

### 1. ClosedPosition (Computed Model - NOT Stored)

**Purpose**: Represents a single completed buy-to-sell trading cycle for a specific cryptocurrency.

**Source**: Computed from Transaction records where total buy quantity equals total sell quantity for a cycle.

```swift
struct ClosedPosition: Identifiable, Equatable {
    // MARK: - Identity

    let id: UUID                    // Unique identifier for this closed cycle
    let coinId: String              // CoinGecko coin ID (e.g., "bitcoin")
    let coin: Coin                  // Full coin details (name, symbol, current price)

    // MARK: - Cycle Metrics

    let totalQuantity: Decimal      // Total amount traded in this cycle
    let avgCostPrice: Decimal       // Weighted average buy price for this cycle
    let avgSalePrice: Decimal       // Weighted average sell price for this cycle
    let closedDate: Date            // Date of final sell transaction that closed cycle

    // MARK: - P&L Metrics

    var realizedPnL: Decimal {
        // Realized profit/loss in USD
        (avgSalePrice - avgCostPrice) * totalQuantity
    }

    var realizedPnLPercentage: Decimal {
        // Realized profit/loss as percentage
        guard avgCostPrice > 0 else { return 0 }
        return ((avgSalePrice / avgCostPrice) - 1) * 100
    }

    // MARK: - Source Transactions

    let cycleTransactions: [Transaction]  // All transactions for this cycle
}
```

**Validation Rules**:
- `totalQuantity` > 0 (must have traded non-zero amount)
- `avgCostPrice` >= 0 (can be 0 for gifted coins)
- `avgSalePrice` > 0 (sell price always positive)
- `closedDate` matches date of final sell transaction in cycle
- `cycleTransactions` contains at least 1 buy and 1 sell

**Relationships**:
- References `coinId` → `Coin` (1:1, required)
- References `cycleTransactions` → `[Transaction]` (1:many, required)

**Lifecycle**:
- Created when: Total buy quantity equals total sell quantity for a cycle (within 0.00000001 tolerance)
- Updated when: Never (immutable once created)
- Deleted when: User deletes transactions that close the cycle (position moves back to open holdings)

---

### 2. PortfolioSummary (Computed Model - NOT Stored)

**Purpose**: Aggregates portfolio performance metrics including unrealized and realized P&L.

**Source**: Computed from Holding[] (open positions) and ClosedPosition[] (closed cycles).

```swift
struct PortfolioSummary: Equatable {
    // MARK: - Open Holdings Metrics

    let totalValue: Decimal          // Sum of all open holdings' current value
    let unrealizedPnL: Decimal       // Sum of all open holdings' profit/loss

    // MARK: - Closed Positions Metrics

    let realizedPnL: Decimal         // Sum of all closed positions' realized P&L

    // MARK: - Total Performance

    var totalPnL: Decimal {
        unrealizedPnL + realizedPnL  // Total portfolio P&L (open + closed)
    }

    var totalPnLPercentage: Decimal {
        // Total P&L as percentage of total cost basis
        let totalCostBasis = totalOpenCost + totalClosedCost
        guard totalCostBasis > 0 else { return 0 }
        return (totalPnL / totalCostBasis) * 100
    }

    // MARK: - Internal Metrics

    let totalOpenCost: Decimal       // Sum of all open holdings' cost basis
    let totalClosedCost: Decimal     // Sum of all closed positions' cost basis
}
```

**Validation Rules**:
- All Decimal values can be negative (losses), zero, or positive (gains)
- `totalValue` >= 0 (current value can't be negative)
- `totalCostBasis` = `totalOpenCost` + `totalClosedCost`

**Relationships**:
- Computed from `[Holding]` (many:1)
- Computed from `[ClosedPosition]` (many:1)

**Lifecycle**:
- Created when: PortfolioView loads or refreshes
- Updated when: Transactions change, prices update, positions close
- Deleted when: Never (transient, recomputed on demand)

---

## Computation Algorithms

### Algorithm 1: Compute Closed Positions from Transactions

**Input**: `[Transaction]` - All user transactions across all coins

**Output**: `[ClosedPosition]` - Array of closed trading cycles

**Logic**:

```swift
func computeClosedPositions(
    transactions: [Transaction],
    currentPrices: [String: Coin]
) -> [ClosedPosition] {
    // Step 1: Group transactions by coinId
    let grouped = Dictionary(grouping: transactions, by: { $0.coinId })

    var closedPositions: [ClosedPosition] = []

    // Step 2: For each coin, detect closed cycles
    for (coinId, txs) in grouped {
        guard let coin = currentPrices[coinId] else { continue }

        // Sort transactions by date (chronological order)
        let sortedTxs = txs.sorted { $0.date < $1.date }

        // Step 3: Track running balance and detect cycle closures
        var cycleStart = 0
        var runningBalance: Decimal = 0

        for (index, tx) in sortedTxs.enumerated() {
            // Update running balance
            switch tx.type {
            case .buy:
                runningBalance += tx.amount
            case .sell:
                runningBalance -= tx.amount
            }

            // Check if cycle closed (balance within tolerance of zero)
            if abs(runningBalance) < 0.00000001 && runningBalance != 0 {
                // Extract cycle transactions
                let cycleTxs = Array(sortedTxs[cycleStart...index])

                // Compute cycle metrics
                if let closedPos = computeCycleMetrics(
                    coinId: coinId,
                    coin: coin,
                    transactions: cycleTxs,
                    closeDate: tx.date
                ) {
                    closedPositions.append(closedPos)
                }

                // Reset for next cycle
                cycleStart = index + 1
                runningBalance = 0
            }
        }
    }

    // Step 4: Sort by close date (most recent first)
    return closedPositions.sorted { $0.closedDate > $1.closedDate }
}

private func computeCycleMetrics(
    coinId: String,
    coin: Coin,
    transactions: [Transaction],
    closeDate: Date
) -> ClosedPosition? {
    var totalBuyAmount: Decimal = 0
    var totalBuyCost: Decimal = 0
    var totalSellAmount: Decimal = 0
    var totalSellRevenue: Decimal = 0

    // Calculate weighted averages
    for tx in transactions {
        switch tx.type {
        case .buy:
            totalBuyAmount += tx.amount
            totalBuyCost += tx.amount * tx.pricePerCoin
        case .sell:
            totalSellAmount += tx.amount
            totalSellRevenue += tx.amount * tx.pricePerCoin
        }
    }

    guard totalBuyAmount > 0 && totalSellAmount > 0 else {
        return nil  // Invalid cycle
    }

    let avgCostPrice = totalBuyCost / totalBuyAmount
    let avgSalePrice = totalSellRevenue / totalSellAmount

    return ClosedPosition(
        id: UUID(),
        coinId: coinId,
        coin: coin,
        totalQuantity: totalBuyAmount,  // Use buy amount (should equal sell amount)
        avgCostPrice: avgCostPrice,
        avgSalePrice: avgSalePrice,
        closedDate: closeDate,
        cycleTransactions: transactions
    )
}
```

**Performance**:
- Time Complexity: O(n log n) where n = total transactions (dominated by sorting)
- Space Complexity: O(n) for grouped and sorted arrays
- Expected runtime: < 100ms for 100 transactions (Assumption #7)

**Edge Cases Handled**:
- Fractional amounts: Tolerance 0.00000001 for close detection
- Multiple cycles: Each close creates new entry
- Zero-cost positions: avgCostPrice = 0 allowed
- Transaction deletions: Recompute from scratch when transactions change

---

### Algorithm 2: Compute Portfolio Summary

**Input**:
- `[Holding]` - Active open positions
- `[ClosedPosition]` - Closed trading cycles

**Output**: `PortfolioSummary` - Aggregated portfolio metrics

**Logic**:

```swift
func computePortfolioSummary(
    holdings: [Holding],
    closedPositions: [ClosedPosition]
) -> PortfolioSummary {
    // Open holdings metrics
    let totalValue = holdings.reduce(0) { $0 + $1.currentValue }
    let unrealizedPnL = holdings.reduce(0) { $0 + $1.profitLoss }
    let totalOpenCost = holdings.reduce(0) { $0 + $1.totalCost }

    // Closed positions metrics
    let realizedPnL = closedPositions.reduce(0) { $0 + $1.realizedPnL }
    let totalClosedCost = closedPositions.reduce(0) { $0 + ($1.avgCostPrice * $1.totalQuantity) }

    return PortfolioSummary(
        totalValue: totalValue,
        unrealizedPnL: unrealizedPnL,
        realizedPnL: realizedPnL,
        totalOpenCost: totalOpenCost,
        totalClosedCost: totalClosedCost
    )
}
```

**Performance**:
- Time Complexity: O(h + c) where h = holdings count, c = closed positions count
- Space Complexity: O(1)
- Expected runtime: < 1ms for typical portfolio sizes

---

## Data Integrity

### Close Detection Tolerance

**Requirement**: Position considered closed when `|total bought - total sold| < 0.00000001`

**Rationale**: Decimal arithmetic may introduce minor precision errors. Tolerance prevents false negatives.

**Example**:
```swift
// User buys 1.0 BTC, sells 0.999999999 BTC
let bought: Decimal = 1.0
let sold: Decimal = 0.999999999
let balance = bought - sold  // 0.000000001

// With tolerance:
if abs(balance) < 0.00000001 {
    // Position considered closed ✅
}
```

### Weighted Average Calculation

**Requirement**: Cost and sale prices use weighted average

**Formula**:
```
avgCostPrice = SUM(buy_amount[i] * buy_price[i]) / SUM(buy_amount[i])
avgSalePrice = SUM(sell_amount[i] * sell_price[i]) / SUM(sell_amount[i])
```

**Example**:
```swift
// Cycle transactions:
// Buy 0.5 BTC @ $40,000 = $20,000 cost
// Buy 0.5 BTC @ $50,000 = $25,000 cost
// Sell 1.0 BTC @ $60,000 = $60,000 revenue

avgCostPrice = (20,000 + 25,000) / (0.5 + 0.5) = $45,000
avgSalePrice = 60,000 / 1.0 = $60,000
realizedPnL = (60,000 - 45,000) * 1.0 = $15,000 profit ✅
```

---

## Testing Requirements

### Unit Tests (Test-First - Write BEFORE Implementation)

1. **Cycle Detection Tests**:
   - Single buy/sell cycle (1 buy, 1 sell)
   - Multiple buys, single sell (weighted average)
   - Single buy, multiple sells (weighted average)
   - Multiple cycles for same coin (2 separate entries)
   - Fractional amounts within tolerance (closes)
   - Fractional amounts outside tolerance (stays open)

2. **P&L Calculation Tests**:
   - Profitable cycle (sale price > cost price)
   - Loss cycle (sale price < cost price)
   - Break-even cycle (sale price = cost price)
   - Zero-cost cycle (gifted coins, cost = 0)
   - High precision (8 decimal places)

3. **Portfolio Summary Tests**:
   - Only open holdings (realized P&L = 0)
   - Only closed positions (unrealized P&L = 0, total value = 0)
   - Mixed open and closed (all 4 metrics)
   - Total P&L = unrealized + realized

4. **Edge Case Tests**:
   - Transaction deletion (cycle reopens)
   - Empty transaction list (no closed positions)
   - All sells (no cycles - impossible scenario)
   - All buys (no cycles - position stays open)

**Test Coverage Target**: 100% for computation functions

---

## Dependencies

### Existing Models

- **Transaction** (`Bitpal/Features/Portfolio/Models/Transaction.swift`)
  - Swift Data @Model (persisted)
  - Properties: id, coinId, type, amount, pricePerCoin, date, notes

- **Coin** (`Bitpal/Models/Coin.swift`)
  - API response model
  - Properties: id, symbol, name, currentPrice, priceChange24h, lastUpdated

- **Holding** (`Bitpal/Features/Portfolio/Models/Holding.swift`)
  - Computed model (NOT persisted)
  - Similar pattern to ClosedPosition

### Reused Patterns

- Weighted average calculation (from `computeHoldings()`)
- Decimal arithmetic for financial values
- Computed model pattern (struct, derived from @Model data)

---

## Migration Notes

**No database migration required** - ClosedPosition is computed, not stored.

**Backward Compatibility**: Existing Transaction records work as-is. No schema changes.

**Data Consistency**: Closed positions automatically update when:
- User adds transaction (may close open position)
- User edits transaction (may open/close position)
- User deletes transaction (may reopen closed position)
