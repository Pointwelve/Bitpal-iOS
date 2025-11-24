# Data Model: Watchlist Feature

**Feature**: 001-watchlist
**Date**: 2025-11-08
**Status**: Final

## Overview

This document defines all data models for the Watchlist feature, including entity structures, relationships, validation rules, and state management patterns.

---

## Entity Definitions

### 1. Coin (API Response Model)

**Purpose**: Represents a cryptocurrency from CoinGecko API with current market data.

**Type**: Struct (value type, from API responses)

**Storage**: In-memory cache only (NOT persisted)

**Definition**:
```swift
import Foundation

/// Represents a cryptocurrency from CoinGecko API
struct Coin: Identifiable, Codable, Equatable {
    let id: String              // CoinGecko ID (e.g., "bitcoin")
    let symbol: String          // Ticker symbol (e.g., "btc")
    let name: String            // Display name (e.g., "Bitcoin")
    var currentPrice: Decimal   // Current USD price
    var priceChange24h: Decimal // 24h change percentage
    var lastUpdated: Date       // Last price update timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case currentPrice = "current_price"
        case priceChange24h = "price_change_percentage_24h"
        case lastUpdated = "last_updated"
    }
}
```

**Attributes**:

| Field | Type | Description | Constraints | Source |
|-------|------|-------------|-------------|--------|
| `id` | String | CoinGecko unique identifier | Non-empty, immutable | API |
| `symbol` | String | Ticker symbol (lowercase) | Non-empty, immutable | API |
| `name` | String | Human-readable name | Non-empty, immutable | API |
| `currentPrice` | Decimal | Current price in USD | > 0, **MUST use Decimal** per Constitution | API |
| `priceChange24h` | Decimal | 24h % change | Can be negative, **MUST use Decimal** | API |
| `lastUpdated` | Date | Last update timestamp | Not in future | API |

**Validation Rules**:
- `id`, `symbol`, `name` MUST NOT be empty
- `currentPrice` MUST be positive (> 0)
- `priceChange24h` can be positive, negative, or zero
- `lastUpdated` MUST be <= current time (not in future)

**Equatable Implementation**:
```swift
// Coin is Equatable for efficient SwiftUI updates
// Two coins are equal if id matches and price data matches
extension Coin {
    static func == (lhs: Coin, rhs: Coin) -> Bool {
        lhs.id == rhs.id &&
        lhs.currentPrice == rhs.currentPrice &&
        lhs.priceChange24h == rhs.priceChange24h
    }
}
```

**Example**:
```swift
let bitcoin = Coin(
    id: "bitcoin",
    symbol: "btc",
    name: "Bitcoin",
    currentPrice: 45000.50,
    priceChange24h: 2.5,
    lastUpdated: Date()
)
```

---

### 2. WatchlistItem (Persistence Model)

**Purpose**: Tracks which cryptocurrencies user has added to their watchlist.

**Type**: Class (reference type for Swift Data @Model)

**Storage**: Swift Data (local persistence)

**Definition**:
```swift
import SwiftData
import Foundation

@Model
final class WatchlistItem {
    @Attribute(.unique) var coinId: String
    var dateAdded: Date
    var sortOrder: Int  // Reserved for future manual reordering

    init(coinId: String, dateAdded: Date = Date(), sortOrder: Int = 0) {
        self.coinId = coinId
        self.dateAdded = dateAdded
        self.sortOrder = sortOrder
    }
}
```

**Attributes**:

| Field | Type | Description | Constraints | Default |
|-------|------|-------------|-------------|---------|
| `coinId` | String | Reference to Coin.id | Non-empty, **unique** | Required |
| `dateAdded` | Date | When coin was added | Not in future | Current time |
| `sortOrder` | Int | Manual sort position (future) | >= 0 | 0 |

**Validation Rules**:
- `coinId` MUST match a valid CoinGecko coin ID
- `coinId` MUST be unique (enforced by @Attribute(.unique))
- `dateAdded` defaults to current timestamp
- `sortOrder` defaults to 0 (unused in Phase 1, reserved for future)

**Uniqueness Constraint**:
- Swift Data enforces uniqueness on `coinId`
- Attempting to insert duplicate `coinId` triggers save error
- UI MUST check for duplicates before inserting

**Relationships**:
- **Foreign Key**: `coinId` references `Coin.id` (not enforced by Swift Data, logical relationship)
- **One-to-One**: Each WatchlistItem corresponds to one Coin
- **Lookup**: Join WatchlistItem with Coin data via `coinId`

**Example**:
```swift
let watchlistItem = WatchlistItem(coinId: "bitcoin")
// dateAdded = Date() (now)
// sortOrder = 0
```

---

### 3. CoinListItem (Search Model)

**Purpose**: Lightweight model for cryptocurrency search results (no price data).

**Type**: Struct (value type)

**Storage**: In-memory cache (7-day TTL)

**Definition**:
```swift
import Foundation

/// Lightweight coin metadata for search functionality
struct CoinListItem: Codable, Identifiable {
    let id: String      // CoinGecko ID
    let symbol: String  // Ticker symbol
    let name: String    // Display name

    // Identifiable conformance
    var id: String { id }
}
```

**Attributes**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | String | CoinGecko unique identifier | Non-empty |
| `symbol` | String | Ticker symbol (lowercase) | Non-empty |
| `name` | String | Human-readable name | Non-empty |

**Validation Rules**:
- All fields MUST NOT be empty
- Used only for display in search results (no price data)

**Usage**:
- Cached from CoinGecko `/coins/list` endpoint
- Filtered locally for search autocomplete
- Converted to `Coin` after user selects and fetches market data

**Example**:
```json
[
  {"id": "bitcoin", "symbol": "btc", "name": "Bitcoin"},
  {"id": "ethereum", "symbol": "eth", "name": "Ethereum"}
]
```

---

## Relationships

### WatchlistItem ↔ Coin

**Relationship Type**: One-to-One (logical, not enforced)

**Description**: Each `WatchlistItem` references one `Coin` via `coinId`. Coin data is fetched from CoinGecko API using this ID.

**Diagram**:
```
┌────────────────┐         coinId         ┌──────────────┐
│ WatchlistItem  │ ─────────────────────> │     Coin     │
│                │                         │              │
│ coinId (FK)    │                         │ id (PK)      │
│ dateAdded      │                         │ name         │
│ sortOrder      │                         │ symbol       │
└────────────────┘                         │ currentPrice │
                                           │ priceChange  │
                                           └──────────────┘

Storage:                                   Storage:
Swift Data                                 In-memory cache
(persisted)                                (ephemeral)
```

**Join Operation** (in ViewModel):
```swift
// WatchlistViewModel
func loadWatchlistWithPrices() async {
    let watchlistItems = fetchWatchlistItems() // From Swift Data
    let coinIds = watchlistItems.map { $0.coinId }

    do {
        let coins = try await CoinGeckoService.shared.fetchMarketData(coinIds: coinIds)
        // coins is [String: Coin] dictionary keyed by coinId

        self.watchlistCoins = watchlistItems.compactMap { item in
            guard let coin = coins[item.coinId] else { return nil }
            return (item, coin) // Tuple of WatchlistItem + Coin
        }
    } catch {
        Logger.api.error("Failed to load prices: \(error)")
        // Show cached data or error state
    }
}
```

---

## State Management

### ViewModel State

**WatchlistViewModel** manages combined state from multiple sources:

```swift
import Observation
import SwiftData

@Observable
final class WatchlistViewModel {
    // MARK: - State

    // Combined watchlist data (WatchlistItem + Coin)
    var watchlistCoins: [(WatchlistItem, Coin)] = []

    // UI state
    var isLoading = false
    var errorMessage: String?
    var sortOption: SortOption = .name
    var lastUpdateTime: Date?

    // MARK: - Computed Properties

    var sortedWatchlist: [(WatchlistItem, Coin)] {
        switch sortOption {
        case .name:
            return watchlistCoins.sorted { $0.1.name < $1.1.name }
        case .price:
            return watchlistCoins.sorted { $0.1.currentPrice > $1.1.currentPrice }
        case .change24h:
            return watchlistCoins.sorted { $0.1.priceChange24h > $1.1.priceChange24h }
        }
    }

    var isUpToDate: Bool {
        guard let lastUpdate = lastUpdateTime else { return false }
        return Date().timeIntervalSince(lastUpdate) < 30 // Within 30s
    }

    // MARK: - Dependencies

    private let coinGeckoService: CoinGeckoService
    private let priceUpdateService: PriceUpdateService

    init(
        coinGeckoService: CoinGeckoService = .shared,
        priceUpdateService: PriceUpdateService = .shared
    ) {
        self.coinGeckoService = coinGeckoService
        self.priceUpdateService = priceUpdateService
    }

    // MARK: - Actions (see implementation in code)
}

enum SortOption: String, CaseIterable {
    case name = "Name (A-Z)"
    case price = "Price (High-Low)"
    case change24h = "24h Change (Best-Worst)"
}
```

### State Transitions

```
[Initial State]
     |
     v
[Loading watchlist from Swift Data]
     |
     v
[Fetching prices from API]
     |
     +--[Success]─────> [Display watchlist]
     |                         |
     +--[Error]────────> [Show cached data + error]
                               |
     v                         v
[Periodic updates every 30s] <─┘
     |
     +--[Success]─────> [Update prices in UI]
     |
     +--[Error]────────> [Keep showing old data + retry]
```

---

## Caching Strategy

### Two-Tier Caching (Per Constitution Principle I)

**Tier 1: In-Memory Cache** (Fast, Ephemeral)
```swift
final class CoinDataCache {
    // Singleton
    static let shared = CoinDataCache()

    // In-memory cache
    private var memoryCache: [String: Coin] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheTTL: TimeInterval = 60 // 1 minute

    func getCoin(id: String) -> Coin? {
        guard let coin = memoryCache[id],
              let timestamp = cacheTimestamps[id],
              Date().timeIntervalSince(timestamp) < cacheTTL else {
            return nil
        }
        return coin
    }

    func setCoin(_ coin: Coin) {
        memoryCache[coin.id] = coin
        cacheTimestamps[coin.id] = Date()
    }

    func invalidate(coinId: String) {
        memoryCache.removeValue(forKey: coinId)
        cacheTimestamps.removeValue(forKey: coinId)
    }

    func invalidateAll() {
        memoryCache.removeAll()
        cacheTimestamps.removeAll()
    }
}
```

**Tier 2: Swift Data** (Persistent, Survives Restarts)
- `WatchlistItem` persisted permanently
- Coin price data NOT persisted (always fresh from API)
- Rationale: Stale prices are misleading; always fetch latest from API

---

## Validation & Error Handling

### Data Validation

**Before Insertion**:
```swift
func addCoinToWatchlist(coinId: String) throws {
    // Validate coinId
    guard !coinId.isEmpty else {
        throw WatchlistError.invalidCoinId
    }

    // Check for duplicates
    if watchlistContains(coinId: coinId) {
        throw WatchlistError.coinAlreadyExists
    }

    // Create and insert
    let item = WatchlistItem(coinId: coinId)
    modelContext.insert(item)

    do {
        try modelContext.save()
    } catch {
        throw WatchlistError.saveFailed(error)
    }
}
```

### Error Types

```swift
enum WatchlistError: LocalizedError {
    case invalidCoinId
    case coinAlreadyExists
    case coinNotFound
    case saveFailed(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCoinId:
            return "Invalid cryptocurrency ID"
        case .coinAlreadyExists:
            return "This coin is already in your watchlist"
        case .coinNotFound:
            return "Cryptocurrency not found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

---

## Schema Evolution

### Phase 1 Schema (MVP)

Current schema as defined above. No migrations needed (initial version).

### Future Schema Changes (Planned but NOT Implemented)

**Phase 2: Wallet Integration**
- Add `WalletAddress` model
- Add `walletId` foreign key to `WatchlistItem`? (TBD)

**Phase 3+: Advanced Features**
- Add `sortOrder` usage for manual reordering
- Add `category` field for user-defined categories
- Add `notes` field for personal annotations

**Migration Strategy**:
- Swift Data handles automatic migrations for additive changes
- For breaking changes, define `VersionedSchema` migrations
- See: https://developer.apple.com/documentation/swiftdata/migration

---

## Compliance Checklist

- [x] Financial values use `Decimal` type (Constitution Principle IV)
- [x] Models conform to `Codable` for API parsing
- [x] `Coin` is struct (value type, per Constitution Principle III)
- [x] `WatchlistItem` uses Swift Data (NOT Core Data, per Constitution)
- [x] Uniqueness constraints enforced (`coinId` unique)
- [x] No premature optimization for future phases (Principle V)
- [x] Error handling documented
- [x] Caching strategy two-tier (memory + Swift Data, Principle I)

**Status**: ✅ Data model complete and Constitution-compliant
