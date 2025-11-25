# Research: Watchlist Feature

**Feature**: 001-watchlist
**Date**: 2025-11-08
**Status**: Complete

## Overview

This document captures technical research and decisions for implementing the Watchlist feature. All research follows Constitution v1.0.0 principles and CLAUDE.md guidelines.

---

## 1. CoinGecko API Integration

### Decision

Use CoinGecko free tier API with two endpoints:
- `/coins/list` - Get all available coins for search (cached 7 days)
- `/coins/markets` - Get market data for watchlist coins (batched requests)

### Rationale

**Why CoinGecko**:
- Free tier: 50 calls/minute, 10K-30K calls/month (sufficient for MVP)
- No API key required for basic endpoints
- Comprehensive cryptocurrency coverage (10,000+ coins)
- Reliable uptime and documentation

**Why these endpoints**:
- `/coins/list` returns lightweight data (id, symbol, name) - perfect for search autocomplete
- `/coins/markets` returns full market data in single request - enables batching per Constitution Principle I

**Rate limiting strategy**:
```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.2 // 50/min = ~1.2s between calls

    func waitIfNeeded() async {
        if let last = lastRequestTime {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < minimumInterval {
                try? await Task.sleep(for: .seconds(minimumInterval - elapsed))
            }
        }
        lastRequestTime = Date()
    }
}
```

### Alternatives Considered

- **CoinCap API**: Considered but less comprehensive coin coverage
- **CryptoCompare**: Requires API key even for free tier
- **Binance API**: Limited to Binance-listed coins only

### Implementation Notes

**Batch request example**:
```swift
// ✅ GOOD: Fetch all watchlist coins in one request
let coinIds = ["bitcoin", "ethereum", "cardano"].joined(separator: ",")
let url = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=\(coinIds)&price_change_percentage=24h"

// ❌ BAD: Individual requests (violates Constitution Principle I)
for coinId in coinIds {
    await fetchPrice(for: coinId) // FORBIDDEN
}
```

**Response structure** (from actual API):
```json
[
  {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin",
    "current_price": 45000.50,
    "price_change_percentage_24h": 2.5,
    "last_updated": "2025-01-15T10:30:00.000Z"
  }
]
```

**Error handling**:
- Network errors: Show cached data + "Offline" indicator
- Rate limit (429): Exponential backoff, show last cached data
- Invalid response: Log error, skip invalid coins, show partial data

### References

- CoinGecko API Docs: https://docs.coingecko.com/reference/introduction
- CLAUDE.md lines 651-799 (API Integration section)

---

## 2. Swift Data Watchlist Persistence

### Decision

Use Swift Data with `@Model` for `WatchlistItem`:
```swift
@Model
final class WatchlistItem {
    @Attribute(.unique) var coinId: String
    var dateAdded: Date
    var sortOrder: Int  // For future manual reordering

    init(coinId: String, dateAdded: Date = Date(), sortOrder: Int = 0) {
        self.coinId = coinId
        self.dateAdded = dateAdded
        self.sortOrder = sortOrder
    }
}
```

### Rationale

**Why Swift Data**:
- Modern replacement for Core Data (Constitution Principle III)
- Type-safe with Swift macros (@Model)
- SwiftUI integration via @Query
- Automatic schema migrations
- Better performance than Core Data for simple models

**Why coinId as unique**:
- Prevents duplicate coins in watchlist
- CoinGecko uses stable IDs ("bitcoin", "ethereum")
- Enables fast lookups and relationship with Coin model

**Why dateAdded**:
- Allows sorting by "Recently Added"
- Useful for future features (e.g., "What's new")

**Why sortOrder**:
- Placeholder for Phase 2+ manual reordering
- Defaults to 0 (not used in Phase 1)

### Alternatives Considered

- **UserDefaults**: Too limited for complex queries and large datasets
- **Core Data**: Legacy, more boilerplate than Swift Data
- **JSON files**: No query support, manual persistence handling

### Implementation Notes

**Model Container setup** (in BitpalApp.swift):
```swift
import SwiftUI
import SwiftData

@main
struct BitpalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WatchlistItem.self])
    }
}
```

**Querying in SwiftUI**:
```swift
import SwiftData

struct WatchlistView: View {
    @Query(sort: \WatchlistItem.dateAdded, order: .reverse)
    private var watchlistItems: [WatchlistItem]

    var body: some View {
        // Use watchlistItems...
    }
}
```

**Adding item**:
```swift
@Environment(\.modelContext) private var modelContext

func addCoin(coinId: String) {
    let item = WatchlistItem(coinId: coinId)
    modelContext.insert(item)
    try? modelContext.save()
}
```

### References

- Swift Data Docs: https://developer.apple.com/documentation/swiftdata
- CLAUDE.md lines 931-991 (Swift Data Setup)

---

## 3. Background Price Updates

### Decision

Use Swift `Task` with `while !Task.isCancelled` loop for 30-second periodic updates:

```swift
final class PriceUpdateService {
    private var updateTask: Task<Void, Never>?
    private let updateInterval: TimeInterval = 30

    func startPeriodicUpdates(coinIds: [String], onUpdate: @Sendable @escaping ([String: Coin]) -> Void) {
        updateTask = Task {
            while !Task.isCancelled {
                do {
                    let prices = try await CoinGeckoService.shared.fetchPrices(coinIds: coinIds)
                    await MainActor.run {
                        onUpdate(prices)
                    }
                    try await Task.sleep(for: .seconds(updateInterval))
                } catch {
                    Logger.api.error("Price update failed: \(error)")
                    try? await Task.sleep(for: .seconds(updateInterval))
                }
            }
        }
    }

    func stopPeriodicUpdates() {
        updateTask?.cancel()
        updateTask = nil
    }
}
```

### Rationale

**Why Task over Timer**:
- Native async/await integration (Constitution Principle III)
- Easy cancellation with Task.cancel()
- No Combine dependency (FORBIDDEN per Constitution)
- Automatic backpressure (won't queue if previous update slow)

**Why 30 seconds**:
- Per Constitution Principle I: "30-second intervals, real-time FORBIDDEN"
- Balances freshness with battery/network efficiency
- CoinGecko rate limits respected (max 2 requests/minute per user)

**Why MainActor.run for UI updates**:
- Constitution Principle I: "UI updates MUST occur on MainActor"
- Prevents UI blocking while API calls happen in background

### Alternatives Considered

- **Timer**: Requires Combine or RunLoop, less clean with async/await
- **Background Tasks API**: Overkill for foreground updates, 15-minute minimum intervals
- **Real-time WebSocket**: FORBIDDEN by Constitution (battery drain, complexity)

### Implementation Notes

**Lifecycle management**:
```swift
// In WatchlistViewModel
func startUpdates() {
    guard !isUpdating else { return }
    isUpdating = true

    priceService.startPeriodicUpdates(coinIds: watchlistCoinIds) { [weak self] prices in
        self?.updatePrices(prices)
    }
}

func stopUpdates() {
    priceService.stopPeriodicUpdates()
    isUpdating = false
}

// Called on view appear/disappear
.onAppear { viewModel.startUpdates() }
.onDisappear { viewModel.stopUpdates() }
```

**Battery optimization**:
- Updates stop when view disappears (no background polling)
- Exponential backoff on errors
- Batch API requests (all coins at once)

### References

- CLAUDE.md lines 147-166 (Throttled Price Updates)
- Swift Concurrency Docs: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/

---

## 4. Search Implementation

### Decision

**Local-first search** with cached CoinGecko `/coins/list` data:

1. Fetch full coin list on first launch (cache for 7 days)
2. Store in-memory array of `CoinListItem` structs
3. Filter locally using Swift `filter` with case-insensitive contains
4. Debounce search input (300ms) to reduce UI churn

```swift
final class CoinSearchViewModel {
    @Published var searchQuery = ""
    @Published var searchResults: [CoinListItem] = []

    private var allCoins: [CoinListItem] = []
    private var searchTask: Task<Void, Never>?

    func performSearch() {
        searchTask?.cancel()

        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300)) // Debounce

            guard !Task.isCancelled else { return }

            let query = searchQuery.lowercased()
            let results = allCoins.filter { coin in
                coin.name.lowercased().contains(query) ||
                coin.symbol.lowercased().contains(query) ||
                coin.id.lowercased().contains(query)
            }

            await MainActor.run {
                searchResults = Array(results.prefix(50)) // Limit results
            }
        }
    }
}
```

### Rationale

**Why local search**:
- Instant results (<100ms vs >1s for API call)
- No network required after initial load
- No rate limit concerns
- Meets <1s search requirement (SC-004)

**Why 7-day cache**:
- Coin list changes infrequently (new coins added weekly/monthly)
- Reduces API calls and app launch time
- User can manually refresh if needed

**Why 300ms debounce**:
- Prevents excessive filtering on rapid typing
- Smooth UX without perceived lag
- Reduces unnecessary computations

**Why 50 result limit**:
- Prevents overwhelming UI
- LazyVStack handles efficiently
- User can refine search if needed

### Alternatives Considered

- **API search**: Slower (>1s), rate limit issues, requires network
- **CoreSpotlight**: Overkill for in-app search
- **No debounce**: Choppy UI, excessive filtering

### Implementation Notes

**Caching strategy**:
```swift
// Load coin list on first launch
func loadCoinList() async {
    if let cached = loadFromCache(), cached.age < 7.days {
        allCoins = cached.coins
        return
    }

    do {
        let coins = try await CoinGeckoService.shared.fetchCoinList()
        allCoins = coins
        saveToCache(coins)
    } catch {
        Logger.api.error("Failed to load coin list: \(error)")
        // Fall back to cached data if available
    }
}
```

**UI responsiveness**:
- Show "No results" only after 300ms (prevent flicker)
- Display "Searching..." indicator for long queries
- Cancel search on sheet dismiss

### References

- CLAUDE.md lines 700-701 (Coin List caching)

---

## 5. LazyVStack Performance Optimization

### Decision

**Use LazyVStack with Equatable CoinRowView**:

```swift
// ✅ GOOD: LazyVStack for efficient rendering
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(coins) { coin in
            CoinRowView(coin: coin)
                .equatable()
        }
    }
}

// ✅ GOOD: Equatable prevents unnecessary re-renders
struct CoinRowView: View, Equatable {
    let coin: Coin

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.coin.id == rhs.coin.id &&
        lhs.coin.currentPrice == rhs.coin.currentPrice &&
        lhs.coin.priceChange24h == rhs.coin.priceChange24h
    }

    var body: some View {
        // Row content...
    }
}
```

### Rationale

**Why LazyVStack**:
- Constitution Principle I: "Lists >10 items MUST use LazyVStack"
- Only renders visible rows + small buffer
- Crucial for 60fps with 50+ coins
- Reduces memory footprint

**Why Equatable**:
- Prevents re-rendering when unrelated state changes
- Only updates when coin price/change actually changes
- Critical for smooth price updates

**Why 12pt spacing**:
- Matches Liquid Glass design (CLAUDE.md line 405)
- Visual breathing room without wasted space

### Alternatives Considered

- **Regular VStack**: Renders all rows upfront, poor performance >20 items
- **List**: More opinionated styling, less control over Liquid Glass design
- **UIViewRepresentable + UITableView**: Unnecessary complexity for SwiftUI

### Implementation Notes

**Full CoinRowView example**:
```swift
struct CoinRowView: View, Equatable {
    let coin: Coin

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.coin.id == rhs.coin.id &&
        lhs.coin.currentPrice == rhs.coin.currentPrice &&
        lhs.coin.priceChange24h == rhs.coin.priceChange24h
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.name)
                    .font(.title3)
                    .foregroundColor(.primary)

                Text(coin.symbol.uppercased())
                    .font(.callout)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(coin.currentPrice.formatted(.currency(code: "USD")))
                    .font(.title3)
                    .foregroundColor(.primary)

                PriceChangeLabel(change: coin.priceChange24h)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
```

**Performance validation**:
- Use Xcode Instruments Time Profiler
- Verify 60fps during scrolling (16.67ms per frame max)
- Test with 100+ coins to stress test

### References

- CLAUDE.md lines 237-265 (Efficient List Rendering)
- Constitution Principle I (LazyVStack requirement)

---

## Research Completeness Checklist

- [x] CoinGecko API integration researched (endpoints, rate limits, batching)
- [x] Swift Data persistence researched (model structure, querying, insertion)
- [x] Background price updates researched (Task vs Timer, 30s intervals)
- [x] Search implementation researched (local-first, caching, debouncing)
- [x] LazyVStack performance researched (Equatable, rendering optimization)
- [x] All decisions align with Constitution v1.0.0
- [x] All alternatives considered and documented
- [x] Code examples provided for each decision
- [x] References to CLAUDE.md included

**Status**: ✅ Research complete - Ready for Phase 1 (Design & Contracts)
