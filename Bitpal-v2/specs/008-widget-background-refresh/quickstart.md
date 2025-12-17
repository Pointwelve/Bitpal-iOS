# Quickstart: Widget Background Refresh

**Feature**: 008-widget-background-refresh
**Date**: 2025-12-11

## Overview

Enable the portfolio widget to fetch fresh cryptocurrency prices directly from the CoinGecko API when iOS requests a timeline refresh.

## What Changes

### New Files

1. **`Bitpal/Shared/Models/WidgetRefreshData.swift`**
   - Stores coin quantities and costs for P&L recalculation
   - Written by main app, read by widget

2. **`BitpalWidget/Services/WidgetAPIClient.swift`**
   - Lightweight API client for widget
   - Fetches batched prices from CoinGecko

3. **`BitpalTests/WidgetTests/WidgetRefreshTests.swift`**
   - Unit tests for P&L recalculation logic

### Modified Files

1. **`Bitpal/Shared/Services/AppGroupStorage.swift`**
   - Add `writeRefreshData()` and `readRefreshData()` methods

2. **`Bitpal/Features/Widget/WidgetDataProvider.swift`**
   - Write refresh data when updating widget data

3. **`BitpalWidget/Provider/PortfolioTimelineProvider.swift`**
   - Fetch fresh prices in `getTimeline()`
   - Recalculate holdings with fresh prices
   - Fall back to cached data on failure

## Data Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Main App      │     │   App Group     │     │   Widget        │
│                 │     │   Container     │     │                 │
│ PortfolioVM     │     │                 │     │ TimelineProvider│
│      │          │     │                 │     │      │          │
│      ▼          │     │                 │     │      ▼          │
│ WidgetData      │────▶│ refresh_data    │────▶│ Read quantities │
│ Provider        │     │ .json           │     │      │          │
│                 │     │                 │     │      ▼          │
│                 │     │                 │     │ Fetch prices    │
│                 │     │                 │     │ (CoinGecko API) │
│                 │     │                 │     │      │          │
│                 │     │ portfolio       │◀────│ Recalculate &   │
│                 │     │ .json           │     │ write results   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## Key Implementation Points

### 1. WidgetRefreshData Structure

```swift
struct WidgetRefreshData: Codable, Sendable {
    let holdings: [RefreshableHolding]
    let realizedPnL: Decimal

    struct RefreshableHolding: Codable, Sendable {
        let coinId: String
        let symbol: String
        let name: String
        let quantity: Decimal
        let avgCost: Decimal
    }
}
```

### 2. Timeline Provider Flow

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    Task {
        // 1. Read refresh data (quantities)
        guard let refreshData = storage.readRefreshData() else {
            completion(emptyTimeline())
            return
        }

        // 2. Try to fetch fresh prices
        do {
            let prices = try await WidgetAPIClient.fetchPrices(
                coinIds: refreshData.holdings.map { $0.coinId }
            )

            // 3. Recalculate with fresh prices
            let updatedData = recalculatePortfolio(refreshData, prices)

            // 4. Write updated data for widget views
            try storage.writePortfolioData(updatedData)

            // 5. Return timeline with fresh data
            completion(freshTimeline(updatedData))
        } catch {
            // Fall back to cached data
            let cached = storage.readPortfolioData() ?? .empty
            completion(cachedTimeline(cached))
        }
    }
}
```

### 3. P&L Recalculation

```swift
func recalculateHoldings(_ refreshData: WidgetRefreshData, _ prices: [String: CoinMarketData]) -> [WidgetHolding] {
    refreshData.holdings.compactMap { holding in
        guard let price = prices[holding.coinId] else { return nil }

        let currentValue = holding.quantity * price.currentPrice
        let costBasis = holding.quantity * holding.avgCost
        let pnlAmount = currentValue - costBasis
        let pnlPercentage = costBasis > 0 ? ((currentValue / costBasis) - 1) * 100 : 0

        return WidgetHolding(
            id: holding.coinId,
            symbol: holding.symbol.uppercased(),
            name: holding.name,
            currentValue: currentValue,
            pnlAmount: pnlAmount,
            pnlPercentage: pnlPercentage
        )
    }
}
```

## Testing

### Unit Tests (Before Implementation)

1. P&L recalculation with mock prices
2. Empty holdings handling
3. Missing price fallback
4. Decimal precision preservation

### Manual Testing

1. Add widget to home screen
2. Wait 15+ minutes without opening app
3. Verify prices update (check lastUpdated timestamp)
4. Test offline: enable airplane mode, verify cached data displays

## Success Criteria

- [ ] Widget shows prices no more than 30 min old (with connectivity)
- [ ] Single API call per refresh (batched)
- [ ] Cached fallback on network failure
- [ ] Staleness indicator at 60+ minutes
- [ ] P&L calculations match main app
