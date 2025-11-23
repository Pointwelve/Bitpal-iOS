# Implementation Plan: Closed Positions & Realized P&L

**Branch**: `003-closed-positions` | **Date**: 2025-01-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-closed-positions/spec.md`

## Summary

This feature extends the Portfolio to track closed trading positions (coins fully sold) and display realized profit/loss alongside unrealized P&L from active holdings. The primary technical approach is to compute closed positions on-the-fly from existing Transaction records, using cycle boundaries to identify separate buy-sell cycles for the same coin. The implementation reuses existing Portfolio infrastructure (Transaction model, Holding calculation patterns, UI components) and adds new computed models for ClosedPosition tracking.

**Key Technical Approach**:
- Compute closed positions from Transaction records (no new storage)
- Track multiple buy/sell cycles per coin using close date as cycle identifier
- Extend PortfolioViewModel to manage both open holdings and closed positions
- Add collapsible section to Portfolio UI (collapsed when > 5 closed positions)
- Enhance portfolio summary to show unrealized + realized + total P&L

## Technical Context

**Language/Version**: Swift 6.0 (iOS 26+, Xcode 17+)
**Primary Dependencies**: SwiftUI, SwiftData, Foundation (no external dependencies per Constitution Principle III)
**Storage**: Swift Data for Transaction persistence (@Model), ClosedPosition computed in-memory from Transaction records
**Testing**: XCTest for unit tests (closed position calculation, cycle detection, P&L computation), Manual testing for UI flows
**Target Platform**: iOS 26+ (iPhone 13 and newer devices)
**Project Type**: Mobile (iOS) - feature module within Bitpal/Features/Portfolio/
**Performance Goals**:
  - 60fps scrolling for closed positions list (Constitution Principle I)
  - Closed position computation < 100ms for 100 transactions (Assumption #7)
  - UI update < 500ms when position closes (SC-006)
**Constraints**:
  - No new database storage (compute from existing Transaction records)
  - Reuse existing Portfolio UI components (LiquidGlassCard, TransactionHistoryView)
  - Must handle Decimal precision (tolerance 0.00000001 for closed detection)
**Scale/Scope**:
  - Support 50+ closed positions without performance degradation (SC-004)
  - Handle multiple buy/sell cycles per coin
  - Collapsed UI for > 5 closed positions

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with Bitpal Constitution v1.0.0 (see `.specify/memory/constitution.md`):

### Principle I: Performance-First Architecture ✓
- [x] Feature maintains 60fps UI smoothness (LazyVStack for closed positions list, cached computations)
- [x] Price updates throttled to 30-second intervals (no change - reuses existing price update service)
- [x] Uses two-tier caching (in-memory computed ClosedPosition array + Swift Data Transaction records)
- [x] API requests are batched (no new API calls - uses existing Transaction and Coin data)
- [x] Lists >10 items use LazyVStack (closed positions list uses LazyVStack)
- [x] Async operations non-blocking (closed position computation runs in background, MainActor for UI)
- [x] Computed values cached (closed positions array cached in ViewModel, invalidated on transaction changes)

### Principle II: Liquid Glass Design System ✓
- [x] Uses iOS 26 translucent materials (LiquidGlassCard for closed position rows, .ultraThinMaterial for section header)
- [x] Rounded corners 12-16pt radius (reuses existing LiquidGlassCard component)
- [x] System colors for Dark Mode support (.profitGreen, .lossRed, .textPrimary, .textSecondary)
- [x] Supports Dynamic Type (uses Typography.* throughout)
- [x] Spring animations (collapse/expand animation: response: 0.3, dampingFraction: 0.7)
- [x] Minimum 44x44pt tap targets (section header, closed position rows)
- [x] Uses standard spacing scale (Spacing.small, .medium, .large)

### Principle III: MVVM + Modern Swift Patterns ✓
- [x] ViewModels use @Observable (PortfolioViewModel extended with @Observable macro)
- [x] SwiftUI views are stateless (ClosedPositionsView is declarative, no business logic)
- [x] Services use singleton pattern (no new services - reuses existing)
- [x] Swift Data for persistence (Transaction @Model already exists, no new storage)
- [x] async/await concurrency (closed position computation uses async/await)
- [x] Structs preferred over classes (ClosedPosition is struct)
- [x] NO external dependencies (100% native Swift/SwiftUI)

### Principle IV: Data Integrity & Calculation Accuracy ✓
- [x] Financial values use Decimal (ClosedPosition uses Decimal for all money values)
- [x] P&L calculations have unit tests written BEFORE implementation (test-first for realized P&L calculation)
- [x] Calculations are independently verifiable (users can verify from transaction history)
- [x] Computed values cached with invalidation (closed positions cached, invalidated on transaction add/edit/delete)
- [x] API parsing includes error handling (no new API calls)
- [x] Transaction accounting follows standard principles (weighted average calculation matches existing Holding model)

### Principle V: Phase Discipline (Scope Management) ✓
- [x] Feature is explicitly IN Phase 1 scope (Manual Portfolio extension, spec validated)
- [x] NO out-of-scope features included:
  - ✓ No wallet integration
  - ✓ No multiple portfolios
  - ✓ No charts/graphs (future consideration only)
  - ✓ No price alerts
  - ✓ No widgets
  - ✓ No ads/monetization
  - ✓ No social features
  - ✓ No iCloud sync
  - ✓ No export functionality (future consideration only)
- [x] No premature optimization for future phases (cycle detection is current requirement)
- [x] Feature maps to Phase 1 Manual Portfolio requirements (natural extension of 002-portfolio)

**GATE STATUS**: ✅ PASSED - All constitution principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/003-closed-positions/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (no research needed - extends existing 002-portfolio)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (N/A - no API contracts, uses existing models)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
Bitpal/
└── Features/
    └── Portfolio/                          # Extends existing 002-portfolio feature
        ├── Models/
        │   ├── Transaction.swift           # Existing (@Model)
        │   ├── Holding.swift               # Existing (computed)
        │   ├── ClosedPosition.swift        # NEW (computed from Transactions)
        │   └── PortfolioSummary.swift      # NEW (extends existing portfolio summary logic)
        ├── ViewModels/
        │   └── PortfolioViewModel.swift    # MODIFIED (add closed positions computation)
        └── Views/
            ├── PortfolioView.swift         # MODIFIED (add Closed Positions section)
            ├── ClosedPositionsSection.swift # NEW (collapsible section view)
            ├── ClosedPositionRowView.swift # NEW (individual row view)
            └── PortfolioSummaryView.swift  # MODIFIED (add realized P&L, total P&L)

BitpalTests/
└── Features/
    └── Portfolio/
        └── ClosedPositionTests.swift       # NEW (test cycle detection, P&L calculation)
```

**Structure Decision**: Mobile (iOS) feature module. This feature extends the existing `Bitpal/Features/Portfolio/` directory structure from 002-portfolio. No new top-level directories needed. All new files are scoped under Portfolio feature folder following existing MVVM organization (Models, ViewModels, Views).

## Complexity Tracking

> **No constitution violations** - this section is empty (all gates passed)

---

## Phase 0: Research & Unknowns Resolution

**Status**: ✅ No research needed

**Rationale**: This feature extends the existing 002-portfolio implementation with well-understood requirements:
- Transaction model already exists (@Model in Swift Data)
- Holding calculation pattern established (weighted average cost)
- UI components already built (LiquidGlassCard, TransactionHistoryView)
- Cycle detection logic is straightforward (chronological grouping with balance tracking)

All technical unknowns have been resolved during specification:
- Multiple cycle tracking: Separate entries per close date (Clarification Session 2025-01-22)
- Collapsed state behavior: Header with count, tap to expand/collapse (Clarification Session 2025-01-22)
- Close threshold: 0.00000001 tolerance (Assumption #1)
- Performance target: < 100ms computation (Assumption #7)

**Decision**: Skip research.md generation - proceed directly to Phase 1 design.

---

## Phase 1: Design & Contracts

### Data Model Design

See [data-model.md](./data-model.md) for complete entity definitions.

**Key Models**:

1. **ClosedPosition** (struct, computed)
   - Represents single buy-sell cycle for a coin
   - Computed from Transaction records (not persisted)
   - Properties: coinId, coin, totalQuantity, avgCostPrice, avgSalePrice, realizedPnL, realizedPnLPercentage, closedDate, cycleTransactions

2. **PortfolioSummary** (struct, computed)
   - Aggregates portfolio performance metrics
   - Properties: totalValue (open holdings), unrealizedPnL, realizedPnL, totalPnL

### API Contracts

**Status**: N/A - No API contracts required

**Rationale**: This feature uses only existing data models (Transaction, Coin) and computes derived values in-memory. No new backend API endpoints, no external service integration.

### Quickstart Guide

See [quickstart.md](./quickstart.md) for developer onboarding.

---

## Implementation Phases (for /speckit.tasks)

The following phases will be converted to tasks by `/speckit.tasks`:

### Phase 1: Core Calculation Logic (P1 - Critical)

**Goal**: Implement cycle detection and closed position computation

1. Create `ClosedPosition.swift` model with all properties
2. Implement `computeClosedPositions()` function with cycle detection algorithm
3. Write unit tests for cycle detection (single cycle, multiple cycles, edge cases)
4. Write unit tests for realized P&L calculation (profit, loss, zero-cost basis)

**Acceptance**: Unit tests pass, closed positions correctly identified from transactions

### Phase 2: ViewModel Integration (P1 - Critical)

**Goal**: Extend PortfolioViewModel to manage closed positions

1. Add `@Published var closedPositions: [ClosedPosition] = []` to PortfolioViewModel
2. Implement `refreshClosedPositions()` method (calls `computeClosedPositions()`)
3. Add cache invalidation on transaction add/edit/delete
4. Create `PortfolioSummary.swift` model
5. Implement `portfolioSummary` computed property (total value, unrealized, realized, total P&L)

**Acceptance**: ViewModel correctly computes and caches closed positions, invalidates on changes

### Phase 3: UI - Closed Positions Section (P1 - Critical)

**Goal**: Display closed positions in Portfolio view

1. Create `ClosedPositionRowView.swift` (coin name, symbol, quantity, P&L, close date)
2. Create `ClosedPositionsSection.swift` (collapsible section with header)
3. Implement collapse/expand state management (@State variable, tap gesture)
4. Integrate section into `PortfolioView.swift` below active holdings
5. Hide section when closedPositions.isEmpty
6. Apply Liquid Glass design (LiquidGlassCard, spacing, colors)

**Acceptance**: Closed positions display correctly, collapse/expand works, hidden when empty

### Phase 4: UI - Portfolio Summary Enhancement (P2)

**Goal**: Show unrealized + realized + total P&L in summary

1. Modify `PortfolioSummaryView.swift` to show 4 rows:
   - Total Value (current holdings)
   - Unrealized P&L (open positions) - green/red
   - Realized P&L (closed positions) - green/red
   - Total P&L (sum) - green/red, bold
2. Add tap gesture to "Realized P&L" row to scroll to Closed Positions section

**Acceptance**: Portfolio summary displays all 4 metrics, tap scrolls to section

### Phase 5: Transaction History Integration (P3)

**Goal**: Allow users to view transaction history for closed positions

1. Make ClosedPositionRowView tappable
2. Pass closed position's coinId to TransactionHistoryView
3. Reuse existing TransactionHistoryView (no changes needed)

**Acceptance**: Tapping closed position opens transaction history

### Phase 6: Testing & Polish (P1 - Critical)

**Goal**: Verify performance, edge cases, and visual design

1. Test with 50+ closed positions (verify 60fps scrolling)
2. Test multiple close/reopen cycles (verify separate entries)
3. Test fractional amounts (verify 0.00000001 tolerance)
4. Test transaction deletion (verify position moves back to open)
5. Test collapse threshold (5 vs 6+ positions)
6. Profile with Instruments (verify < 100ms computation, < 500ms UI update)

**Acceptance**: All edge cases handled, performance targets met, UI polished

---

## Next Steps

1. ✅ Constitution Check passed
2. ✅ Phase 0 skipped (no research needed)
3. ⏭️ Generate `data-model.md` (Phase 1)
4. ⏭️ Generate `quickstart.md` (Phase 1)
5. ⏭️ Run `/speckit.tasks` to generate `tasks.md` with implementation checklist
