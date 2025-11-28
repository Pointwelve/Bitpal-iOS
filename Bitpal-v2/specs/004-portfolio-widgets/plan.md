# Implementation Plan: iOS Home Screen Widgets for Portfolio

**Branch**: `004-portfolio-widgets` | **Date**: 2025-11-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-portfolio-widgets/spec.md`

## Summary

Add WidgetKit-based home screen widgets (small, medium, large) that display portfolio value, P&L breakdown, and top holdings at a glance. Widgets share data with the main app via App Groups, refresh every 30 minutes, and support offline display with cached data.

## Technical Context

**Language/Version**: Swift 6.0+ (iOS 26+)
**Primary Dependencies**: WidgetKit, SwiftUI, Swift Data, App Groups
**Storage**: Swift Data (shared via App Group container)
**Testing**: XCTest (unit tests for widget data provider, shared calculations)
**Target Platform**: iOS 26+ (iPhone only for widgets)
**Project Type**: Mobile (iOS app + Widget extension)
**Performance Goals**: Widget renders in <1 second, 30-minute refresh cycle, <30MB memory
**Constraints**: 30-minute max refresh (WidgetKit limitation), offline-capable with cached data
**Scale/Scope**: 3 widget sizes, single portfolio

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with Bitpal Constitution v2.0.0 (see `.specify/memory/constitution.md`):

### Principle I: Performance-First Architecture ✓
- [x] Feature maintains 60fps UI smoothness - Widgets are static views, no scrolling
- [x] Price updates throttled to 30-second intervals (no real-time) - N/A for widgets
- [x] Uses two-tier caching (memory + Swift Data) - App Group shared container with Swift Data
- [x] API requests are batched (no individual coin requests) - Widget uses pre-cached data from app
- [x] Lists >10 items use LazyVStack - Large widget shows max 5 items
- [x] Async operations non-blocking (MainActor for UI updates) - Widget timeline provider uses async
- [x] Cached computed values with explicit invalidation - Widget reads pre-computed data
- [x] Widget efficiency: Timeline refreshes every 30 minutes (per FR-004)

### Principle II: Liquid Glass Design System ✓
- [x] Uses iOS 26 translucent materials (.ultraThinMaterial, .regularMaterial) - containerBackground
- [x] Rounded corners 12-16pt radius - Widget system handles corners
- [x] System colors for Dark Mode support - Uses Color.primary, .green, .red
- [x] Supports Dynamic Type (.medium to .accessibilityExtraLarge) - Widget text scales
- [x] Spring animations (response: 0.3, dampingFraction: 0.7) - N/A for static widgets
- [x] Minimum 44x44pt tap targets - Entire widget is tappable
- [x] Uses standard spacing scale (xs/sm/md/lg/xl/xxl) - Consistent with main app
- [x] Widget design matches main app - containerBackground with system materials

### Principle III: MVVM + Modern Swift Patterns ✓
- [x] ViewModels use @Observable (NOT ObservableObject) - N/A for widgets (no ViewModel)
- [x] SwiftUI views are stateless (no business logic) - Widget views are pure SwiftUI
- [x] Services use singleton pattern - Shared data provider singleton
- [x] Swift Data for persistence (NOT Core Data) - App Group container uses Swift Data
- [x] App Groups for sharing - Widget accesses data via App Group container
- [x] async/await for concurrency (NOT Combine) - Timeline provider uses async
- [x] Structs preferred over classes - Widget entry is a struct
- [x] Minimal external dependencies - Only WidgetKit (Apple framework)

### Principle IV: Data Integrity & Calculation Accuracy ✓
- [x] Decimal type for money - All P&L values use Decimal (existing models)
- [x] P&L calculations tested - Reuse existing tested calculation functions
- [x] Widget calculations consistent - Widget uses shared calculation code (FR-007)
- [x] Cached computed values - Widget reads pre-computed PortfolioSummary
- [x] API response parsing validated - Existing CoinGeckoService parsing
- [x] Proper transaction accounting - Existing computeHoldings() logic

### Principle V: Phase Discipline (Scope Management) ✓
- [x] Feature is explicitly IN Phase 2 scope (see constitution v2.0.0)
- [x] NO out-of-scope features included:
  - ❌ Watchlist widgets - Portfolio only
  - ❌ Lock screen widgets - Home screen only
  - ❌ Widget configuration UI - Not included
  - ❌ Widget customization - Not included
  - ❌ Interactive widgets - Tap only opens app
  - ❌ Live Activities - Not included
  - ❌ Any monetization - Not included
- [x] No premature optimization for future phases
- [x] Feature maps to Phase 2 Widget requirements exactly

**GATE STATUS**: ✅ All applicable boxes checked - Proceed to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/004-portfolio-widgets/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A for widgets (no API contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Bitpal/
├── App/
│   └── BitpalApp.swift          # Add App Group container configuration
├── Features/
│   ├── Portfolio/
│   │   ├── Models/
│   │   │   ├── Holding.swift            # Existing (no changes)
│   │   │   └── PortfolioSummary.swift   # Existing (no changes)
│   │   └── ViewModels/
│   │       └── PortfolioViewModel.swift # Add cache invalidation trigger
│   └── Widget/                          # NEW: Widget support in main app
│       └── WidgetDataProvider.swift     # Shared data provider for widget
├── Shared/                              # NEW: Code shared between app and widget
│   ├── Models/
│   │   ├── WidgetPortfolioData.swift    # Widget-specific data structure
│   │   └── WidgetHolding.swift          # Simplified holding for widget
│   ├── Services/
│   │   └── AppGroupStorage.swift        # App Group data access
│   └── Calculations/
│       └── PortfolioCalculations.swift  # Extracted shared calculation logic
└── Utilities/
    └── Logger.swift                     # Add .widget category

BitpalWidget/                            # NEW: Widget extension target
├── BitpalWidget.swift                   # Widget configuration
├── BitpalWidgetBundle.swift             # Widget bundle entry point
├── Provider/
│   └── PortfolioTimelineProvider.swift  # Timeline provider
├── Views/
│   ├── SmallWidgetView.swift            # Small widget UI
│   ├── MediumWidgetView.swift           # Medium widget UI
│   └── LargeWidgetView.swift            # Large widget UI
├── Entry/
│   └── PortfolioEntry.swift             # Timeline entry model
└── Resources/
    └── Assets.xcassets                  # Widget preview assets

BitpalTests/
└── WidgetTests/                         # NEW: Widget-specific tests
    ├── WidgetDataProviderTests.swift
    └── PortfolioEntryTests.swift
```

**Structure Decision**: Mobile iOS app with Widget extension target. Shared code extracted to `Shared/` directory accessible by both app and widget via App Group container.

## Complexity Tracking

No constitution violations requiring justification. Design follows existing patterns.
