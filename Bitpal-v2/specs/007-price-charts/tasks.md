# Tasks: Per-Coin Price Charts

**Input**: Design documents from `/specs/007-price-charts/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for critical business logic and OPTIONAL for UI/simple operations.

**Tests REQUIRED** (must write BEFORE implementation):
- Chart data parsing (API response → model conversion)
- Chart statistics calculations (period high/low, price change)
- Cache key generation and expiration logic

**Tests OPTIONAL** (manual testing acceptable):
- SwiftUI views (visual review)
- Chart rendering and animations
- Navigation flows

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
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Feature code**: `Bitpal/Features/CoinDetail/`
- **Models**: `Bitpal/Features/CoinDetail/Models/`
- **Views**: `Bitpal/Features/CoinDetail/Views/`
- **ViewModels**: `Bitpal/Features/CoinDetail/ViewModels/`
- **Services**: `Bitpal/Services/`
- **Design components**: `Bitpal/Design/Components/ChartComponents/`
- **Tests**: `BitpalTests/CoinDetailTests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create feature folder structure and foundational models

- [ ] T001 Create feature directory structure: `Bitpal/Features/CoinDetail/{Views,ViewModels,Models}/`
- [ ] T002 Create chart components directory: `Bitpal/Design/Components/ChartComponents/`
- [ ] T003 Create test directory: `BitpalTests/CoinDetailTests/`
- [ ] T004 [P] Create ChartError.swift error enum in `Bitpal/Features/CoinDetail/Models/ChartError.swift`
- [ ] T005 [P] Add Logger.chart category extension in `Bitpal/Utilities/Logger.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and API integration that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Required Tests (Write FIRST, verify FAIL)

- [ ] T006 [P] Create chart data parsing tests in `BitpalTests/CoinDetailTests/ChartDataParsingTests.swift`
  - Test ChartDataPoint initialization from API array [timestamp, price]
  - Test CandleDataPoint initialization from API array [timestamp, open, high, low, close]
  - Test invalid/malformed data handling
  - Test Decimal conversion accuracy

- [ ] T007 [P] Create chart statistics tests in `BitpalTests/CoinDetailTests/ChartStatisticsTests.swift`
  - Test period high/low calculation from line data
  - Test period high/low calculation from candle data
  - Test price change and percentage calculation
  - Test empty data handling

### Core Models

- [ ] T008 [P] Create ChartDataPoint model in `Bitpal/Features/CoinDetail/Models/ChartDataPoint.swift`
  - timestamp: Date, price: Decimal
  - init?(from apiArray: [Double]) failable initializer
  - Array extension: toChartDataPoints()

- [ ] T009 [P] Create CandleDataPoint model in `Bitpal/Features/CoinDetail/Models/CandleDataPoint.swift`
  - timestamp, open, high, low, close: Decimal
  - isGreen, isRed computed properties
  - init?(from apiArray: [Double]) failable initializer
  - Array extension: toCandleDataPoints()

- [ ] T010 [P] Create ChartTimeRange enum in `Bitpal/Features/CoinDetail/Models/ChartTimeRange.swift`
  - Cases: fifteenMinutes, oneHour, fourHours, oneDay, oneWeek, oneMonth, oneYear
  - apiDays, maxDataPoints, cacheTTL computed properties
  - lineRanges and candleRanges static arrays

- [ ] T011 [P] Create ChartType enum in `Bitpal/Features/CoinDetail/Models/ChartType.swift`
  - Cases: line, candle
  - availableRanges, closestAvailableRange() methods
  - UserDefaults persistence: saveAsPreference(), loadPreference()

- [ ] T012 [P] Create ChartStatistics struct in `Bitpal/Features/CoinDetail/Models/ChartStatistics.swift`
  - periodHigh, periodLow, startPrice, endPrice
  - priceChange, percentageChange, isPositive computed properties
  - Factory methods: from(lineData:), from(candleData:)

- [ ] T013 Create CachedChartData Swift Data model in `Bitpal/Features/CoinDetail/Models/CachedChartData.swift`
  - @Model class with cacheKey, pricesJSON, cachedAt, expiresAt
  - makeCacheKey(), forLineChart(), forCandleChart() factory methods
  - decodeLineChartData(), decodeCandleChartData() methods

### API Response Models

- [ ] T014 [P] Create CoinDetailAPIResponse in `Bitpal/Features/CoinDetail/Models/CoinDetailAPIResponse.swift`
  - Nested ImageURLs, MarketData structs
  - toCoinDetail() conversion method

- [ ] T015 [P] Create MarketChartResponse in `Bitpal/Features/CoinDetail/Models/MarketChartResponse.swift`
  - prices, marketCaps, totalVolumes arrays
  - CodingKeys for snake_case mapping

- [ ] T016 Create CoinDetail model in `Bitpal/Models/CoinDetail.swift`
  - id, symbol, name, image, currentPrice, priceChange24h
  - marketCap, totalVolume, circulatingSupply, lastUpdated
  - Custom Decodable for Double→Decimal conversion

### Service Layer

- [ ] T017 Add chart API methods to `Bitpal/Services/CoinGeckoService.swift`
  - fetchCoinDetail(id:) → CoinDetail
  - fetchMarketChart(coinId:days:currency:) → [ChartDataPoint]
  - fetchOHLC(coinId:days:currency:) → [CandleDataPoint]
  - Use existing rateLimiter for all requests

- [ ] T018 Register CachedChartData model in `Bitpal/App/BitpalApp.swift`
  - Add to .modelContainer(for:) array

**Checkpoint**: Foundation ready - all models created, API methods implemented, tests passing

---

## Phase 3: User Story 1 - View Recent Price Movement (Priority: P1) 🎯 MVP

**Goal**: Display 1D line chart with price movement, high/low indicators, and green/red coloring

**Independent Test**: Navigate to any coin from watchlist, view 1D chart showing price movement with clear high/low and color-coded trend

### Implementation for User Story 1

- [ ] T019 [P] [US1] Create CoinDetailViewModel in `Bitpal/Features/CoinDetail/ViewModels/CoinDetailViewModel.swift`
  - @Observable class with coinId, coinDetail, lineChartData, chartStatistics
  - selectedTimeRange (default: .oneDay), isLoading, errorMessage state
  - loadInitialData(), loadChartData(forRange:) async methods
  - configure(modelContext:) for Swift Data access

- [ ] T020 [P] [US1] Create CoinHeaderView in `Bitpal/Features/CoinDetail/Views/CoinHeaderView.swift`
  - Display coin logo (AsyncImage), name, symbol
  - Current price with Formatters.formatPrice()
  - 24h change with PriceChangeLabel component

- [ ] T021 [P] [US1] Create MarketStatsView in `Bitpal/Features/CoinDetail/Views/MarketStatsView.swift`
  - Display market cap, 24h volume, circulating supply
  - Use LiquidGlassCard container
  - Format with Formatters.formatCompactCurrency()

- [ ] T022 [P] [US1] Create ChartStatsBar in `Bitpal/Design/Components/ChartComponents/ChartStatsBar.swift`
  - Display period high, period low, price change
  - Color-coded price change (green/red)
  - Use ChartStatistics struct

- [ ] T023 [US1] Create LineChartView in `Bitpal/Features/CoinDetail/Views/LineChartView.swift`
  - Swift Charts LineMark with catmullRom interpolation
  - Dynamic foregroundStyle based on isPositive (green/red)
  - chartXAxis and chartYAxis configuration
  - Liquid Glass styling with translucent background

- [ ] T024 [US1] Create PriceChartView container in `Bitpal/Features/CoinDetail/Views/PriceChartView.swift`
  - LiquidGlassCard container
  - ChartStatsBar for statistics display
  - Chart view placeholder (LineChartView initially)
  - Loading overlay when isLoadingChart

- [ ] T025 [US1] Create CoinDetailView main screen in `Bitpal/Features/CoinDetail/Views/CoinDetailView.swift`
  - ScrollView with LazyVStack layout
  - CoinHeaderView, PriceChartView, MarketStatsView sections
  - .task to call viewModel.loadInitialData()
  - .refreshable for pull-to-refresh
  - Error banner overlay

- [ ] T026 [US1] Add navigation from WatchlistRowView in `Bitpal/Features/Watchlist/Views/WatchlistRowView.swift`
  - Wrap row content in NavigationLink
  - Destination: CoinDetailView(coinId: coin.id)

- [ ] T027 [US1] Add navigation from HoldingRowView in `Bitpal/Features/Portfolio/Views/HoldingRowView.swift`
  - Wrap row content in NavigationLink
  - Destination: CoinDetailView(coinId: holding.coin.id)

**Checkpoint**: User Story 1 complete - Can navigate to coin detail, view 1D line chart with stats

---

## Phase 4: User Story 2 - Switch Chart Types (Priority: P2)

**Goal**: Toggle between line and candlestick charts with preference persistence

**Independent Test**: On any coin's chart, tap chart type toggle, verify switch between Line/Candle views and preference persists

### Implementation for User Story 2

- [ ] T028 [P] [US2] Create ChartTypeToggle component in `Bitpal/Design/Components/ChartComponents/ChartTypeToggle.swift`
  - Segmented picker with Line/Candle options
  - SF Symbols: chart.xyaxis.line, chart.bar.fill
  - Binding to selectedChartType
  - 44pt minimum tap targets

- [ ] T029 [P] [US2] Create CandlestickMark custom ChartContent in `Bitpal/Features/CoinDetail/Views/CandlestickMark.swift`
  - ChartContent protocol conformance
  - Two RectangleMark: wick (thin) and body (thick)
  - Green/red coloring based on isGreen

- [ ] T030 [US2] Create CandlestickChartView in `Bitpal/Features/CoinDetail/Views/CandlestickChartView.swift`
  - Swift Charts with CandlestickMark
  - ForEach over candleChartData
  - Match axis styling from LineChartView

- [ ] T031 [US2] Update CoinDetailViewModel for candlestick support in `Bitpal/Features/CoinDetail/ViewModels/CoinDetailViewModel.swift`
  - Add candleChartData: [CandleDataPoint] state
  - Add selectedChartType: ChartType state
  - Load preference on init with ChartType.loadPreference()
  - Save preference on change with saveAsPreference()
  - Switch between fetchMarketChart/fetchOHLC based on type

- [ ] T032 [US2] Update PriceChartView for chart type toggle in `Bitpal/Features/CoinDetail/Views/PriceChartView.swift`
  - Add ChartTypeToggle above chart
  - Switch between LineChartView/CandlestickChartView based on type
  - Animate transition with spring animation

**Checkpoint**: User Story 2 complete - Can toggle between chart types, preference persists

---

## Phase 5: User Story 3 - Analyze Different Time Ranges (Priority: P3)

**Goal**: Switch between time ranges with correct options per chart type

**Independent Test**: Verify Line shows 5 ranges (1H, 1D, 1W, 1M, 1Y), Candle shows 7 ranges (15M, 1H, 4H, 1D, 1W, 1M, 1Y), switching updates chart

### Implementation for User Story 3

- [ ] T033 [P] [US3] Create TimeRangeSelector in `Bitpal/Design/Components/ChartComponents/TimeRangeSelector.swift`
  - HStack of buttons for each time range
  - Dynamic ranges based on chart type (5 vs 7 options)
  - Selected state highlighting
  - 44pt minimum tap targets
  - Callback closure for selection

- [ ] T034 [US3] Update CoinDetailViewModel for time range switching in `Bitpal/Features/CoinDetail/ViewModels/CoinDetailViewModel.swift`
  - Add switchTimeRange(to:) async method
  - Add adjustTimeRangeIfNeeded() for chart type changes
  - Handle closestAvailableRange when switching chart types

- [ ] T035 [US3] Update PriceChartView for time range selector in `Bitpal/Features/CoinDetail/Views/PriceChartView.swift`
  - Add TimeRangeSelector below ChartTypeToggle
  - Pass viewModel.availableTimeRanges
  - Call viewModel.switchTimeRange(to:) on selection
  - Show loading indicator during range switch

- [ ] T036 [US3] Implement chart data caching in CoinDetailViewModel in `Bitpal/Features/CoinDetail/ViewModels/CoinDetailViewModel.swift`
  - loadFromCache(range:) method
  - saveToCache(lineData:range:) / saveToCache(candleData:range:) methods
  - Check cache before API fetch
  - Handle cache expiration per time range TTL

**Checkpoint**: User Story 3 complete - Can switch time ranges, options match chart type, caching works

---

## Phase 6: User Story 4 - Inspect Specific Price Points (Priority: P4)

**Goal**: Touch interaction to see exact price and date at any point

**Independent Test**: Touch and drag on chart, tooltip shows exact price/date, lifts to return to current

### Implementation for User Story 4

- [ ] T037 [P] [US4] Create PriceTooltip component in `Bitpal/Design/Components/ChartComponents/PriceTooltip.swift`
  - Display date and price at selected point
  - Formatters.formatPrice() for price
  - Date formatting for timestamp
  - Slide-in animation from top

- [ ] T038 [US4] Add touch interaction to LineChartView in `Bitpal/Features/CoinDetail/Views/LineChartView.swift`
  - .chartOverlay with GeometryReader
  - DragGesture for touch tracking
  - proxy.value(atX:) to get date at position
  - Find closest data point to touched position
  - Binding for selectedPoint: (date: Date, price: Decimal)?
  - PointMark highlight at selected point

- [ ] T039 [US4] Add touch interaction to CandlestickChartView in `Bitpal/Features/CoinDetail/Views/CandlestickChartView.swift`
  - Same .chartOverlay pattern as LineChartView
  - Find closest candle to touched position
  - Highlight selected candle with PointMark
  - Return OHLC data for tooltip

- [ ] T040 [US4] Update PriceChartView for tooltip display in `Bitpal/Features/CoinDetail/Views/PriceChartView.swift`
  - Add selectedDataPoint state binding
  - Display PriceTooltip when selectedDataPoint != nil
  - Clear selection on touch end

- [ ] T041 [US4] Update CoinDetailViewModel for selection state in `Bitpal/Features/CoinDetail/ViewModels/CoinDetailViewModel.swift`
  - Add selectedDataPoint: (date: Date, price: Decimal)? state
  - Clear selection method

**Checkpoint**: User Story 4 complete - Touch shows tooltip, 60fps smooth interaction

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, performance optimization

- [ ] T042 [P] Handle limited history edge case in CoinDetailViewModel
  - Detect when coin has less history than requested range
  - Disable unavailable time ranges or show "Limited data" message
  - Test with newly listed coins

- [ ] T043 [P] Handle API failure with cached fallback in CoinDetailViewModel
  - Show cached data when API fails
  - Display "Showing cached data" indicator with timestamp
  - Retry button for manual refresh

- [ ] T044 [P] Handle zero price change edge case in chart views
  - Use neutral color (not green/red) when change is exactly 0%
  - Update ChartStatistics.isPositive logic

- [ ] T045 [P] Add accessibility labels to chart components
  - TimeRangeSelector: accessibilityLabel per range
  - ChartTypeToggle: accessibilityLabel per type
  - PriceTooltip: announce price and date

- [ ] T046 Performance optimization: data point limiting
  - Implement downsampling in ViewModel.filterAndLimitData()
  - Ensure max ~100 points per view
  - Verify 60fps with Instruments

- [ ] T047 [P] Create CoinDetailViewModelTests in `BitpalTests/CoinDetailTests/CoinDetailViewModelTests.swift`
  - Test loadInitialData() success/failure
  - Test time range switching
  - Test chart type switching with preference
  - Test cache save/load

- [ ] T048 Run quickstart.md validation and manual testing
  - Test all 4 user stories end-to-end
  - Verify 60fps chart interactions
  - Test offline mode with cached data
  - Test pull-to-refresh

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in priority order (P1 → P2 → P3 → P4)
  - Some tasks within stories can parallelize (marked [P])
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Depends on US1 (needs base chart infrastructure)
- **User Story 3 (P3)**: Depends on US1 and US2 (builds on both chart types)
- **User Story 4 (P4)**: Depends on US1, US2, US3 (needs full chart implementation)

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before views
- Core views before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks T004-T005 can run in parallel
- All model creation tasks T008-T012, T014-T016 can run in parallel
- Within US1: T019-T022 can run in parallel (different files)
- Within US2: T028-T030 can run in parallel
- All Polish tasks marked [P] can run in parallel

---

## Parallel Example: Foundational Phase

```bash
# Launch all model tasks together:
Task: "Create ChartDataPoint model in Bitpal/Features/CoinDetail/Models/ChartDataPoint.swift"
Task: "Create CandleDataPoint model in Bitpal/Features/CoinDetail/Models/CandleDataPoint.swift"
Task: "Create ChartTimeRange enum in Bitpal/Features/CoinDetail/Models/ChartTimeRange.swift"
Task: "Create ChartType enum in Bitpal/Features/CoinDetail/Models/ChartType.swift"
Task: "Create ChartStatistics struct in Bitpal/Features/CoinDetail/Models/ChartStatistics.swift"
```

## Parallel Example: User Story 1

```bash
# Launch view tasks together (after ViewModel):
Task: "Create CoinHeaderView in Bitpal/Features/CoinDetail/Views/CoinHeaderView.swift"
Task: "Create MarketStatsView in Bitpal/Features/CoinDetail/Views/MarketStatsView.swift"
Task: "Create ChartStatsBar in Bitpal/Design/Components/ChartComponents/ChartStatsBar.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test coin detail with 1D line chart
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo (chart types)
4. Add User Story 3 → Test independently → Deploy/Demo (time ranges)
5. Add User Story 4 → Test independently → Deploy/Demo (touch interaction)
6. Polish phase → Final release

### Story Test Criteria

| Story | Independent Test |
|-------|-----------------|
| US1 | Navigate to coin, view 1D line chart with stats |
| US2 | Toggle Line ↔ Candle, preference persists |
| US3 | Switch time ranges, see correct options per type |
| US4 | Touch chart, see price/date tooltip |

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tasks | 48 |
| Phase 1 (Setup) | 5 |
| Phase 2 (Foundational) | 13 |
| Phase 3 (US1 - MVP) | 9 |
| Phase 4 (US2) | 5 |
| Phase 5 (US3) | 4 |
| Phase 6 (US4) | 5 |
| Phase 7 (Polish) | 7 |
| Parallel Opportunities | 25 tasks marked [P] |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Use Xcode Instruments to verify 60fps before marking US4 complete
