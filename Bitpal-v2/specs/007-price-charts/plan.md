# Implementation Plan: Per-Coin Price Charts

**Branch**: `007-price-charts` | **Date**: 2025-12-01 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-price-charts/spec.md`

## Summary

Implement a new coin detail screen with interactive price charts supporting both line and candlestick visualizations. Users can view price history across multiple time ranges (15M to 1Y), toggle between chart types, and inspect specific price points via touch interaction. The screen also displays coin header information and market statistics.

## Technical Context

**Language/Version**: Swift 6.0+ (iOS 26+)
**Primary Dependencies**: SwiftUI, Swift Data, Swift Charts, URLSession
**Storage**: Swift Data for chart cache, UserDefaults for chart type preference
**Testing**: XCTest for unit tests, manual testing for UI
**Target Platform**: iOS 26+
**Project Type**: Mobile (iOS)
**Performance Goals**: 60fps chart interactions, <3s initial load, <300ms transitions
**Constraints**: Offline-capable (cached data), <200ms touch response, no external charting libraries
**Scale/Scope**: Single coin detail screen, 2 chart types, 7 time ranges

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Verify compliance with Bitpal Constitution v3.0.0 (see `.specify/memory/constitution.md`):

### Principle I: Performance-First Architecture ✓
- [x] Feature maintains 60fps UI smoothness (FR-026)
- [x] Price updates use appropriate caching TTL (1min-1hr based on range)
- [x] Uses two-tier caching (memory + Swift Data for chart data)
- [x] API requests batched where possible (coin detail + chart in sequence)
- [x] Chart data points are reasonable (<100 points per view)
- [x] Async operations non-blocking (MainActor for UI updates)
- [x] Computed values cached with explicit invalidation

### Principle II: Liquid Glass Design System ✓
- [x] Uses iOS 26 translucent materials (FR-027)
- [x] Rounded corners 12-16pt radius for cards
- [x] System colors for Dark Mode support (green/red for price movement)
- [x] Supports Dynamic Type
- [x] Spring animations (response: 0.3, dampingFraction: 0.7)
- [x] Minimum 44x44pt tap targets (time range buttons, chart type toggle)
- [x] Uses standard spacing scale

### Principle III: MVVM + Modern Swift Patterns ✓
- [x] ViewModels use @Observable (CoinDetailViewModel)
- [x] SwiftUI views are stateless (CoinDetailView, ChartView)
- [x] Services use singleton pattern (CoinGeckoService extension)
- [x] Swift Data for persistence (chart cache)
- [x] async/await concurrency
- [x] Structs preferred (ChartDataPoint, CandleDataPoint)
- [x] NO external dependencies (using Swift Charts, native)

### Principle IV: Data Integrity & Calculation Accuracy ✓
- [x] Financial values use Decimal for prices
- [x] Chart data parsing includes error handling
- [x] Period high/low calculations are accurate
- [x] Price change calculations are verifiable

### Principle V: Phase Discipline (Scope Management) ✓
- [x] Feature is explicitly IN Phase 3 scope: "Price charts per coin (1D, 1W, 1M, 1Y)"
- [x] NO out-of-scope features included:
  - ✓ No portfolio chart (separate Phase 3 feature)
  - ✓ No price alerts (separate Phase 3 feature)
  - ✓ No trading functionality
  - ✓ No social features
- [x] No premature optimization for future phases
- [x] Feature maps to Phase 3 Visual Intelligence requirements

**GATE STATUS**: ✅ All applicable boxes checked. Proceeding to Phase 0 research.

## Project Structure

### Documentation (this feature)

```text
specs/007-price-charts/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (API contracts)
│   └── coingecko-chart-api.yaml
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Bitpal/
├── Features/
│   ├── CoinDetail/                    # NEW - This feature
│   │   ├── Views/
│   │   │   ├── CoinDetailView.swift       # Main screen
│   │   │   ├── CoinHeaderView.swift       # Header with logo, price, 24h change
│   │   │   ├── MarketStatsView.swift      # Market cap, volume, supply
│   │   │   ├── PriceChartView.swift       # Chart container with controls
│   │   │   ├── LineChartView.swift        # Line chart rendering
│   │   │   └── CandlestickChartView.swift # Candlestick chart rendering
│   │   ├── ViewModels/
│   │   │   └── CoinDetailViewModel.swift  # @Observable ViewModel
│   │   └── Models/
│   │       ├── ChartDataPoint.swift       # Line chart data
│   │       ├── CandleDataPoint.swift      # OHLC candlestick data
│   │       ├── ChartTimeRange.swift       # Time range enum
│   │       └── ChartType.swift            # Chart type enum
│   ├── Watchlist/
│   │   └── Views/
│   │       └── WatchlistRowView.swift     # UPDATE - Add navigation to CoinDetail
│   └── Portfolio/
│       └── Views/
│           └── HoldingRowView.swift       # UPDATE - Add navigation to CoinDetail
├── Services/
│   └── CoinGeckoService.swift             # UPDATE - Add chart data endpoints
├── Models/
│   └── CoinDetail.swift                   # NEW - Coin detail model
└── Design/
    └── Components/
        └── ChartComponents/               # NEW - Reusable chart components
            ├── TimeRangeSelector.swift
            ├── ChartTypeToggle.swift
            └── PriceTooltip.swift

BitpalTests/
└── CoinDetailTests/
    ├── ChartDataParsingTests.swift
    └── CoinDetailViewModelTests.swift
```

**Structure Decision**: Feature folder pattern under `Features/CoinDetail/` following existing Watchlist/Portfolio structure. Chart components are reusable for future portfolio chart feature.

## Complexity Tracking

> No Constitution violations requiring justification. All requirements align with existing patterns.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Charting | Swift Charts (native) | No external dependencies per Principle III |
| Caching | Swift Data + Memory | Two-tier caching per Principle I |
| Navigation | NavigationLink | Standard SwiftUI navigation pattern |
