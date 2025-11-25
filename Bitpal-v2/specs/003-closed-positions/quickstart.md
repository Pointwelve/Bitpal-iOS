# Quickstart: Closed Positions & Realized P&L

**Feature**: 003-closed-positions | **For**: Developers implementing this feature

## Overview

This feature adds closed position tracking and realized P&L to the Portfolio. You'll extend the existing Portfolio feature (002-portfolio) with new computed models and UI components.

**What You're Building**:
- Closed positions displayed below active holdings
- Realized P&L shown in portfolio summary
- Collapsible section when > 5 closed positions
- Transaction history access for closed positions

**Time Estimate**: 2-3 days for experienced iOS developer

---

## Prerequisites

### Knowledge Required

- Swift 6.0 (async/await, @Observable, Decimal arithmetic)
- SwiftUI (LazyVStack, @State, animations)
- Swift Data (@Model, @Query)
- MVVM pattern
- Xcode 17+ and Instruments profiling

### Existing Code to Review

Before starting, familiarize yourself with:

1. **`Bitpal/Features/Portfolio/Models/Transaction.swift`**
   - Swift Data @Model for buy/sell transactions
   - Properties: coinId, type, amount, pricePerCoin, date

2. **`Bitpal/Features/Portfolio/Models/Holding.swift`**
   - Computed model pattern (NOT persisted)
   - Weighted average calculation in `computeHoldings()`
   - This is the template for ClosedPosition

3. **`Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift`**
   - @Observable ViewModel managing portfolio state
   - You'll extend this with closed positions

4. **`Bitpal/Features/Portfolio/Views/PortfolioView.swift`**
   - Main portfolio screen
   - You'll add Closed Positions section here

5. **Constitution (`Bitpal-Spec/.specify/memory/constitution.md`)**
   - Performance requirements (60fps, caching, Decimal types)
   - Design system (Liquid Glass, spacing, colors)
   - Architecture patterns (MVVM, @Observable, no external deps)

---

## Development Workflow

### Phase 1: Core Models & Calculation Logic (Day 1 Morning)

**Goal**: Implement ClosedPosition model and cycle detection

1. **Create `ClosedPosition.swift`**:
   ```swift
   // Bitpal/Features/Portfolio/Models/ClosedPosition.swift
   import Foundation

   struct ClosedPosition: Identifiable, Equatable {
       let id: UUID
       let coinId: String
       let coin: Coin
       let totalQuantity: Decimal
       let avgCostPrice: Decimal
       let avgSalePrice: Decimal
       let closedDate: Date
       let cycleTransactions: [Transaction]

       var realizedPnL: Decimal {
           (avgSalePrice - avgCostPrice) * totalQuantity
       }

       var realizedPnLPercentage: Decimal {
           guard avgCostPrice > 0 else { return 0 }
           return ((avgSalePrice / avgCostPrice) - 1) * 100
       }
   }
   ```

2. **Implement `computeClosedPositions()`**:
   - Follow algorithm in `data-model.md`
   - Group transactions by coinId
   - Track running balance chronologically
   - Detect cycle closures (balance < 0.00000001)
   - Compute weighted averages per cycle

3. **Write Unit Tests** (Test-First!):
   ```swift
   // BitpalTests/Features/Portfolio/ClosedPositionTests.swift
   func testSingleCycleDetection() {
       // Buy 1 BTC @ $40k, Sell 1 BTC @ $50k
       // Expected: 1 closed position, $10k profit
   }

   func testMultipleCyclesForSameCoin() {
       // Buy/Sell cycle 1, then Buy/Sell cycle 2
       // Expected: 2 separate closed positions
   }

   func testFractionalAmountsWithinTolerance() {
       // Buy 1.0, Sell 0.999999999
       // Expected: Position closes (within tolerance)
   }
   ```

**Verification**: `⌘ + U` - All unit tests pass

---

### Phase 2: ViewModel Integration (Day 1 Afternoon)

**Goal**: Extend PortfolioViewModel with closed positions

1. **Modify `PortfolioViewModel.swift`**:
   ```swift
   @Observable
   final class PortfolioViewModel {
       // Existing properties...
       var holdings: [Holding] = []

       // NEW: Closed positions
       var closedPositions: [ClosedPosition] = []

       // NEW: Portfolio summary with realized P&L
       var portfolioSummary: PortfolioSummary {
           computePortfolioSummary(
               holdings: holdings,
               closedPositions: closedPositions
           )
       }

       func refreshPortfolio() async {
           // Existing holdings refresh...
           await refreshHoldings()

           // NEW: Compute closed positions
           await refreshClosedPositions()
       }

       private func refreshClosedPositions() async {
           closedPositions = computeClosedPositions(
               transactions: transactions,
               currentPrices: coinPrices
           )
       }
   }
   ```

2. **Create `PortfolioSummary.swift`**:
   ```swift
   struct PortfolioSummary: Equatable {
       let totalValue: Decimal          // Open holdings value
       let unrealizedPnL: Decimal       // Open P&L
       let realizedPnL: Decimal         // Closed P&L
       let totalOpenCost: Decimal
       let totalClosedCost: Decimal

       var totalPnL: Decimal {
           unrealizedPnL + realizedPnL
       }

       var totalPnLPercentage: Decimal {
           let totalCostBasis = totalOpenCost + totalClosedCost
           guard totalCostBasis > 0 else { return 0 }
           return (totalPnL / totalCostBasis) * 100
       }
   }
   ```

**Verification**: Build succeeds, ViewModel compiles without errors

---

### Phase 3: UI - Closed Positions Section (Day 2 Morning)

**Goal**: Display closed positions in Portfolio

1. **Create `ClosedPositionRowView.swift`**:
   ```swift
   struct ClosedPositionRowView: View {
       let closedPosition: ClosedPosition

       var body: some View {
           LiquidGlassCard {
               VStack(alignment: .leading, spacing: Spacing.small) {
                   // Header: Coin name, symbol, close date
                   HStack {
                       VStack(alignment: .leading) {
                           Text(closedPosition.coin.name)
                               .font(Typography.headline)
                           Text(closedPosition.coin.symbol.uppercased())
                               .font(Typography.caption)
                               .foregroundColor(.textSecondary)
                       }
                       Spacer()
                       Text(closedPosition.closedDate.formatted(date: .abbreviated, time: .omitted))
                           .font(Typography.caption)
                           .foregroundColor(.textSecondary)
                   }

                   Divider()

                   // Metrics: Quantity, Avg Cost, Avg Sale, Realized P&L
                   // ... (implement using HStack with 4 columns)
               }
           }
       }
   }
   ```

2. **Create `ClosedPositionsSection.swift`**:
   ```swift
   struct ClosedPositionsSection: View {
       let closedPositions: [ClosedPosition]
       @State private var isExpanded = false

       var shouldCollapse: Bool {
           closedPositions.count > 5
       }

       var body: some View {
           VStack(alignment: .leading, spacing: Spacing.medium) {
               // Section header (tappable if should collapse)
               sectionHeader

               // Positions list (show if expanded or <= 5 items)
               if !shouldCollapse || isExpanded {
                   positionsList
               }
           }
       }

       private var sectionHeader: some View {
           Button {
               if shouldCollapse {
                   withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                       isExpanded.toggle()
                   }
               }
           } label: {
               HStack {
                   Text("Closed Positions")
                       .font(Typography.title2)
                   if shouldCollapse {
                       Text("(\(closedPositions.count))")
                           .font(Typography.title3)
                           .foregroundColor(.textSecondary)
                   }
                   Spacer()
                   if shouldCollapse {
                       Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                           .foregroundColor(.textSecondary)
                   }
               }
           }
           .buttonStyle(.plain)
       }

       private var positionsList: some View {
           LazyVStack(spacing: Spacing.small) {
               ForEach(closedPositions) { position in
                   ClosedPositionRowView(closedPosition: position)
                       .onTapGesture {
                           // TODO: Navigate to transaction history
                       }
               }
           }
       }
   }
   ```

3. **Integrate into `PortfolioView.swift`**:
   ```swift
   ScrollView {
       VStack(spacing: Spacing.large) {
           // Existing portfolio summary and holdings...

           // NEW: Closed Positions Section
           if !viewModel.closedPositions.isEmpty {
               ClosedPositionsSection(
                   closedPositions: viewModel.closedPositions
               )
               .padding(.horizontal, Spacing.medium)
           }
       }
   }
   ```

**Verification**: Run app, create test transactions that close positions, verify UI displays

---

### Phase 4: Portfolio Summary Enhancement (Day 2 Afternoon)

**Goal**: Show unrealized + realized + total P&L

1. **Modify `PortfolioSummaryView.swift`**:
   ```swift
   struct PortfolioSummaryView: View {
       let summary: PortfolioSummary

       var body: some View {
           LiquidGlassCard {
               VStack(spacing: Spacing.small) {
                   // Total Value (existing)
                   summaryRow(
                       label: "Total Value",
                       value: Formatters.formatCurrency(summary.totalValue),
                       color: .textPrimary,
                       isLarge: true
                   )

                   Divider()

                   // NEW: Unrealized P&L (open positions)
                   summaryRow(
                       label: "Unrealized P&L",
                       value: Formatters.formatCurrency(summary.unrealizedPnL),
                       color: summary.unrealizedPnL >= 0 ? .profitGreen : .lossRed
                   )

                   // NEW: Realized P&L (closed positions) - tappable
                   Button {
                       // Scroll to Closed Positions section
                   } label: {
                       summaryRow(
                           label: "Realized P&L",
                           value: Formatters.formatCurrency(summary.realizedPnL),
                           color: summary.realizedPnL >= 0 ? .profitGreen : .lossRed
                       )
                   }

                   Divider()

                   // NEW: Total P&L (sum)
                   summaryRow(
                       label: "Total P&L",
                       value: Formatters.formatCurrency(summary.totalPnL),
                       color: summary.totalPnL >= 0 ? .profitGreen : .lossRed,
                       isLarge: true
                   )
               }
           }
       }

       private func summaryRow(
           label: String,
           value: String,
           color: Color,
           isLarge: Bool = false
       ) -> some View {
           HStack {
               Text(label)
                   .font(isLarge ? Typography.title3 : Typography.body)
               Spacer()
               Text(value)
                   .font(isLarge ? Typography.title2 : Typography.headline)
                   .foregroundColor(color)
                   .fontWeight(isLarge ? .bold : .medium)
           }
       }
   }
   ```

**Verification**: Portfolio summary shows 4 rows with correct values and colors

---

### Phase 5: Testing & Performance (Day 3)

**Goal**: Verify edge cases and performance targets

1. **Create Test Data**:
   ```swift
   // Test scenario 1: Multiple cycles
   // Buy 1 BTC @ $40k, Sell 1 BTC @ $50k (Cycle 1)
   // Buy 2 BTC @ $30k, Sell 2 BTC @ $35k (Cycle 2)
   // Expected: 2 closed positions

   // Test scenario 2: 50+ closed positions
   // Create 60 closed cycles
   // Expected: Section collapses, scrolling smooth at 60fps

   // Test scenario 3: Transaction deletion
   // Close position, then delete sell transaction
   // Expected: Position moves back to open holdings
   ```

2. **Profile with Instruments**:
   - Open Xcode → Product → Profile → Time Profiler
   - Create 100 transactions (50 closed cycles)
   - Measure `computeClosedPositions()` execution time
   - **Target**: < 100ms (Assumption #7)
   - Measure UI update time after closing position
   - **Target**: < 500ms (SC-006)

3. **Manual Testing Checklist**:
   - [ ] Single cycle displays correctly
   - [ ] Multiple cycles for same coin (separate entries)
   - [ ] Collapsed section (> 5 positions)
   - [ ] Expand/collapse animation smooth
   - [ ] Realized P&L colors (green profit, red loss)
   - [ ] Portfolio summary shows 4 metrics
   - [ ] Tap Realized P&L scrolls to section
   - [ ] Transaction deletion reopens position
   - [ ] 60fps scrolling with 50+ positions

**Verification**: All tests pass, performance targets met

---

## Common Issues & Solutions

### Issue 1: Cycle Detection Misses Positions

**Symptom**: Position stays in open holdings despite full sale

**Cause**: Running balance not resetting after cycle closes

**Solution**: Ensure `cycleStart` index and `runningBalance` reset after each cycle:
```swift
if abs(runningBalance) < 0.00000001 {
    // ... create closed position
    cycleStart = index + 1  // ✅ Reset start index
    runningBalance = 0      // ✅ Reset balance
}
```

### Issue 2: Weighted Average Incorrect

**Symptom**: Realized P&L doesn't match manual calculation

**Cause**: Not using weighted average formula

**Solution**: Use existing `computeHoldings()` pattern:
```swift
let totalBuyCost = transactions
    .filter { $0.type == .buy }
    .reduce(0) { $0 + ($1.amount * $1.pricePerCoin) }

let totalBuyAmount = transactions
    .filter { $0.type == .buy }
    .reduce(0) { $0 + $1.amount }

let avgCostPrice = totalBuyCost / totalBuyAmount  // Weighted average
```

### Issue 3: UI Not Updating on Transaction Change

**Symptom**: Closed position still shows after deleting transaction

**Cause**: Forgot to refresh closed positions in ViewModel

**Solution**: Call `refreshClosedPositions()` when transactions change:
```swift
func deleteTransaction(_ transaction: Transaction) {
    modelContext.delete(transaction)
    try? modelContext.save()
    Task {
        await refreshClosedPositions()  // ✅ Recompute
    }
}
```

### Issue 4: Scrolling Laggy with Many Positions

**Symptom**: Scrolling < 60fps with 50+ closed positions

**Cause**: Not using LazyVStack or expensive view computations

**Solution**:
1. Use `LazyVStack` (not `VStack`)
2. Cache `realizedPnL` computation in ClosedPosition (already computed property)
3. Avoid `.onAppear` heavy work in row views

---

## Performance Checklist

Before marking feature complete, verify:

- [ ] **Computation**: `computeClosedPositions()` < 100ms for 100 transactions
- [ ] **UI Update**: Position appears in Closed Positions < 500ms after sell
- [ ] **Scrolling**: 60fps with 50+ closed positions (profile with Instruments)
- [ ] **Memory**: No retain cycles (ClosedPosition is struct, ViewModel is @Observable)
- [ ] **Caching**: Closed positions cached in ViewModel, invalidated on transaction changes

---

## Code Review Checklist

Before submitting PR:

- [ ] All unit tests pass (`⌘ + U`)
- [ ] Constitution principles verified (see `plan.md`)
- [ ] Decimal type used for all financial values (no Double/Float)
- [ ] @Observable used for ViewModel (not ObservableObject)
- [ ] Views are stateless (business logic in ViewModel)
- [ ] LazyVStack used for closed positions list
- [ ] Liquid Glass design applied (LiquidGlassCard, spacing, colors)
- [ ] Spring animations (response: 0.3, dampingFraction: 0.7)
- [ ] Minimum 44x44pt tap targets
- [ ] No force unwrapping (`!`) except in tests
- [ ] No external dependencies added

---

## Next Steps

After implementation:

1. Run `/speckit.tasks` to generate detailed task checklist
2. Follow test-first workflow (write tests before implementation)
3. Profile with Instruments before marking complete
4. Submit PR with performance metrics in description

**Questions?** Refer to:
- `data-model.md` - Entity definitions and algorithms
- `plan.md` - Architecture and constitution compliance
- `spec.md` - Functional requirements and acceptance criteria
- Constitution - Performance and design principles
