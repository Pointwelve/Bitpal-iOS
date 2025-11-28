# Data Model: iOS Home Screen Widgets for Portfolio

**Feature**: 004-portfolio-widgets
**Date**: 2025-11-26

## Overview

This document defines the data models for the widget feature, including both new widget-specific models and relationships to existing app models.

---

## Existing Models (No Changes Required)

These models already exist and will be **reused** by the widget through shared calculation code:

### Coin
```swift
struct Coin: Identifiable, Codable, Equatable {
    let id: String           // CoinGecko ID (e.g., "bitcoin")
    let symbol: String       // Ticker (e.g., "btc")
    let name: String         // Display name (e.g., "Bitcoin")
    var currentPrice: Decimal
    var priceChange24h: Decimal
    var lastUpdated: Date
    var marketCap: Decimal?
}
```

### Transaction (Swift Data Model)
```swift
@Model
final class Transaction {
    var id: UUID
    var coinId: String
    var type: TransactionType  // .buy or .sell
    var amount: Decimal
    var pricePerCoin: Decimal
    var date: Date
    var notes: String?
    var closedCycleId: UUID?   // nil = open position
}
```

### Holding (Computed)
```swift
struct Holding: Identifiable, Equatable {
    let id: String           // coinId
    let coin: Coin
    let totalAmount: Decimal
    let avgCost: Decimal
    let currentValue: Decimal
    var profitLoss: Decimal { computed }
    var profitLossPercentage: Decimal { computed }
}
```

### ClosedPosition
```swift
struct ClosedPosition: Identifiable, Equatable {
    let id: UUID
    let coinId: String
    let coinSymbol: String
    let coinName: String
    let totalQuantity: Decimal
    let avgCostPrice: Decimal
    let avgSellPrice: Decimal
    let realizedPnL: Decimal
    let realizedPnLPercentage: Decimal
    let closedDate: Date
}
```

### PortfolioSummary (Computed)
```swift
struct PortfolioSummary: Equatable {
    let totalValue: Decimal
    let unrealizedPnL: Decimal
    let realizedPnL: Decimal
    let totalOpenCost: Decimal
    let totalClosedCost: Decimal
    var totalPnL: Decimal { computed }
    var totalPnLPercentage: Decimal { computed }
}
```

---

## New Models for Widget

### WidgetPortfolioData

Primary data structure written by app and read by widget. Stored in App Group container.

```swift
/// Lightweight portfolio data optimized for widget display.
/// Written by main app on each portfolio update.
/// Read by widget during timeline generation.
struct WidgetPortfolioData: Codable, Equatable {
    // MARK: - Portfolio Value

    /// Total current value of all open holdings (USD)
    let totalValue: Decimal

    // MARK: - P&L Breakdown

    /// Unrealized P&L from open positions (USD)
    let unrealizedPnL: Decimal

    /// Realized P&L from closed positions (USD)
    let realizedPnL: Decimal

    /// Total P&L (unrealized + realized) in USD
    let totalPnL: Decimal

    // MARK: - Holdings

    /// Top holdings by current value (max 5)
    /// Pre-sorted by currentValue descending
    let holdings: [WidgetHolding]

    // MARK: - Metadata

    /// Timestamp when this data was generated
    let lastUpdated: Date

    /// Whether portfolio has any holdings
    var isEmpty: Bool {
        holdings.isEmpty && totalValue == 0
    }
}
```

**Validation Rules**:
- `holdings.count` ≤ 5 (enforced during creation)
- All `Decimal` values use standard precision (no rounding)
- `lastUpdated` must be non-nil

**State Transitions**:
- Created when portfolio is loaded with prices
- Updated on transaction add/edit/delete
- Updated on price refresh
- Persisted to App Group on each update

---

### WidgetHolding

Simplified holding representation for widget display.

```swift
/// Lightweight holding data for widget display.
/// Subset of Holding properties needed for widget UI.
struct WidgetHolding: Codable, Identifiable, Equatable {
    // MARK: - Identification

    /// CoinGecko coin ID (e.g., "bitcoin")
    let id: String

    /// Ticker symbol uppercase (e.g., "BTC")
    let symbol: String

    /// Full coin name (e.g., "Bitcoin")
    let name: String

    // MARK: - Value

    /// Current market value in USD
    let currentValue: Decimal

    // MARK: - P&L

    /// Unrealized profit/loss amount in USD
    let pnlAmount: Decimal

    /// Unrealized profit/loss as percentage
    let pnlPercentage: Decimal

    // MARK: - Computed

    /// True if holding is profitable
    var isProfit: Bool {
        pnlAmount >= 0
    }
}
```

**Validation Rules**:
- `id` must match a valid CoinGecko coin ID
- `symbol` should be uppercase (display convention)
- All `Decimal` values must be valid numbers

---

### PortfolioEntry (Widget Timeline Entry)

WidgetKit timeline entry containing portfolio data for a specific time.

```swift
/// Timeline entry for widget display.
/// Conforms to TimelineEntry protocol.
struct PortfolioEntry: TimelineEntry {
    /// When this entry should be displayed
    let date: Date

    /// Portfolio data to display (nil for placeholder)
    let data: WidgetPortfolioData?

    /// Whether this is a placeholder entry
    var isPlaceholder: Bool {
        data == nil
    }

    // MARK: - Factory Methods

    /// Create placeholder entry for widget gallery
    static func placeholder() -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: nil)
    }

    /// Create entry with real portfolio data
    static func entry(data: WidgetPortfolioData) -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: data)
    }
}
```

---

## Data Relationships

```text
┌─────────────────────────────────────────────────────────────────────┐
│                          MAIN APP                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Transaction[] ──────► computeHoldings() ──────► Holding[]          │
│       │                                              │               │
│       │                                              │               │
│       ├──────────────► computeClosedPositions() ──► ClosedPosition[]│
│       │                                              │               │
│       │                                              │               │
│       └──────────────► computePortfolioSummary() ◄──┘               │
│                              │                                       │
│                              ▼                                       │
│                       PortfolioSummary                               │
│                              │                                       │
│                              │                                       │
│                              ▼                                       │
│                    prepareWidgetData()                               │
│                              │                                       │
│                              ▼                                       │
│                    WidgetPortfolioData                               │
│                              │                                       │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
                               │ App Group Storage
                               │ (BitpalShared.sqlite or .json)
                               │
┌──────────────────────────────┼───────────────────────────────────────┐
│                              ▼                                       │
│                       WIDGET EXTENSION                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  WidgetPortfolioData ──────► PortfolioEntry ──────► Widget Views    │
│                                                                      │
│  • SmallWidgetView (totalValue, totalPnL)                           │
│  • MediumWidgetView (+ top 2 holdings)                              │
│  • LargeWidgetView (+ top 5 holdings)                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Storage Schema

### App Group Container

**Identifier**: `group.com.bitpal.shared`

**File Structure**:
```text
App Group Container/
└── Library/
    └── Application Support/
        └── WidgetData/
            └── portfolio.json    # WidgetPortfolioData (JSON encoded)
```

**Why JSON over Swift Data for Widget**:
- Simpler read-only access for widget
- No schema migration complexity
- Faster read performance for small data
- Widget only needs read access

**Storage Format**:
```json
{
  "totalValue": "125000.50",
  "unrealizedPnL": "15000.00",
  "realizedPnL": "5000.00",
  "totalPnL": "20000.00",
  "holdings": [
    {
      "id": "bitcoin",
      "symbol": "BTC",
      "name": "Bitcoin",
      "currentValue": "100000.00",
      "pnlAmount": "12000.00",
      "pnlPercentage": "13.64"
    }
  ],
  "lastUpdated": "2025-11-26T10:30:00Z"
}
```

---

## Data Transformation Functions

### prepareWidgetData

Transforms app models to widget format.

```swift
/// Transforms portfolio data to widget-optimized format.
/// - Parameters:
///   - summary: Portfolio summary with P&L totals
///   - holdings: All holdings sorted by value descending
/// - Returns: Widget-optimized portfolio data
func prepareWidgetData(
    summary: PortfolioSummary,
    holdings: [Holding]
) -> WidgetPortfolioData {
    // Take top 5 holdings by current value
    let topHoldings = holdings.prefix(5).map { holding in
        WidgetHolding(
            id: holding.id,
            symbol: holding.coin.symbol.uppercased(),
            name: holding.coin.name,
            currentValue: holding.currentValue,
            pnlAmount: holding.profitLoss,
            pnlPercentage: holding.profitLossPercentage
        )
    }

    return WidgetPortfolioData(
        totalValue: summary.totalValue,
        unrealizedPnL: summary.unrealizedPnL,
        realizedPnL: summary.realizedPnL,
        totalPnL: summary.totalPnL,
        holdings: Array(topHoldings),
        lastUpdated: Date()
    )
}
```

---

## Entity Summary

| Entity | Type | Storage | Purpose |
|--------|------|---------|---------|
| WidgetPortfolioData | Struct | App Group (JSON) | Primary widget data |
| WidgetHolding | Struct | App Group (JSON) | Holding display data |
| PortfolioEntry | Struct | Memory | Timeline entry |
| Transaction | Swift Data | Main app DB | Source data (read-only from widget perspective) |
| Holding | Struct | Memory | Computed from transactions |
| PortfolioSummary | Struct | Memory | Computed P&L totals |

---

## Validation & Error Handling

### Empty State Detection
- `WidgetPortfolioData.isEmpty` → Show "Add holdings" message
- `holdings.count == 0` but `realizedPnL > 0` → Show P&L only (closed positions only)

### Stale Data Detection
- Compare `lastUpdated` to current time
- Show "Updated X min ago" timestamp
- If > 60 minutes stale, show subtle staleness indicator

### Corrupt Data Handling
- If JSON parsing fails, return `nil` from storage
- Widget shows placeholder entry
- Main app re-writes data on next portfolio load
