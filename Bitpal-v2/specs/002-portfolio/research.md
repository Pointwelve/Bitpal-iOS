# Research: Portfolio Feature Implementation

**Feature**: Manual Portfolio (002-portfolio)
**Date**: 2025-11-18
**Status**: Complete

## Executive Summary

Research of the existing Bitpal iOS codebase reveals a well-structured SwiftUI application following constitution guidelines. The Watchlist feature provides clear patterns that the Portfolio feature will reuse directly.

---

## 1. Codebase Structure

### Project Location
```
/Users/james/Git/Bitpal-iOS/Bitpal-Spec/Bitpal.xcodeproj
```

### Current Architecture
```
Bitpal-Spec/Bitpal/
├── App/
│   ├── BitpalApp.swift              # Swift Data container
│   └── ContentView.swift            # TabView navigation
├── Features/
│   └── Watchlist/                   # Existing feature
│       ├── Models/
│       ├── Views/
│       └── ViewModels/
├── Services/                        # Shared services
├── Models/                          # Shared models
├── Design/                          # Design system
└── Utilities/                       # Shared utilities
```

---

## 2. Services to Reuse (No Modification)

### CoinGeckoService
**Path**: `Bitpal/Services/CoinGeckoService.swift`

**Decision**: Reuse as-is
**Rationale**: Already implements batched requests, rate limiting, and two-tier caching per constitution
**Alternatives**: None - well-suited for Portfolio needs

Key features:
- Singleton pattern (`CoinGeckoService.shared`)
- In-memory cache with 30-second TTL
- Rate limiter integration
- Batched coin ID requests
- Returns `[String: Coin]` dictionary

### PriceUpdateService
**Path**: `Bitpal/Services/PriceUpdateService.swift`

**Decision**: Reuse as-is
**Rationale**: Handles periodic 30-second updates per constitution Principle I
**Alternatives**: None - exact behavior needed for Portfolio

### RateLimiter
**Path**: `Bitpal/Services/RateLimiter.swift`

**Decision**: Reuse as-is
**Rationale**: Actor-based rate limiting (1.2s between API calls) prevents CoinGecko rate limit errors
**Alternatives**: None

---

## 3. Models to Reuse

### Coin
**Path**: `Bitpal/Models/Coin.swift`

**Decision**: Reuse as-is
**Rationale**: Contains all market data needed for holdings display (price, 24h change, symbol, name)
**Alternatives**: None - shared model ensures data consistency between Watchlist and Portfolio

Key properties:
- `id: String` (CoinGecko ID)
- `symbol: String`
- `name: String`
- `currentPrice: Decimal`
- `priceChange24h: Decimal`
- `lastUpdated: Date`

### CoinListItem
**Path**: `Bitpal/Models/CoinListItem.swift`

**Decision**: Reuse for coin selection
**Rationale**: Lightweight model for search/selection UI
**Alternatives**: None

---

## 4. Design Components to Reuse

### LiquidGlassCard
**Path**: `Bitpal/Design/Components/LiquidGlassCard.swift`

**Decision**: Reuse for holding rows and summary card
**Rationale**: Implements iOS 26 Liquid Glass design per constitution Principle II
**Alternatives**: None

### PriceChangeLabel
**Path**: `Bitpal/Design/Components/PriceChangeLabel.swift`

**Decision**: Reuse for P&L percentage display
**Rationale**: Color-coded percentage already implemented
**Alternatives**: May need slight adaptation for P&L vs price change context

### Colors
**Path**: `Bitpal/Design/Styles/Colors.swift`

**Decision**: Reuse
**Rationale**: Contains `.profitGreen` and `.lossRed` semantic colors
**Alternatives**: None

### Spacing
**Path**: `Bitpal/Design/Styles/Spacing.swift`

**Decision**: Reuse
**Rationale**: Consistent spacing scale (tiny: 4, small: 8, standard: 12, medium: 16, large: 24, extraLarge: 32)
**Alternatives**: None

### Typography
**Path**: `Bitpal/Design/Styles/Typography.swift`

**Decision**: Reuse
**Rationale**: SF Pro fonts with numeric variants for price display
**Alternatives**: None

---

## 5. Utilities to Reuse

### Formatters
**Path**: `Bitpal/Utilities/Formatters.swift`

**Decision**: Reuse all formatters
**Rationale**: Currency and percentage formatting already correct
**Alternatives**: None

Key functions:
- `formatCurrency(_ value: Decimal) -> String`
- `formatPercentage(_ value: Decimal) -> String`
- `formatCompactCurrency(_ value: Decimal) -> String`

### Logger
**Path**: `Bitpal/Utilities/Logger.swift`

**Decision**: Reuse
**Rationale**: OSLog categories already defined
**Alternatives**: None

Categories: `.api`, `.persistence`, `.ui`, `.logic`, `.error`

---

## 6. Patterns to Follow

### ViewModel Pattern
**Reference**: `Bitpal/Features/Watchlist/ViewModels/WatchlistViewModel.swift`

Key patterns:
- `@Observable` macro (NOT ObservableObject)
- Dependency injection via init with default `.shared` singletons
- `ModelContext` passed via `configure()` method
- All UI-updating methods marked `@MainActor`
- Clear MARK sections for organization

```swift
@Observable
final class PortfolioViewModel {
    var holdings: [Holding] = []
    var isLoading = false
    var errorMessage: String?

    private let coinGeckoService: CoinGeckoService
    private var modelContext: ModelContext?

    init(coinGeckoService: CoinGeckoService = .shared) {
        self.coinGeckoService = coinGeckoService
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
```

### Swift Data Model Pattern
**Reference**: `Bitpal/Features/Watchlist/Models/WatchlistItem.swift`

Key patterns:
- `@Model` macro
- `@Attribute(.unique)` for uniqueness
- Simple memberwise initializer

### View Pattern
**Reference**: `Bitpal/Features/Watchlist/Views/WatchlistView.swift`

Key patterns:
- `@State private var viewModel = ViewModel()`
- Configure in `.task` modifier
- Pass `modelContext` from environment
- Clean up in `.onDisappear`

### Row View Pattern
**Reference**: `Bitpal/Features/Watchlist/Views/CoinRowView.swift`

Key patterns:
- Conforms to `Equatable` for performance
- Uses `LiquidGlassCard` wrapper
- Immutable `let` properties

---

## 7. New Components to Create

### Swift Data Models

| Model | Purpose | Persistence |
|-------|---------|-------------|
| Transaction | User buy/sell records | Swift Data @Model |
| TransactionType | buy/sell enum | Codable enum |

### Computed Models

| Model | Purpose | Persistence |
|-------|---------|-------------|
| Holding | Computed position with P&L | NOT persisted |

### ViewModels

| ViewModel | Purpose |
|-----------|---------|
| PortfolioViewModel | Main portfolio state, holdings calculation |
| AddTransactionViewModel | Transaction form validation and submission |

### Views

| View | Purpose |
|------|---------|
| PortfolioView | Main portfolio list with summary |
| AddTransactionView | Transaction entry form (sheet) |
| HoldingRowView | Individual holding display |
| TransactionHistoryView | Transaction list per coin (navigation destination) |

### Error Types

| Type | Purpose |
|------|---------|
| PortfolioError | Domain-specific errors |

---

## 8. App Configuration Updates

### BitpalApp.swift
Add Transaction to model container:
```swift
.modelContainer(for: [
    WatchlistItem.self,
    Transaction.self  // ADD
])
```

### ContentView.swift
Enable Portfolio tab (currently commented out)

---

## 9. Testing Strategy

### Unit Tests Required (per Constitution Principle IV)

1. **Transaction calculations**
   - Holdings computation from buy/sell transactions
   - Weighted average cost calculation
   - Profit/loss calculation
   - Profit/loss percentage calculation

2. **Edge cases**
   - Selling more than owned (validation)
   - Zero holdings after all sold
   - Mixed buys/sells with fractional amounts

### Test File Structure
```
BitpalTests/PortfolioTests/
├── TransactionModelTests.swift
├── HoldingCalculationTests.swift
└── PortfolioViewModelTests.swift
```

---

## 10. Key Implementation Notes

### Holdings Calculation
- Compute on-the-fly from transactions
- Cache only if performance issues arise (measure first)
- Use Decimal for all financial values

### Coin Selection
- Reuse CoinSearchView pattern
- For Sell: filter to show owned coins first (FR-029)
- Allow cached coins when offline (FR-028)

### Price Updates
- Reuse PriceUpdateService
- Portfolio subscribes to same update cycle as Watchlist
- Show "last updated" badge when stale

### Transaction History
- NavigationLink push (standard iOS pattern)
- Newest first sort order
- Color coding for buy (green) vs sell (red)

---

## 11. Resolved Unknowns

| Unknown | Resolution | Rationale |
|---------|------------|-----------|
| Coin selection UI | Reuse CoinSearchView | Existing pattern works well |
| Price fetching | Reuse PriceUpdateService | Same update cycle needed |
| Currency formatting | Reuse Formatters | Already correct precision |
| P&L display precision | 2 decimal places | Clarified in spec session |
| Empty state | "Add Your First Transaction" button | Clarified in spec session |
| Network failure | Use cached coins | Clarified in spec session |
| Sell coin ordering | Owned coins first | Clarified in spec session |

---

## 12. Summary

The Portfolio feature implementation is well-supported by existing codebase infrastructure:

- **7 services/utilities** to reuse directly
- **6 design components** to reuse
- **2 models** to share
- **4 patterns** to follow

New development focuses on:
- Transaction Swift Data model
- Holding calculation logic
- Portfolio-specific views
- Unit tests for calculations

All constitution principles can be satisfied using existing patterns.
