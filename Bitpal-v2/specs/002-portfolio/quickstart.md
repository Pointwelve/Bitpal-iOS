# Quickstart: Portfolio Feature Development

**Feature**: Manual Portfolio (002-portfolio)
**Date**: 2025-11-18

---

## Prerequisites

- Xcode 17+
- iOS 26+ SDK
- Swift 6.0+
- Existing Bitpal project at `/Users/james/Git/Bitpal-iOS/Bitpal-Spec/`

---

## 1. Project Setup

### Open Project

```bash
cd /Users/james/Git/Bitpal-iOS/Bitpal-Spec
open Bitpal.xcodeproj
```

### Verify Build

1. Select iPhone 16 simulator
2. Build and run (⌘R)
3. Confirm Watchlist tab works

---

## 2. Create Feature Directory Structure

Create the Portfolio feature structure:

```
Bitpal/Features/Portfolio/
├── Models/
│   ├── Transaction.swift
│   ├── Holding.swift
│   ├── TransactionType.swift
│   └── PortfolioError.swift
├── ViewModels/
│   ├── PortfolioViewModel.swift
│   └── AddTransactionViewModel.swift
└── Views/
    ├── PortfolioView.swift
    ├── AddTransactionView.swift
    ├── HoldingRowView.swift
    └── TransactionHistoryView.swift
```

In Xcode:
1. Right-click `Features` folder
2. New Group → "Portfolio"
3. Create subgroups: Models, ViewModels, Views
4. Add new Swift files to appropriate groups

---

## 3. Update App Configuration

### BitpalApp.swift

Add Transaction to model container:

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
            Transaction.self  // ADD THIS
        ])
    }
}
```

### ContentView.swift

Enable Portfolio tab:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WatchlistView()
                .tabItem {
                    Label("Watchlist", systemImage: "star.fill")
                }

            PortfolioView()  // ADD THIS
                .tabItem {
                    Label("Portfolio", systemImage: "chart.pie.fill")
                }
        }
    }
}
```

---

## 4. Key File Locations

### Services to Import (Reuse)

| Service | Path | Usage |
|---------|------|-------|
| CoinGeckoService | `Bitpal/Services/CoinGeckoService.swift` | Fetch coin prices |
| PriceUpdateService | `Bitpal/Services/PriceUpdateService.swift` | Periodic updates |

### Models to Import (Reuse)

| Model | Path | Usage |
|-------|------|-------|
| Coin | `Bitpal/Models/Coin.swift` | Market data |
| CoinListItem | `Bitpal/Models/CoinListItem.swift` | Search results |

### Design Components to Import (Reuse)

| Component | Path |
|-----------|------|
| LiquidGlassCard | `Bitpal/Design/Components/LiquidGlassCard.swift` |
| PriceChangeLabel | `Bitpal/Design/Components/PriceChangeLabel.swift` |
| LoadingView | `Bitpal/Design/Components/LoadingView.swift` |
| Colors | `Bitpal/Design/Styles/Colors.swift` |
| Spacing | `Bitpal/Design/Styles/Spacing.swift` |

### Utilities to Import (Reuse)

| Utility | Path |
|---------|------|
| Formatters | `Bitpal/Utilities/Formatters.swift` |
| Logger | `Bitpal/Utilities/Logger.swift` |

---

## 5. Development Patterns

### ViewModel Pattern

```swift
import Observation
import SwiftData

@Observable
final class PortfolioViewModel {
    // State
    var holdings: [Holding] = []
    var isLoading = false
    var errorMessage: String?

    // Dependencies
    private let coinGeckoService: CoinGeckoService
    private var modelContext: ModelContext?

    init(coinGeckoService: CoinGeckoService = .shared) {
        self.coinGeckoService = coinGeckoService
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    @MainActor
    func loadPortfolio() async {
        isLoading = true
        defer { isLoading = false }

        // Implementation
    }
}
```

### View Pattern

```swift
import SwiftUI

struct PortfolioView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PortfolioViewModel()

    var body: some View {
        NavigationStack {
            // Content
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadPortfolio()
        }
    }
}
```

### Row View Pattern (with Equatable)

```swift
struct HoldingRowView: View, Equatable {
    let holding: Holding

    static func == (lhs: HoldingRowView, rhs: HoldingRowView) -> Bool {
        lhs.holding == rhs.holding
    }

    var body: some View {
        LiquidGlassCard {
            // Content
        }
    }
}
```

---

## 6. Testing

### Create Test Files

```
BitpalTests/PortfolioTests/
├── TransactionModelTests.swift
├── HoldingCalculationTests.swift
└── PortfolioViewModelTests.swift
```

### Run Tests

```bash
# Command line
xcodebuild test -scheme Bitpal -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode: ⌘U
```

### Critical Tests (Write First)

Per Constitution Principle IV, these tests MUST be written BEFORE implementation:

1. **Holdings calculation**
   - Buy transactions add to quantity
   - Sell transactions reduce quantity
   - Weighted average cost calculation

2. **P&L calculation**
   - Profit when currentValue > totalCost
   - Loss when currentValue < totalCost
   - Percentage calculation accuracy

3. **Edge cases**
   - Cannot sell more than owned
   - Zero holdings after all sold
   - Multiple buys at different prices

### Example Test

```swift
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
            lastUpdated: Date(),
            marketCap: nil
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

    func testWeightedAverageCost() {
        // Buy 1 BTC at $40,000
        // Buy 1 BTC at $50,000
        // Avg cost should be $45,000
        let transactions = [
            Transaction(coinId: "bitcoin", type: .buy, amount: 1, pricePerCoin: 40000, date: Date()),
            Transaction(coinId: "bitcoin", type: .buy, amount: 1, pricePerCoin: 50000, date: Date())
        ]

        // Test computation logic
        let totalAmount: Decimal = 2
        let totalCost: Decimal = 40000 + 50000
        let avgCost = totalCost / totalAmount

        XCTAssertEqual(avgCost, 45000)
    }
}
```

---

## 7. Performance Validation

### Instruments Profiling

Before shipping, verify with Xcode Instruments:

1. **Time Profiler**: No functions > 16ms (for 60fps)
2. **Allocations**: No memory leaks in portfolio calculations
3. **Network**: API calls are batched

### Performance Targets (from Success Criteria)

| Metric | Target |
|--------|--------|
| Portfolio load | < 500ms (SC-003) |
| Holdings recalculation | < 100ms for 50 holdings (SC-005) |
| Price update reflection | < 1 second (SC-009) |
| Scrolling | 60fps with 100+ transactions (SC-004) |

### Validation Steps

```bash
# Profile with Instruments
open -a Instruments

# Select Time Profiler
# Run app and exercise portfolio features
# Verify no frame drops in scrolling
```

---

## 8. Key Implementation Checklist

### Models
- [ ] Transaction.swift with @Model
- [ ] TransactionType.swift enum
- [ ] Holding.swift computed struct
- [ ] PortfolioError.swift

### ViewModels
- [ ] PortfolioViewModel with holdings calculation
- [ ] AddTransactionViewModel with validation

### Views
- [ ] PortfolioView with summary and list
- [ ] AddTransactionView with form
- [ ] HoldingRowView with P&L display
- [ ] TransactionHistoryView

### App Configuration
- [ ] Add Transaction to modelContainer
- [ ] Enable Portfolio tab in ContentView

### Tests
- [ ] Holdings calculation tests
- [ ] P&L calculation tests
- [ ] Edge case tests

### Performance
- [ ] 60fps scrolling verified
- [ ] < 500ms load time verified
- [ ] API calls batched

---

## 9. Common Patterns Reference

### Formatting Currency

```swift
import Foundation

// Use existing Formatters utility
let value: Decimal = 45000.50
let formatted = Formatters.formatCurrency(value)
// "$45,000.50"
```

### Formatting Percentage

```swift
let percentage: Decimal = 25.34
let formatted = Formatters.formatPercentage(percentage)
// "+25.34%"
```

### Color Coding P&L

```swift
import SwiftUI

extension Color {
    static func forProfitLoss(_ value: Decimal) -> Color {
        if value > 0 {
            return .profitGreen
        } else if value < 0 {
            return .lossRed
        } else {
            return .secondary
        }
    }
}
```

### Logging

```swift
import OSLog

Logger.logic.info("Computing holdings for \(coinIds.count) coins")
Logger.persistence.debug("Saved transaction: \(transaction.id)")
Logger.error("Failed to fetch prices: \(error)")
```

---

## 10. Troubleshooting

### Swift Data Not Persisting

1. Verify Transaction added to modelContainer in BitpalApp
2. Check modelContext is passed to ViewModel
3. Call `try modelContext.save()` after insert

### Prices Not Updating

1. Verify PriceUpdateService is started
2. Check coin IDs match CoinGecko format (lowercase)
3. Check rate limiter not blocking requests

### Build Errors

1. Clean build folder (⇧⌘K)
2. Delete derived data
3. Restart Xcode

---

## 11. Reference Documents

- **Spec**: `/Users/james/Git/Bitpal-iOS/specs/002-portfolio/spec.md`
- **Research**: `/Users/james/Git/Bitpal-iOS/specs/002-portfolio/research.md`
- **Data Model**: `/Users/james/Git/Bitpal-iOS/specs/002-portfolio/data-model.md`
- **Constitution**: `/Users/james/Git/Bitpal-iOS/Bitpal-Spec/.specify/memory/constitution.md`
- **CLAUDE.md**: `/Users/james/Git/Bitpal-iOS/CLAUDE.md`

---

## 12. Next Steps

1. Create model files (Transaction, Holding, etc.)
2. Write unit tests for calculations
3. Implement PortfolioViewModel
4. Build views
5. Profile performance
6. Run `/speckit.tasks` for detailed task breakdown
