# Bitpal - iOS Crypto Portfolio Tracker

## Project Overview

**Bitpal** is a performance-first cryptocurrency portfolio tracking application for iOS. The core value proposition is **speed and smoothness** - providing a buttery smooth, lag-free experience that solves the frustration of slow, laggy portfolio apps (like getquin).

### Primary Goal
Deliver the fastest, smoothest crypto portfolio tracking experience on iOS.

### Secondary Goal
Generate potential side income through ads and premium subscriptions (Phase 3+).

### Developer Context
This is a focused MVP project emphasizing clean architecture, modern Swift patterns, and exceptional performance. The goal is to ship a polished Phase 1 quickly, then iterate based on user feedback.

---

## Phase 1 MVP Scope

### ✅ Features to Build NOW

#### 1. Watchlist
- **Search cryptocurrencies** via CoinGecko API
- **Add coins** to watchlist
- **Display data**: coin name, symbol, current price, 24h price change (%)
- **Sort options**: by name (A-Z), price (high-low), 24h change (best-worst)
- **Remove coins** from watchlist (swipe to delete)
- **Pull to refresh** to update prices
- **Persistent storage** using Swift Data

#### 2. Manual Portfolio
- **Add transactions** manually:
  - Coin selection (from CoinGecko data)
  - Quantity (decimal support, e.g., 0.5 BTC)
  - Purchase price per coin
  - Transaction date (date picker)
  - Optional notes
  - Transaction type: Buy or Sell
- **Display holdings**:
  - Coin name and symbol
  - Total quantity held
  - Average cost per coin
  - Current value (quantity × current price)
  - Profit/Loss (absolute $ and %)
  - Profit/Loss color coding (green/red)
- **Portfolio summary** at top:
  - Total portfolio value
  - Total profit/loss ($ and %)
- **Simple list view** (no charts in Phase 1)
- **Transaction history** accessible per coin
- **Edit/delete transactions**
- **Persistent storage** using Swift Data

### ❌ Explicitly OUT OF SCOPE for Phase 1

Do NOT implement these features in the MVP:

- Wallet integration (monitor blockchain addresses)
- Multiple portfolios
- Charts or graphs (price history, performance over time)
- Price alerts/notifications
- Home screen widgets
- Ads or monetization features
- Social features (sharing, leaderboards)
- News feeds or market updates
- Dark/Light mode toggle (use system setting only)
- iCloud sync
- Export functionality (CSV, PDF)
- Biometric authentication
- Onboarding tutorial

---

## Technical Stack & Architecture

### Platform Requirements
- **iOS 26+** (released September 2025)
- **Xcode 17+**
- **Swift 6.0+**

### Core Technologies

```swift
// Modern SwiftUI with @Observable (NOT ObservableObject)
import SwiftUI
import Observation

@Observable
final class WatchlistViewModel {
    var coins: [Coin] = []
    var isLoading = false
    // NO @Published needed with @Observable
}
```

#### Technology Choices

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **UI Framework** | SwiftUI | Modern, declarative, built-in performance optimizations |
| **State Management** | @Observable macro | Modern Swift, less boilerplate than ObservableObject |
| **Architecture** | MVVM | Lightweight, familiar, sufficient for MVP scope |
| **Persistence** | Swift Data | Modern, type-safe, native to Swift |
| **Networking** | URLSession + async/await | Native, no dependencies |
| **API** | CoinGecko (free tier) | Reliable, generous free tier, no auth required |

#### What We're NOT Using (and why)

- ❌ **TCA (The Composable Architecture)**: Too heavy for MVP, adds complexity
- ❌ **Combine**: @Observable + async/await are simpler and more modern
- ❌ **Core Data**: Swift Data is the modern replacement
- ❌ **Third-party networking** (Alamofire): URLSession is sufficient
- ❌ **External dependencies**: Keep it lean for fast build times

### Architecture Pattern: MVVM

```
┌─────────────┐
│    View     │  SwiftUI views (stateless, declarative)
└──────┬──────┘
       │
┌──────▼──────┐
│  ViewModel  │  @Observable classes (business logic, state)
└──────┬──────┘
       │
┌──────▼──────┐
│   Service   │  API calls, data persistence
└──────┬──────┘
       │
┌──────▼──────┐
│    Model    │  Data structures
└─────────────┘
```

**Guidelines:**
- **Views**: Pure SwiftUI, no business logic, reference ViewModels
- **ViewModels**: @Observable classes, handle user actions, update state
- **Services**: Singletons for API and persistence operations
- **Models**: Structs for data, conform to Codable/Identifiable as needed

---

## Performance Guidelines (Critical - Our Differentiator)

Performance is **the** core value proposition. Every decision should prioritize smoothness and responsiveness.

### 1. Throttled Price Updates

```swift
// ✅ GOOD: Update every 30 seconds, not real-time
final class PriceUpdateService {
    private let updateInterval: TimeInterval = 30 // seconds

    func startPeriodicUpdates() async {
        while !Task.isCancelled {
            await updatePrices()
            try? await Task.sleep(for: .seconds(updateInterval))
        }
    }
}

// ❌ BAD: Real-time updates will hammer the API and drain battery
```

**Rationale**: Real-time updates are unnecessary for portfolio tracking and waste resources. 30-second intervals provide fresh data without performance cost.

### 2. Batch API Requests

```swift
// ✅ GOOD: Fetch all coin prices in one request
let coinIds = ["bitcoin", "ethereum", "cardano"].joined(separator: ",")
let url = "https://api.coingecko.com/api/v3/simple/price?ids=\(coinIds)&vs_currencies=usd&include_24hr_change=true"

// ❌ BAD: Individual requests per coin
for coinId in coinIds {
    // Don't do this - makes 3 requests instead of 1
    await fetchPrice(for: coinId)
}
```

### 3. Cache Computed Values

```swift
@Observable
final class PortfolioViewModel {
    var holdings: [Holding] = []

    // ✅ GOOD: Cached computed property
    private var _totalValue: Decimal?
    var totalValue: Decimal {
        if let cached = _totalValue { return cached }
        let computed = holdings.reduce(0) { $0 + $1.currentValue }
        _totalValue = computed
        return computed
    }

    // Invalidate cache when holdings change
    func invalidateCache() {
        _totalValue = nil
    }
}
```

### 4. Aggressive Caching Strategy

**Two-tier caching:**
1. **In-memory cache**: Fast reads, cleared on app termination
2. **Swift Data cache**: Persistent, survives app restarts

```swift
final class CoinDataCache {
    // Tier 1: In-memory (fastest)
    private var memoryCache: [String: Coin] = [:]

    // Tier 2: Swift Data (persistent)
    @Query private var cachedCoins: [CachedCoin]

    func getCoin(id: String) async -> Coin? {
        // Check memory first
        if let cached = memoryCache[id] {
            return cached
        }

        // Check persistent cache
        if let persistent = cachedCoins.first(where: { $0.id == id }) {
            let coin = persistent.toCoin()
            memoryCache[id] = coin // Promote to memory
            return coin
        }

        // Cache miss - fetch from API
        return await fetchFromAPI(id: id)
    }
}
```

### 5. Efficient List Rendering

```swift
// ✅ GOOD: Use LazyVStack for long lists
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(coins) { coin in
            CoinRowView(coin: coin)
        }
    }
}

// ✅ GOOD: Minimize view updates with Equatable
struct CoinRowView: View, Equatable {
    let coin: Coin

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.coin.id == rhs.coin.id &&
        lhs.coin.currentPrice == rhs.coin.currentPrice
    }
}

// ❌ BAD: Regular VStack loads all views upfront
VStack {
    ForEach(coins) { coin in
        CoinRowView(coin: coin)
    }
}
```

### 6. Background Refresh Without Blocking UI

```swift
// ✅ GOOD: Use Task with MainActor for UI updates
func refreshPrices() {
    Task {
        let newPrices = await priceService.fetchPrices() // Background thread

        await MainActor.run {
            self.updateUI(with: newPrices) // UI thread
        }
    }
}
```

### Performance Checklist

Before shipping any feature, verify:
- [ ] List scrolling is smooth (60fps minimum)
- [ ] No UI blocking during API calls
- [ ] Computed values are cached
- [ ] API requests are batched where possible
- [ ] Updates throttled to reasonable intervals
- [ ] LazyVStack used for lists > 10 items
- [ ] Animations are smooth and purposeful

---

## Design System: Liquid Glass (iOS 26)

### Overview

Bitpal follows the **Liquid Glass** design language introduced in iOS 26. This aesthetic emphasizes translucency, depth, and fluidity.

### Core Principles

1. **Translucent Materials**: Use glass-like backgrounds with blur
2. **Layering**: Create depth through overlapping translucent layers
3. **Smooth Animations**: Everything should feel fluid and responsive
4. **High Contrast**: Ensure readability despite translucent backgrounds
5. **Rounded Corners**: 12-16pt radius for cards and containers

### Material Usage

```swift
// Primary background material
.background(.ultraThinMaterial)

// Secondary container material
.background(.regularMaterial)

// Emphasized elements (buttons, highlights)
.background(.thickMaterial)
```

### Color Palette

```swift
extension Color {
    // Primary colors (use semantic colors, not hardcoded)
    static let profitGreen = Color.green
    static let lossRed = Color.red
    static let neutral = Color.secondary

    // Use system colors for adaptability
    static let cardBackground = Color(.systemBackground).opacity(0.6)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
}
```

### Typography

```swift
// Follow iOS 26 Dynamic Type
.font(.largeTitle)      // Portfolio total value
.font(.title)           // Section headers
.font(.title2)          // Coin names
.font(.title3)          // Emphasized values
.font(.body)            // Standard text
.font(.callout)         // Secondary info
.font(.caption)         // Tertiary info (timestamps, etc.)

// Enable dynamic type scaling
.dynamicTypeSize(.medium...accessibilityExtraLarge)
```

### Component Specifications

#### Card Component

```swift
struct LiquidGlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}
```

#### Spacing System

```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

#### Animation Standards

```swift
// Standard spring animation for interactive elements
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)

// Smooth easing for list updates
.animation(.easeInOut(duration: 0.2), value: sortOrder)

// Emphasized entrance
.transition(.scale.combined(with: .opacity))
```

### Layout Guidelines

- **Screen padding**: 16pt horizontal, 8pt top
- **Card spacing**: 12pt vertical between cards
- **Minimum tap target**: 44x44pt (iOS HIG)
- **Maximum content width**: 600pt (iPad optimization)

---

## Project Structure

Organize codebase by **feature folders** for clarity and scalability.

```
Bitpal/
├── App/
│   ├── BitpalApp.swift              # App entry point
│   └── ContentView.swift            # Root tab navigation
│
├── Features/
│   ├── Watchlist/
│   │   ├── Views/
│   │   │   ├── WatchlistView.swift
│   │   │   ├── CoinSearchView.swift
│   │   │   └── CoinRowView.swift
│   │   ├── ViewModels/
│   │   │   └── WatchlistViewModel.swift
│   │   └── Models/
│   │       └── WatchlistItem.swift
│   │
│   └── Portfolio/
│       ├── Views/
│       │   ├── PortfolioView.swift
│       │   ├── AddTransactionView.swift
│       │   ├── HoldingRowView.swift
│       │   └── TransactionHistoryView.swift
│       ├── ViewModels/
│       │   ├── PortfolioViewModel.swift
│       │   └── AddTransactionViewModel.swift
│       └── Models/
│           ├── Transaction.swift
│           └── Holding.swift
│
├── Services/
│   ├── CoinGeckoService.swift       # API client
│   ├── PersistenceService.swift     # Swift Data manager
│   └── PriceUpdateService.swift     # Background price updates
│
├── Models/
│   ├── Coin.swift                   # Shared coin model
│   └── APIResponse.swift            # API response models
│
├── Design/
│   ├── Components/
│   │   ├── LiquidGlassCard.swift
│   │   ├── PriceChangeLabel.swift
│   │   └── LoadingView.swift
│   ├── Styles/
│   │   ├── Colors.swift
│   │   ├── Spacing.swift
│   │   └── Typography.swift
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── Decimal+Extensions.swift
│
└── Utilities/
    ├── Logger.swift                 # Logging utilities
    ├── Constants.swift              # App-wide constants
    └── Formatters.swift             # Number/date formatters

BitpalTests/
└── (Unit tests organized by feature)

BitpalUITests/
└── (UI tests for critical flows)
```

### File Naming Conventions

- **Views**: `WatchlistView.swift`, `CoinRowView.swift`
- **ViewModels**: `WatchlistViewModel.swift`
- **Services**: `CoinGeckoService.swift`
- **Models**: `Coin.swift`, `Transaction.swift`
- **Extensions**: `View+Extensions.swift`

---

## Data Models

### Core Models

#### Coin (API Model)

```swift
import Foundation

/// Represents a cryptocurrency from CoinGecko API
struct Coin: Identifiable, Codable, Equatable {
    let id: String              // e.g., "bitcoin"
    let symbol: String          // e.g., "btc"
    let name: String            // e.g., "Bitcoin"
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

#### WatchlistItem (Swift Data Model)

```swift
import SwiftData
import Foundation

@Model
final class WatchlistItem {
    @Attribute(.unique) var coinId: String
    var dateAdded: Date
    var sortOrder: Int  // For manual reordering (future)

    init(coinId: String, dateAdded: Date = Date(), sortOrder: Int = 0) {
        self.coinId = coinId
        self.dateAdded = dateAdded
        self.sortOrder = sortOrder
    }
}
```

#### Transaction (Swift Data Model)

```swift
import SwiftData
import Foundation

@Model
final class Transaction {
    var id: UUID
    var coinId: String          // Reference to Coin.id
    var type: TransactionType   // Buy or Sell
    var amount: Decimal         // Quantity of coins
    var pricePerCoin: Decimal   // Purchase/sale price
    var date: Date
    var notes: String?

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

enum TransactionType: String, Codable {
    case buy
    case sell
}
```

#### Holding (Computed Model - NOT stored)

```swift
import Foundation

/// Computed from transactions and current prices - NOT persisted
struct Holding: Identifiable {
    let id: String              // coinId
    let coin: Coin              // Full coin details
    let totalAmount: Decimal    // Sum of buy - sell quantities
    let avgCost: Decimal        // Weighted average cost
    let currentValue: Decimal   // totalAmount × currentPrice

    var profitLoss: Decimal {
        currentValue - (totalAmount * avgCost)
    }

    var profitLossPercentage: Decimal {
        guard avgCost > 0 else { return 0 }
        return ((currentValue / (totalAmount * avgCost)) - 1) * 100
    }
}
```

### Calculation Logic

#### Computing Holdings from Transactions

```swift
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
                // Note: For avg cost, we don't subtract from totalCost
                // This gives a more accurate P&L calculation
            }
        }

        guard totalAmount > 0 else { return nil } // No holdings left

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

---

## API Integration: CoinGecko

### Base URL
```
https://api.coingecko.com/api/v3
```

### Free Tier Limits
- **50 calls/minute**
- **10,000-30,000 calls/month** (varies)
- No API key required for basic endpoints

### Rate Limiting Strategy
```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 1.2 // 50 req/min = ~1.2s between calls

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

### Endpoints to Use

#### 1. Get Coin List (for search)
```
GET /coins/list
```

**Response:**
```json
[
  {
    "id": "bitcoin",
    "symbol": "btc",
    "name": "Bitcoin"
  },
  ...
]
```

**Usage**: Cache this list locally, refresh weekly. Use for search autocomplete.

#### 2. Get Market Data (for watchlist)
```
GET /coins/markets?vs_currency=usd&ids=bitcoin,ethereum&order=market_cap_desc&per_page=100&page=1&sparkline=false&price_change_percentage=24h
```

**Parameters:**
- `vs_currency`: `usd`
- `ids`: Comma-separated coin IDs (e.g., `bitcoin,ethereum,cardano`)
- `price_change_percentage`: `24h`

**Response:**
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

#### 3. Get Simple Price (for portfolio updates)
```
GET /simple/price?ids=bitcoin,ethereum&vs_currencies=usd&include_24hr_change=true
```

**Response:**
```json
{
  "bitcoin": {
    "usd": 45000.50,
    "usd_24h_change": 2.5
  },
  "ethereum": {
    "usd": 3200.75,
    "usd_24h_change": -1.2
  }
}
```

**Usage**: Use this for batch price updates. More lightweight than `/markets`.

### Service Implementation Example

```swift
import Foundation

final class CoinGeckoService {
    static let shared = CoinGeckoService()

    private let baseURL = "https://api.coingecko.com/api/v3"
    private let rateLimiter = RateLimiter()

    private init() {}

    // Fetch current prices for multiple coins
    func fetchPrices(coinIds: [String]) async throws -> [String: Decimal] {
        await rateLimiter.waitIfNeeded()

        let ids = coinIds.joined(separator: ",")
        let urlString = "\(baseURL)/simple/price?ids=\(ids)&vs_currencies=usd"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: PriceData].self, from: data)

        return response.mapValues { Decimal($0.usd) ?? 0 }
    }

    // Search coins by query
    func searchCoins(query: String) async throws -> [Coin] {
        // Implementation using cached coin list
    }
}

struct PriceData: Codable {
    let usd: Double
}

enum APIError: Error {
    case invalidURL
    case rateLimitExceeded
    case invalidResponse
}
```

### Caching Strategy

1. **Coin List**: Cache for 7 days, refresh in background
2. **Prices**: Cache for 30 seconds (matches update interval)
3. **Market Data**: Cache for 1 minute

---

## Development Guidelines

### Code Style

- Use **Swift 6.0** features (strict concurrency, typed throws)
- Follow **Swift API Design Guidelines**
- Use `async/await` over completion handlers
- Prefer `struct` over `class` unless reference semantics needed
- Use `@Observable` for ViewModels (not `ObservableObject`)
- Keep functions under 30 lines
- Avoid force unwrapping (`!`) - use `guard` or `if let`

### Error Handling

```swift
// Use typed errors
enum WatchlistError: LocalizedError {
    case coinNotFound
    case alreadyAdded
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .coinNotFound:
            return "Cryptocurrency not found"
        case .alreadyAdded:
            return "This coin is already in your watchlist"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// Display errors to user
struct WatchlistView: View {
    @State private var errorMessage: String?

    var body: some View {
        // ...
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
```

### Testing Strategy

Focus on **critical business logic** and **data integrity**.

**Priority for testing:**
1. Transaction calculations (holdings, P&L)
2. API response parsing
3. Swift Data operations
4. Price update logic

**Skip testing:**
- SwiftUI views (use manual testing)
- Simple getters/setters

```swift
// Example test
import XCTest
@testable import Bitpal

final class HoldingCalculationTests: XCTestCase {
    func testProfitCalculation() {
        let coin = Coin(
            id: "bitcoin",
            symbol: "btc",
            name: "Bitcoin",
            currentPrice: 50000,
            priceChange24h: 2.5,
            lastUpdated: Date()
        )

        let holding = Holding(
            id: "bitcoin",
            coin: coin,
            totalAmount: 1.0,
            avgCost: 40000,
            currentValue: 50000
        )

        XCTAssertEqual(holding.profitLoss, 10000)
        XCTAssertEqual(holding.profitLossPercentage, 25)
    }
}
```

### Logging

Use unified logging for debugging.

```swift
import OSLog

extension Logger {
    static let api = Logger(subsystem: "com.bitpal.app", category: "API")
    static let persistence = Logger(subsystem: "com.bitpal.app", category: "Persistence")
    static let ui = Logger(subsystem: "com.bitpal.app", category: "UI")
}

// Usage
Logger.api.info("Fetching prices for \(coinIds.count) coins")
Logger.persistence.error("Failed to save transaction: \(error)")
```

### Performance Monitoring

```swift
// Use Instruments to profile:
// - Time Profiler: Identify slow functions
// - Allocations: Detect memory leaks
// - Network: Monitor API usage

// Add performance markers
import OSLog

let signpost = OSSignposter(logger: Logger.ui)
let state = signpost.beginInterval("LoadWatchlist")
// ... load data
signpost.endInterval("LoadWatchlist", state)
```

---

## Swift Data Setup

### Model Container Configuration

```swift
import SwiftUI
import SwiftData

@main
struct BitpalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WatchlistItem.self, Transaction.self])
    }
}
```

### Querying Data

```swift
import SwiftData

struct PortfolioView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    var body: some View {
        // Use transactions...
    }
}
```

### Inserting/Updating Data

```swift
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext

    func saveTransaction() {
        let transaction = Transaction(
            coinId: selectedCoin.id,
            type: .buy,
            amount: amount,
            pricePerCoin: pricePerCoin,
            date: date
        )

        modelContext.insert(transaction)

        do {
            try modelContext.save()
        } catch {
            Logger.persistence.error("Failed to save: \(error)")
        }
    }
}
```

---

## Navigation Structure

### Tab-Based Navigation

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }

            PortfolioView()
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
        }
    }
}
```

### Navigation Flow

```
ContentView (TabView)
├── Watchlist Tab
│   ├── WatchlistView (List)
│   └── CoinSearchView (Sheet)
│
└── Portfolio Tab
    ├── PortfolioView (List)
    ├── AddTransactionView (Sheet)
    └── TransactionHistoryView (Navigation Push)
```

---

## Future Phases (Reference Only - DO NOT Implement)

### Phase 2: Wallet Integration (Q2 2026)

**Goal**: Automatically track portfolio by monitoring blockchain addresses.

**Features:**
- Add wallet addresses (Bitcoin, Ethereum, etc.)
- Background job detects new transactions
- User approval flow for importing transactions
- Edit imported transactions before adding to portfolio

**Technical Approach:**
- Use blockchain explorers APIs (Blockchain.com, Etherscan)
- Background Tasks framework for periodic scanning
- Transaction deduplication logic

**User Flow:**
```
1. User adds wallet address → Stored in Swift Data
2. Background task runs every 6 hours
3. Fetch new transactions from blockchain
4. Show pending import list to user
5. User selects which to import (can edit before importing)
6. Imported transactions added to portfolio
```

**Why This Approach:**
Gives user control instead of messy auto-sync. Avoids confusion from dust transactions or test sends.

### Phase 3: Monetization (Q3 2026)

**Revenue Streams:**
1. **Premium Subscription** ($4.99/month or $39.99/year):
   - Unlimited portfolios
   - Price alerts
   - Advanced charts
   - Export data (CSV, PDF)
   - Priority support

2. **Ads** (Free tier):
   - Google AdMob banner ads
   - Interstitial ads (limit: once per session)
   - Respectful placement (bottom of lists, not intrusive)

**Technical:**
- Use StoreKit 2 for IAP
- Google AdMob SDK for ads
- Feature flags to toggle premium features

### Phase 4: Advanced Features (2027+)

**Possible features** (based on user feedback):
- Home screen widgets (price glances, portfolio value)
- Interactive charts (TradingView-style)
- Price alerts with notifications
- iCloud sync (multi-device)
- Watch app (quick glances)
- Siri shortcuts ("Hey Siri, what's my portfolio worth?")
- DeFi protocol integration (Uniswap positions, staking)

---

## Success Metrics (Phase 1)

### Primary KPIs
- **Performance**: Smooth 60fps scrolling on iPhone 13 and newer
- **Load time**: Watchlist loads in < 500ms (cached data)
- **API efficiency**: < 100 API calls per user per day

### Secondary KPIs
- **User retention**: 40%+ Day 7 retention
- **Crash-free rate**: > 99.5%
- **App Store rating**: Target 4.5+ stars

### How to Measure
- Use **Xcode Instruments** for performance profiling
- **TestFlight** beta with analytics enabled
- **App Store Connect** analytics post-launch

---

## Launch Checklist

### Before TestFlight Beta
- [ ] All Phase 1 features implemented and tested
- [ ] Performance profiling complete (60fps validated)
- [ ] Crash testing on physical devices (iPhone 13, 14, 15, 16)
- [ ] API rate limiting verified
- [ ] Swift Data migrations handled
- [ ] Privacy policy created (for App Store)
- [ ] App icons and screenshots prepared

### Before App Store Submission
- [ ] TestFlight beta feedback addressed
- [ ] Final performance audit
- [ ] Accessibility audit (VoiceOver support)
- [ ] App Store metadata prepared (description, keywords)
- [ ] Promo video created (optional)
- [ ] Support email setup

---

## Contact & Resources

### CoinGecko API
- Docs: https://docs.coingecko.com/reference/introduction
- Status: https://status.coingecko.com/

### Apple Resources
- Swift Data: https://developer.apple.com/documentation/swiftdata
- @Observable: https://developer.apple.com/documentation/observation
- iOS 26 HIG: https://developer.apple.com/design/human-interface-guidelines/

### Support
- Project repo: (TBD)
- Issue tracking: (TBD)

---

## Appendix: Design Mockup References

### Watchlist Screen Layout
```
┌─────────────────────────┐
│  ⚡ Watchlist      [+]  │  ← Navigation bar
├─────────────────────────┤
│  Sort: [Name ▼]         │  ← Sort picker
├─────────────────────────┤
│ ╭─────────────────────╮ │
│ │ Bitcoin (BTC)       │ │  ← Coin row (glass card)
│ │ $45,000.50   +2.5% ↗│ │
│ ╰─────────────────────╯ │
│ ╭─────────────────────╮ │
│ │ Ethereum (ETH)      │ │
│ │ $3,200.75    -1.2% ↘│ │
│ ╰─────────────────────╯ │
│ ╭─────────────────────╮ │
│ │ Cardano (ADA)       │ │
│ │ $0.52        +5.8% ↗│ │
│ ╰─────────────────────╯ │
└─────────────────────────┘
```

### Portfolio Screen Layout
```
┌─────────────────────────┐
│  💼 Portfolio           │  ← Navigation bar
├─────────────────────────┤
│ ╭─────────────────────╮ │
│ │ Total Value         │ │  ← Summary card
│ │ $127,456.89         │ │
│ │ +$23,456 (+22.5%) ↗ │ │
│ ╰─────────────────────╯ │
├─────────────────────────┤
│ ╭─────────────────────╮ │
│ │ Bitcoin (BTC)       │ │  ← Holding row
│ │ 1.5 BTC             │ │
│ │ Avg: $40,000        │ │
│ │ Value: $67,500      │ │
│ │ P&L: +$7,500 (+12%) │ │
│ ╰─────────────────────╯ │
│        [+Add]           │  ← Floating action button
└─────────────────────────┘
```

---

**Last Updated**: January 2025
**Version**: 1.0 (Phase 1 MVP Specification)

## Active Technologies
- Swift 6.0+ (iOS 26+) + SwiftUI, SwiftData, UniformTypeIdentifiers (for file types) (006-portfolio-import-export)
- Swift Data (existing Transaction model) (006-portfolio-import-export)

## Recent Changes
- 006-portfolio-import-export: Added Swift 6.0+ (iOS 26+) + SwiftUI, SwiftData, UniformTypeIdentifiers (for file types)
