# Implementation Plan: Widget Background Refresh

**Branch**: `008-widget-background-refresh` | **Date**: 2025-12-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/008-widget-background-refresh/spec.md`

## Summary

Enable the portfolio widget to fetch fresh cryptocurrency prices directly from the CoinGecko API when iOS requests a timeline refresh, eliminating the requirement to open the main app for data updates. The widget will store coin quantities and cost basis in App Group to recalculate P&L with fresh prices.

## Technical Context

**Language/Version**: Swift 6.0+ (iOS 26+)
**Primary Dependencies**: SwiftUI, WidgetKit, URLSession (async/await)
**Storage**: App Groups JSON file (`group.com.bitpal.shared`)
**Testing**: XCTest
**Target Platform**: iOS 26+
**Project Type**: Mobile (iOS app + widget extension)
**Performance Goals**: Widget refresh completes within 15 seconds; 60fps UI maintained
**Constraints**: WidgetKit time budget (~15-30 seconds); offline-capable with cached fallback
**Scale/Scope**: <50 holdings per user; single batched API request per refresh

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with Bitpal Constitution v3.0.0:

### Principle I: Performance-First Architecture ✓
- [x] Feature maintains 60fps UI smoothness (widget is static, no scrolling)
- [x] Price updates throttled to 30-second intervals (widget uses 15-30 min iOS-controlled refresh)
- [x] Uses two-tier caching (App Group JSON cache + API fetch)
- [x] API requests are batched (single request for all coin IDs)
- [N/A] Lists >10 items use LazyVStack (widget displays max 5 holdings)
- [x] Async operations non-blocking (async/await in getTimeline)
- [x] Computed values cached with explicit invalidation (P&L cached in WidgetPortfolioData)

### Principle II: Liquid Glass Design System ✓
- [N/A] Uses iOS 26 translucent materials (no UI changes in this feature)
- [N/A] Rounded corners 12-16pt radius (existing widget design unchanged)
- [N/A] System colors for Dark Mode support (existing)
- [N/A] Supports Dynamic Type (existing)
- [N/A] Spring animations (no animations in widget)
- [N/A] Minimum 44x44pt tap targets (existing)
- [N/A] Uses standard spacing scale (existing)

### Principle III: MVVM + Modern Swift Patterns ✓
- [N/A] ViewModels use @Observable (widget uses TimelineProvider, not ViewModel)
- [x] SwiftUI views are stateless (widget views are declarative)
- [x] Services use singleton pattern (WidgetAPIClient as static methods)
- [x] Swift Data for persistence (App Groups JSON for widget sharing - per constitution)
- [x] async/await concurrency (used in getTimeline)
- [x] Structs preferred over classes (WidgetRefreshData, WidgetAPIClient are structs)
- [x] NO external dependencies (URLSession native)

### Principle IV: Data Integrity & Calculation Accuracy ✓
- [x] Financial values use Decimal (WidgetRefreshData uses Decimal)
- [x] P&L calculations have unit tests written BEFORE implementation
- [x] Calculations are independently verifiable (same formula as main app)
- [x] Computed values cached with invalidation (WidgetPortfolioData)
- [x] API parsing includes error handling (graceful fallback)
- [x] Transaction accounting follows standard principles (reuses existing logic)

### Principle V: Phase Discipline (Scope Management) ✓
- [x] Feature is explicitly IN scope: Enhancement to Phase 2 Widgets (fixing stale data issue)
- [x] NO out-of-scope features included:
  - ❌ Wallet integration - Not included
  - ❌ Multiple portfolios - Not included
  - ❌ Charts/graphs - Not included
  - ❌ Price alerts - Not included
  - ✅ Widgets - Phase 2 complete, this is a bug fix/enhancement
  - ❌ Ads/monetization - Not included
  - ❌ Social features - Not included
  - ❌ iCloud sync - Not included
  - ❌ Export functionality - Not included
- [x] No premature optimization for future phases
- [x] Feature enhances existing Phase 2 Widget functionality

**GATE STATUS**: ✅ PASSED - All applicable principles verified.

**Note**: This feature is an enhancement to Phase 2 Widgets (marked COMPLETE in constitution). The current widget implementation has a defect where data becomes stale because the widget doesn't fetch prices directly. This fix enables widgets to fulfill their intended purpose per constitution: "Always show cached data when API unavailable" and "Widget values MUST match main app exactly."

## Project Structure

### Documentation (this feature)

```text
specs/008-widget-background-refresh/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contract)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Bitpal/
├── Shared/
│   ├── Models/
│   │   └── WidgetRefreshData.swift     # NEW: Quantities for recalculation
│   └── Services/
│       └── AppGroupStorage.swift       # MODIFY: Add refresh data methods
├── Features/
│   └── Widget/
│       └── WidgetDataProvider.swift    # MODIFY: Write refresh data

BitpalWidget/
├── Services/
│   └── WidgetAPIClient.swift           # NEW: Lightweight API client
└── Provider/
    └── PortfolioTimelineProvider.swift # MODIFY: Fetch prices in getTimeline

BitpalTests/
└── WidgetTests/
    └── WidgetRefreshTests.swift        # NEW: P&L recalculation tests
```

**Structure Decision**: Follows existing feature-based organization. New files go in `Shared/Models/` (accessible by both app and widget) and `BitpalWidget/Services/` (widget-only API client).

## Complexity Tracking

> No constitution violations requiring justification.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
