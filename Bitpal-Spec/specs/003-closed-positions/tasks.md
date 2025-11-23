# Tasks: Closed Positions & Realized P&L

**Input**: Design documents from `/specs/003-closed-positions/`
**Prerequisites**: plan.md, spec.md, data-model.md, quickstart.md

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for critical business logic and OPTIONAL for UI/simple operations.

**Tests REQUIRED** (must write BEFORE implementation):
- Closed position calculation (cycle detection, P&L computation)
- Weighted average calculations (cost price, sale price)
- Portfolio summary aggregation

**Tests OPTIONAL** (manual testing acceptable):
- SwiftUI views (visual review)
- Collapse/expand animations
- UI flows and navigation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Architecture**: Per Constitution Principle III (MVVM + Modern Swift Patterns):
- ViewModels MUST use @Observable (NOT ObservableObject)
- Views MUST be stateless (no business logic)
- Services use singleton pattern
- Swift Data for persistence (NOT Core Data)
- async/await concurrency (NOT Combine)
- NO external dependencies

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

**iOS Mobile App Structure**:
- **Models**: `Bitpal/Features/Portfolio/Models/`
- **ViewModels**: `Bitpal/Features/Portfolio/ViewModels/`
- **Views**: `Bitpal/Features/Portfolio/Views/`
- **Tests**: `BitpalTests/Features/Portfolio/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verify existing Portfolio infrastructure is ready for extension

**Status**: ✅ Already complete from 002-portfolio feature

This feature extends the existing Portfolio feature (002-portfolio). All infrastructure is already in place:
- Transaction model (@Model in Swift Data)
- Holding computation pattern established
- PortfolioViewModel with @Observable
- LiquidGlassCard UI components
- Portfolio screen layout

**No setup tasks required** - proceed directly to foundational work.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and computation logic that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests (Write FIRST - Constitution Principle IV)

- [ ] T001 [P] Create unit test file `BitpalTests/Features/Portfolio/ClosedPositionTests.swift` with test class structure
- [ ] T002 [P] Write test `testSingleCycleDetection()` - Buy 1 BTC @ $40k, Sell 1 BTC @ $50k, expect 1 closed position with $10k profit
- [ ] T003 [P] Write test `testMultipleCyclesForSameCoin()` - Two buy/sell cycles, expect 2 separate ClosedPosition entries
- [ ] T004 [P] Write test `testFractionalAmountsWithinTolerance()` - Buy 1.0 BTC, Sell 0.999999999 BTC, expect position closes (within 0.00000001 tolerance)
- [ ] T005 [P] Write test `testFractionalAmountsOutsideTolerance()` - Buy 1.0 BTC, Sell 0.99 BTC, expect position stays open
- [ ] T006 [P] Write test `testWeightedAverageCostCalculation()` - Multiple buys at different prices, verify correct weighted average
- [ ] T007 [P] Write test `testWeightedAverageSaleCalculation()` - Multiple sells at different prices, verify correct weighted average
- [ ] T008 [P] Write test `testProfitableClosedPosition()` - Sale price > cost price, verify positive realized P&L
- [ ] T009 [P] Write test `testLossClosedPosition()` - Sale price < cost price, verify negative realized P&L
- [ ] T010 [P] Write test `testZeroCostPosition()` - Gifted coins (cost = 0), then sell, verify entire sale is profit

### Core Models

- [ ] T011 Create `Bitpal/Features/Portfolio/Models/ClosedPosition.swift` with struct definition (id, coinId, coin, totalQuantity, avgCostPrice, avgSalePrice, closedDate, cycleTransactions, realizedPnL computed property, realizedPnLPercentage computed property)
- [ ] T012 Create `Bitpal/Features/Portfolio/Models/PortfolioSummary.swift` with struct definition (totalValue, unrealizedPnL, realizedPnL, totalOpenCost, totalClosedCost, totalPnL computed property, totalPnLPercentage computed property)

### Core Computation Functions

- [ ] T013 Implement `computeClosedPositions(transactions:currentPrices:) -> [ClosedPosition]` function in `Bitpal/Features/Portfolio/Models/ClosedPosition.swift` following algorithm from data-model.md (group by coinId, sort chronologically, track running balance, detect cycle closures with 0.00000001 tolerance)
- [ ] T014 Implement `computeCycleMetrics(coinId:coin:transactions:closeDate:) -> ClosedPosition?` private helper function in `ClosedPosition.swift` (calculate weighted averages, validate cycle, return ClosedPosition)
- [ ] T015 Implement `computePortfolioSummary(holdings:closedPositions:) -> PortfolioSummary` function in `PortfolioSummary.swift` (aggregate metrics from open holdings and closed positions)

### Verify Tests Pass

- [ ] T016 Run all unit tests (`⌘ + U`) and verify all 10 tests pass - if any fail, fix computation logic before proceeding

**Checkpoint**: Foundation ready - all tests pass, core models and computation logic verified. User story implementation can now begin.

---

## Phase 3: User Story 1 - View Closed Positions List (Priority: P1) 🎯 MVP

**Goal**: Display closed trading positions in a dedicated section below active holdings in Portfolio screen, with profit/loss color coding and collapsible UI for > 5 positions.

**Independent Test**: Create buy/sell transactions that net to zero (e.g., buy 1 BTC, sell 1 BTC) and verify coin appears in "Closed Positions" section with calculated realized P&L. Section collapses when > 5 positions exist and expands/collapses on header tap.

**Acceptance Criteria** (from spec.md):
1. Closed positions appear in separate section below active holdings
2. Profit shows green with % gain, loss shows red with % loss
3. Section hidden when no closed positions exist
4. Position automatically moves from open to closed when final sell completes
5. Section collapsed (header with count) when > 5 closed positions
6. Tap header to expand/collapse section
7. Expand/collapse animation smooth (spring: 0.3, dampingFraction: 0.7)

### ViewModel Integration

- [X] T017 [US1] Add `var closedPositions: [ClosedPosition] = []` property to `Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift`
- [X] T018 [US1] Add `@MainActor private func refreshClosedPositions() async` method to PortfolioViewModel that calls `computeClosedPositions()` with current transactions and coin prices
- [X] T019 [US1] Update existing `refresh()` method in PortfolioViewModel to call `await refreshClosedPositions()` after refreshing holdings
- [X] T020 [US1] Add cache invalidation - call `refreshClosedPositions()` when transactions are added/edited/deleted in PortfolioViewModel

### UI Components

- [X] T021 [P] [US1] Create `Bitpal/Features/Portfolio/Views/ClosedPositionRowView.swift` with LiquidGlassCard displaying: coin name/symbol, close date, total quantity traded, avg cost price, avg sale price, realized P&L ($), realized P&L (%) with profit/loss color coding (green for gains, red for losses)
- [X] T022 [US1] Create `Bitpal/Features/Portfolio/Views/ClosedPositionsSection.swift` with collapsible section header, @State `isExpanded` boolean, computed `shouldCollapse` (count > 5), section header HStack with title, count badge, chevron icon, tap gesture to toggle expand/collapse with spring animation
- [X] T023 [US1] Add LazyVStack in ClosedPositionsSection displaying ClosedPositionRowView for each position (only when expanded or count <= 5)
- [X] T024 [US1] Integrate ClosedPositionsSection into `Bitpal/Features/Portfolio/Views/PortfolioView.swift` below holdings list, conditionally rendered only if `!viewModel.closedPositions.isEmpty`

### Manual Testing

- [ ] T025 [US1] Manual test: Create single buy/sell cycle (1 BTC buy, 1 BTC sell), verify position appears in Closed Positions section
- [ ] T026 [US1] Manual test: Create closed position with profit (buy @ $40k, sell @ $50k), verify P&L shows green with correct percentage
- [ ] T027 [US1] Manual test: Create closed position with loss (buy @ $50k, sell @ $40k), verify P&L shows red with correct percentage
- [ ] T028 [US1] Manual test: Create 6 closed positions, verify section collapses (shows header with count only)
- [ ] T029 [US1] Manual test: Tap collapsed header, verify section expands with smooth animation, tap again to collapse
- [ ] T030 [US1] Manual test: Verify section hidden when portfolio has zero closed positions

**Checkpoint**: User Story 1 complete and independently testable. Users can view closed positions with profit/loss tracking.

---

## Phase 4: User Story 2 - Portfolio Summary with Realized Gains (Priority: P2)

**Goal**: Enhance portfolio summary to display unrealized P&L (open positions), realized P&L (closed positions), and total P&L in a comprehensive 4-row summary card.

**Independent Test**: Create mix of open and closed positions, verify portfolio summary shows 4 distinct rows: Total Value, Unrealized P&L, Realized P&L, Total P&L with correct values and color coding.

**Acceptance Criteria** (from spec.md):
1. Summary shows: Total Value, Unrealized P&L, Realized P&L, Total P&L
2. Only closed positions → Total Value $0, Unrealized $0, Realized shows cumulative
3. Mixed profitable/losing positions → correct color coding per metric
4. Tap Realized P&L → scrolls to Closed Positions section

### ViewModel Enhancement

- [X] T031 [US2] Add `var portfolioSummary: PortfolioSummary` computed property to `Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift` that calls `computePortfolioSummary(holdings:closedPositions:)` with current holdings and closed positions arrays

### UI Components

- [X] T032 [P] [US2] Modify `Bitpal/Features/Portfolio/Views/PortfolioSummaryView.swift` to accept `PortfolioSummary` parameter instead of individual values
- [X] T033 [US2] Add "Unrealized P&L" row in PortfolioSummaryView with value from summary.unrealizedPnL, color coded (green if >= 0, red if < 0)
- [X] T034 [US2] Add "Realized P&L" row in PortfolioSummaryView as tappable Button with value from summary.realizedPnL, color coded (green if >= 0, red if < 0)
- [X] T035 [US2] Add Divider separator between Realized P&L and Total P&L rows
- [X] T036 [US2] Add "Total P&L" row in PortfolioSummaryView with value from summary.totalPnL, color coded (green if >= 0, red if < 0), bold font weight
- [X] T037 [US2] Update `Bitpal/Features/Portfolio/Views/PortfolioView.swift` to pass `viewModel.portfolioSummary` to PortfolioSummaryView
- [X] T038 [US2] Implement scroll-to-section functionality: add @State `closedPositionsSectionID` in PortfolioView, add `.id(closedPositionsSectionID)` modifier to ClosedPositionsSection, add `.scrollTo()` action on Realized P&L tap

### Manual Testing

- [ ] T039 [US2] Manual test: Create both open holdings and closed positions, verify all 4 summary rows display with correct values
- [ ] T040 [US2] Manual test: Portfolio with only closed positions (no open), verify Total Value = $0, Unrealized P&L = $0, Realized P&L shows cumulative
- [ ] T041 [US2] Manual test: Profitable closed trades + losing open holdings, verify color coding (realized green, unrealized red, total shows net)
- [ ] T042 [US2] Manual test: Tap "Realized P&L" row, verify smooth scroll to Closed Positions section

**Checkpoint**: User Story 2 complete. Portfolio summary provides complete financial picture with realized and unrealized performance.

---

## Phase 5: User Story 3 - Closed Position Details (Priority: P3)

**Goal**: Allow users to tap closed positions to view transaction history, providing detailed breakdown of the buy/sell cycle.

**Independent Test**: Tap a closed position row and verify TransactionHistoryView opens showing all transactions for that coin's cycle with weighted averages displayed.

**Acceptance Criteria** (from spec.md):
1. Tap closed position → opens detail view with all cycle transactions
2. Transaction history shows buys and sells chronologically
3. (Optional) "Buy Again" button to re-enter position

### UI Integration

- [ ] T043 [US3] Make ClosedPositionRowView in `Bitpal/Features/Portfolio/Views/ClosedPositionRowView.swift` tappable by wrapping in Button
- [ ] T044 [US3] Add navigation to `TransactionHistoryView` on closed position tap in `ClosedPositionsSection.swift` using NavigationLink, passing closed position's coinId and coin name
- [ ] T045 [US3] Update `Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift` @Query to filter transactions by coinId (already implemented - verify it works for closed positions)

### Manual Testing

- [ ] T046 [US3] Manual test: Tap closed position row, verify TransactionHistoryView opens with correct coin name
- [ ] T047 [US3] Manual test: Verify transaction history shows all buys/sells for that cycle in chronological order
- [ ] T048 [US3] Manual test: Verify transaction details match closed position metrics (quantity, avg prices)

**Checkpoint**: User Story 3 complete. Users can drill down into closed position details via transaction history.

---

## Phase 6: Polish & Performance

**Purpose**: Final testing, performance validation, and edge case handling

### Edge Case Testing

- [ ] T049 Delete transaction that closed position, verify position moves back to active holdings in `PortfolioView.swift`
- [ ] T050 Create exactly 5 closed positions, verify section displays expanded (not collapsed)
- [ ] T051 Create exactly 6 closed positions, verify section collapses (header with count)
- [ ] T052 Test multiple close/reopen cycles for same coin (e.g., buy/sell BTC twice), verify 2 separate ClosedPosition entries appear
- [ ] T053 Test zero-cost position (manually set transaction pricePerCoin to 0 for buy, then sell), verify entire sale revenue shows as realized profit

### Performance Profiling

- [ ] T054 Create 100 test transactions (50 closed cycles) and profile `computeClosedPositions()` execution time with Xcode Instruments Time Profiler - verify < 100ms (Constitution Principle I target from plan.md Assumption #7)
- [ ] T055 Profile UI update time when closing a position (add sell transaction to close open holding) - verify < 500ms from save to UI display (SC-006 from spec.md)
- [ ] T056 Create 60 closed positions and test scrolling in ClosedPositionsSection with Instruments - verify 60fps scrolling performance (Constitution Principle I + SC-004)
- [ ] T057 Profile memory usage with 50+ closed positions - verify no memory leaks, closed positions array properly cached in ViewModel

### Visual Design Validation

- [ ] T058 Verify ClosedPositionRowView follows Liquid Glass design: LiquidGlassCard with .ultraThinMaterial, 16pt corner radius, correct spacing (Spacing.small, .medium)
- [ ] T059 Verify profit/loss color coding uses system colors (.profitGreen for gains, .lossRed for losses) for Dark Mode compatibility
- [ ] T060 Verify section header uses Typography.title2 font, count badge uses Typography.title3
- [ ] T061 Verify expand/collapse animation uses spring(response: 0.3, dampingFraction: 0.7) per Constitution Principle II
- [ ] T062 Verify all tap targets >= 44x44pt (section header, closed position rows) per Constitution Principle II
- [ ] T063 Verify Dynamic Type support - test with largest accessibility text size, ensure no text truncation

### Code Quality

- [ ] T064 Run unit tests (`⌘ + U`) and verify all tests pass (10 foundational tests + any additional tests added)
- [ ] T065 Verify all financial values use Decimal type (no Double/Float) in ClosedPosition.swift and PortfolioSummary.swift per Constitution Principle IV
- [ ] T066 Verify PortfolioViewModel uses @Observable (not ObservableObject) per Constitution Principle III
- [ ] T067 Verify all views are stateless (no business logic in ClosedPositionRowView, ClosedPositionsSection, PortfolioSummaryView)
- [ ] T068 Verify no force unwrapping (`!`) except in test code
- [ ] T069 Code review: Verify compliance with Swift API Design Guidelines (naming, clarity, conventions)

**Final Checkpoint**: Feature complete, all edge cases handled, performance targets met, constitution compliance verified.

---

## Dependencies & Parallel Execution

### User Story Dependencies

```
Phase 1: Setup (Complete from 002-portfolio) ✅
           ↓
Phase 2: Foundational (T001-T016) ← BLOCKING
           ↓
     ┌─────┴─────┬─────────┐
     ↓           ↓         ↓
Phase 3: US1  Phase 4: US2  Phase 5: US3
(T017-T030)   (T031-T042)  (T043-T048)
  INDEPENDENT    depends     depends
                 on US1      on US1
     ↓           ↓         ↓
     └─────┬─────┴─────────┘
           ↓
Phase 6: Polish (T049-T069)
```

**Independent Stories**: US1 can be implemented and shipped as MVP standalone.

**Dependent Stories**:
- US2 depends on US1 (needs PortfolioViewModel with closedPositions)
- US3 depends on US1 (needs ClosedPositionRowView and ClosedPositionsSection)

### Parallel Execution Opportunities

**Phase 2 (Foundational)**: Tests can run in parallel
- T001-T010: All test writing tasks are parallelizable ✅
- T011-T012: Model file creation can run in parallel ✅
- T013-T015: Computation functions must run sequentially (T014 depends on T013)

**Phase 3 (US1)**: Many tasks parallelizable
- T017-T020: ViewModel tasks sequential (all modify same file)
- T021: ClosedPositionRowView can run in parallel with ViewModel work ✅
- T022-T024: View tasks sequential (dependencies)

**Phase 4 (US2)**: Some parallelization possible
- T031: Blocks T037
- T032-T036: View modifications can run in parallel ✅
- T038: Depends on T037

**Phase 6 (Polish)**: Many tasks parallelizable
- T049-T053: Edge case tests can run in parallel ✅
- T054-T057: Performance profiling can run in parallel ✅
- T058-T063: Visual validation can run in parallel ✅
- T064-T069: Code quality checks can run in parallel ✅

---

## Implementation Strategy

### MVP Scope (Ship First)

**Minimum Viable Product** = User Story 1 only (Phase 3)
- Core value: View closed positions with realized P&L
- 14 tasks (T017-T030)
- Estimated effort: 1-2 days for experienced iOS developer
- Can ship independently and gather user feedback

### Incremental Delivery

1. **Week 1**: Foundational + US1 (T001-T030)
   - Ship MVP: Closed positions display with collapse/expand
2. **Week 2**: US2 (T031-T042)
   - Ship enhancement: Portfolio summary with realized P&L
3. **Week 3**: US3 + Polish (T043-T069)
   - Ship complete feature: Transaction history access + performance validation

### Success Metrics

- **Tests Written**: 10 unit tests (T002-T010) MUST pass before implementation
- **Performance**:
  - Computation < 100ms for 100 transactions ✅
  - UI update < 500ms when position closes ✅
  - 60fps scrolling with 50+ closed positions ✅
- **Code Quality**:
  - All Decimal types for financial values ✅
  - @Observable ViewModel ✅
  - Stateless views ✅
  - Constitution compliance ✅

---

**Total Tasks**: 69
**Critical Path**: T001-T016 (Foundational) → T017-T030 (US1) → T031-T042 (US2) → T043-T048 (US3) → T049-T069 (Polish)
**Parallel Opportunities**: 28 tasks marked [P] can run in parallel
**Estimated Effort**: 2-3 days for experienced iOS developer (MVP = 1-2 days)

**Next Step**: Begin Phase 2 (Foundational) by writing unit tests T001-T010 BEFORE implementing computation logic.
