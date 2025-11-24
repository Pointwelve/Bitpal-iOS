# Implementation Plan: Watchlist

**Branch**: `001-watchlist` | **Date**: 2025-11-08 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-watchlist/spec.md`

## Summary

The Watchlist feature allows users to track cryptocurrency prices in real-time without investment commitments. Users can search and add coins from CoinGecko's database, monitor price movements at a glance, and organize their list through sorting. The feature emphasizes performance (60fps scrolling, smooth updates) and follows iOS 26 Liquid Glass design language.

**Technical Approach**: SwiftUI + @Observable MVVM architecture with Swift Data persistence. CoinGecko API for price data with two-tier caching (memory + Swift Data). Background price updates every 30 seconds using async/await. LazyVStack for efficient list rendering.

## Technical Context

**Language/Version**: Swift 6.0
**Primary Dependencies**: SwiftUI, Swift Data, URLSession (NO external dependencies per Constitution)
**Storage**: Swift Data (local persistence), Two-tier caching (in-memory + Swift Data)
**Testing**: XCTest (required for API parsing, optional for UI per Constitution)
**Target Platform**: iOS 26+ (released September 2025)
**Project Type**: Mobile (iOS single-platform)
**Performance Goals**: 60fps scrolling, 30-second update intervals, <1s search results
**Constraints**: <100MB memory with 100 coins, no UI blocking during API calls, offline-capable with cached data
**Scale/Scope**: Phase 1 MVP - Watchlist only (NO portfolio, charts, alerts per Constitution Principle V)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with Bitpal Constitution v1.0.0 (see `.specify/memory/constitution.md`):

### Principle I: Performance-First Architecture ✓
- [x] Feature maintains 60fps UI smoothness
- [x] Price updates throttled to 30-second intervals (no real-time)
- [x] Uses two-tier caching (memory + Swift Data)
- [x] API requests are batched (no individual coin requests)
- [x] Lists >10 items use LazyVStack
- [x] Async operations non-blocking (MainActor for UI updates)
- [x] Computed values cached with explicit invalidation

**Rationale**: Watchlist displays list of coins (LazyVStack), fetches prices in batch via CoinGecko /coins/markets endpoint, updates every 30s in background using Task, caches Coin data in memory and WatchlistItem in Swift Data.

### Principle II: Liquid Glass Design System ✓
- [x] Uses iOS 26 translucent materials (.ultraThinMaterial, .regularMaterial)
- [x] Rounded corners 12-16pt radius
- [x] System colors for Dark Mode support
- [x] Supports Dynamic Type (.medium to .accessibilityExtraLarge)
- [x] Spring animations (response: 0.3, dampingFraction: 0.7)
- [x] Minimum 44x44pt tap targets
- [x] Uses standard spacing scale (xs/sm/md/lg/xl/xxl)

**Rationale**: CoinRowView uses LiquidGlassCard component with .ultraThinMaterial, color-coded price changes (system .green/.red), Dynamic Type fonts, smooth animations for add/delete.

### Principle III: MVVM + Modern Swift Patterns ✓
- [x] ViewModels use @Observable (NOT ObservableObject)
- [x] SwiftUI views are stateless (no business logic)
- [x] Services use singleton pattern
- [x] Swift Data for persistence (NOT Core Data)
- [x] async/await concurrency (NOT Combine)
- [x] Structs preferred over classes
- [x] NO external dependencies

**Rationale**: WatchlistViewModel uses @Observable, WatchlistView is stateless, CoinGeckoService.shared singleton, Swift Data for WatchlistItem, async/await for API calls, Coin is struct.

### Principle IV: Data Integrity & Calculation Accuracy ✓
- [x] Financial values use Decimal (NOT Double/Float)
- [x] P&L calculations have unit tests written BEFORE implementation
- [x] Calculations are independently verifiable
- [x] Computed values cached with invalidation
- [x] API parsing includes error handling
- [x] Transaction accounting follows standard principles

**Rationale**: Coin.currentPrice and priceChange24h use Decimal type. API response parsing has error handling (try/catch). No P&L calculations in Watchlist (Portfolio feature only), but price parsing is validated.

### Principle V: Phase Discipline (Scope Management) ✓
- [x] Feature is explicitly IN Phase 1 scope (see CLAUDE.md)
- [x] NO out-of-scope features included:
  - ✅ No wallet integration
  - ✅ No multiple portfolios
  - ✅ No charts/graphs (only current price + 24h change)
  - ✅ No price alerts
  - ✅ No widgets
  - ✅ No ads/monetization
  - ✅ No social features
  - ✅ No iCloud sync
  - ✅ No export functionality
- [x] No premature optimization for future phases
- [x] Feature maps to Phase 1 Watchlist OR Manual Portfolio requirements

**Rationale**: Watchlist is first feature listed in Phase 1 MVP scope (CLAUDE.md lines 22-29). Only implements: search, add, display, sort, remove, refresh. NO out-of-scope features.

**GATE STATUS**: ✅ PASS - All principles satisfied

## Project Structure

### Documentation (this feature)

```text
specs/001-watchlist/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (created)
├── research.md          # Phase 0 output (next step)
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── coingecko-api.yaml
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

**Structure Decision**: Mobile (iOS) project with feature-based organization per CLAUDE.md

```text
Bitpal/
├── App/
│   ├── BitpalApp.swift              # App entry point
│   └── ContentView.swift            # Root tab navigation (Watchlist tab default)
│
├── Features/
│   └── Watchlist/
│       ├── Views/
│       │   ├── WatchlistView.swift       # Main list view
│       │   ├── CoinSearchView.swift      # Search sheet
│       │   └── CoinRowView.swift         # Individual coin row
│       ├── ViewModels/
│       │   └── WatchlistViewModel.swift  # @Observable business logic
│       └── Models/
│           └── WatchlistItem.swift       # Swift Data model
│
├── Services/
│   ├── CoinGeckoService.swift       # API client (singleton)
│   └── PriceUpdateService.swift     # Background 30s updates
│
├── Models/
│   ├── Coin.swift                   # Shared coin model (from API)
│   └── APIResponse.swift            # CoinGecko response models
│
├── Design/
│   ├── Components/
│   │   ├── LiquidGlassCard.swift    # Reusable glass card
│   │   ├── PriceChangeLabel.swift   # Color-coded % change
│   │   └── LoadingView.swift        # Pull-to-refresh indicator
│   ├── Styles/
│   │   ├── Colors.swift             # System color extensions
│   │   ├── Spacing.swift            # Spacing scale
│   │   └── Typography.swift         # Font styles
│   └── Extensions/
│       ├── View+Extensions.swift
│       └── Decimal+Extensions.swift
│
└── Utilities/
    ├── Logger.swift                 # OSLog categorized loggers
    └── Formatters.swift             # Number/date formatters

BitpalTests/
└── WatchlistTests/
    ├── CoinGeckoServiceTests.swift  # API parsing tests (REQUIRED)
    └── PriceUpdateTests.swift       # Update logic tests (REQUIRED)

BitpalUITests/
└── WatchlistUITests.swift           # Manual testing acceptable
```

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. All Constitution principles satisfied.
