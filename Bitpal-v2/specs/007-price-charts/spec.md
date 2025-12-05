# Feature Specification: Per-Coin Price Charts

**Feature Branch**: `007-price-charts`
**Created**: 2025-12-01
**Status**: Draft
**Input**: User description: "Per-coin price charts with 15M, 1H, 4H, 1D, 1W, 1M, 1Y time ranges for cryptocurrency price history visualization"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Recent Price Movement (Priority: P1)

A user wants to quickly check how a coin's price has moved today to understand current market sentiment before making decisions.

**Why this priority**: Most common use case - users check daily price movement frequently to gauge short-term trends and validate their holdings.

**Independent Test**: Navigate to any coin in watchlist or portfolio, view the 1D chart displaying price movement over the last 24 hours with clear high/low indicators.

**Acceptance Scenarios**:

1. **Given** a user is viewing a coin detail screen, **When** they see the price chart, **Then** the 1D (24-hour) view is displayed by default as a line chart showing price movement over time.
2. **Given** a user is viewing a 1D chart, **When** prices have changed, **Then** the chart shows the current price, 24h high, and 24h low clearly visible.
3. **Given** a user is viewing a chart, **When** the price is up for the selected period, **Then** the chart uses green coloring; when down, uses red coloring.

---

### User Story 2 - Switch Chart Types (Priority: P2)

A user wants to toggle between line chart and candlestick chart to choose the visualization that best suits their analysis style.

**Why this priority**: Different users have different needs - casual users prefer simple line charts while traders need candlestick charts for OHLC (Open/High/Low/Close) analysis.

**Independent Test**: On any coin's chart, tap the chart type toggle and verify the display switches between line and candlestick views.

**Acceptance Scenarios**:

1. **Given** a user is viewing a chart, **When** they see the chart type toggle, **Then** they can switch between "Line" and "Candle" views.
2. **Given** a user selects "Line" chart, **When** the chart renders, **Then** it displays a continuous line showing price over time.
3. **Given** a user selects "Candle" chart, **When** the chart renders, **Then** it displays candlesticks showing Open, High, Low, Close for each time interval.
4. **Given** a user is viewing candlesticks, **When** a candle closes higher than it opened, **Then** the candle is green; when it closes lower, the candle is red.
5. **Given** a user switches chart types, **When** the new view loads, **Then** their preference is remembered for future sessions.

---

### User Story 3 - Analyze Different Time Ranges (Priority: P3)

A user wants to switch between different time periods to understand both short-term volatility and long-term trends for investment analysis.

**Why this priority**: Essential for informed decision-making - traders using candlestick charts need granular views (15M, 4H) for short-term analysis, while casual users on line charts need broader views (1H, 1D, 1W, 1M, 1Y).

**Independent Test**: On any coin's chart, verify the available time ranges match the chart type (Line: 5 options, Candle: 7 options) and chart updates correctly when switching.

**Acceptance Scenarios**:

1. **Given** a user is viewing a Line chart, **When** they see time range options, **Then** they see 5 options: 1H, 1D, 1W, 1M, 1Y.
2. **Given** a user is viewing a Candlestick chart, **When** they see time range options, **Then** they see 7 options: 15M, 1H, 4H, 1D, 1W, 1M, 1Y.
3. **Given** a user taps any time range, **When** the chart updates, **Then** it displays data for the selected period.
4. **Given** a user switches time ranges, **When** the new data loads, **Then** the transition is smooth and the selected time range button is visually highlighted.
5. **Given** a user is viewing Candlestick at 15M, **When** they switch to Line chart, **Then** the time range automatically changes to 1H (closest available).

---

### User Story 4 - Inspect Specific Price Points (Priority: P4)

A user wants to see the exact price at a specific point in time to understand historical values at key moments.

**Why this priority**: Adds depth to analysis - while the overall trend is visible in P1/P2, users sometimes need precise values for specific dates (e.g., "What was BTC worth on my birthday?").

**Independent Test**: Touch and hold on the chart to reveal a price indicator showing the exact price and date at that point.

**Acceptance Scenarios**:

1. **Given** a user is viewing a chart, **When** they touch and drag along the chart, **Then** a tooltip/indicator shows the exact price and date at the touch point.
2. **Given** a user is inspecting the chart, **When** they lift their finger, **Then** the chart returns to showing current/latest price.
3. **Given** a user is dragging on the chart, **When** they move smoothly, **Then** the price indicator updates fluidly without lag (60fps).

---

### Edge Cases

- What happens when historical data is unavailable for a newly listed coin? Display available data with a message indicating limited history.
- How does the system handle API failures when loading chart data? Show cached data if available, otherwise display a "Could not load chart" message with retry option.
- What happens when a coin has less than 1 year of history? Disable the 1Y option or show all available history with a note.
- How does the chart display when price change is exactly 0%? Use neutral color (not green or red).

### Phase Scope Validation

**Feature Category** (check one):
- [ ] Watchlist feature (explicitly in Phase 1)
- [ ] Manual Portfolio feature (explicitly in Phase 1)
- [x] **Phase 3 Visual Intelligence feature** - Price charts per coin (1D, 1W, 1M, 1Y)

**Constitution Reference**: Per constitution v3.0.0, Phase 3 (Visual Intelligence) is 🔵 ACTIVE and includes "Price charts per coin (1D, 1W, 1M, 1Y)" in scope.

## Requirements *(mandatory)*

### Functional Requirements

**Navigation & Screen**
- **FR-001**: System MUST provide a new dedicated coin detail screen accessible by tapping any coin in watchlist or portfolio.
- **FR-002**: Coin detail screen MUST display the price chart as the primary focus element.
- **FR-003**: Coin detail screen MUST display a header section with coin name, symbol, logo, current price, and 24h price change.
- **FR-004**: Coin detail screen MUST display market statistics: market cap, 24h trading volume, and circulating supply.

**Chart Display**
- **FR-005**: System MUST display a price chart for any cryptocurrency on the coin detail screen.
- **FR-006**: System MUST display the 1D time range by default when a chart is first viewed.
- **FR-007**: System MUST display the price change (amount and percentage) for the selected time range.
- **FR-008**: System MUST show the period high and low prices for the selected time range.

**Chart Types**
- **FR-009**: System MUST support two chart types: Line chart and Candlestick chart.
- **FR-010**: System MUST display Line chart by default for new users.
- **FR-011**: System MUST allow users to toggle between Line and Candlestick chart types.
- **FR-012**: Line chart MUST support 5 time ranges: 1H, 1D, 1W, 1M, 1Y.
- **FR-013**: Candlestick chart MUST support 7 time ranges: 15M, 1H, 4H, 1D, 1W, 1M, 1Y.
- **FR-014**: Line chart MUST display a continuous line showing closing prices over time.
- **FR-015**: Candlestick chart MUST display OHLC (Open, High, Low, Close) data for each time interval.
- **FR-016**: System MUST color candlesticks green when close > open, red when close < open.
- **FR-017**: System MUST persist user's chart type preference across sessions.
- **FR-018**: When switching chart types, system MUST switch to closest available time range if current range is unavailable.

**Interactions**
- **FR-019**: System MUST allow users to switch between time ranges with immediate visual feedback.
- **FR-020**: System MUST support touch interaction to inspect specific price points on the chart.
- **FR-021**: System MUST display the exact price and date when user touches a point on the chart (line) or candle (candlestick).
- **FR-022**: System MUST refresh chart data when user performs pull-to-refresh gesture.

**Performance & Design**
- **FR-023**: System MUST cache chart data to enable offline viewing of previously loaded charts.
- **FR-024**: System MUST display a loading indicator while fetching chart data.
- **FR-025**: System MUST handle missing historical data gracefully with appropriate messaging.
- **FR-026**: Charts MUST render smoothly at 60fps during interactions (per Constitution Principle I).
- **FR-027**: System MUST follow Liquid Glass design language (per Constitution Principle II).
- **FR-028**: Chart colors MUST use green for positive movement and red for negative movement.

### Key Entities

- **CoinDetail**: Aggregate view of coin information including name, symbol, logo URL, current price, 24h change, market cap, volume, circulating supply.
- **ChartDataPoint**: Represents a single price point with timestamp and closing price (for line chart).
- **CandleDataPoint**: Represents OHLC data with timestamp, open, high, low, close prices (for candlestick chart).
- **ChartTimeRange**: Enumeration of available time ranges (15M, 1H, 4H, 1D, 1W, 1M, 1Y) with associated data granularity.
- **ChartType**: Enumeration of chart display types (Line, Candlestick).
- **PriceChart**: Collection of chart data points for a specific coin and time range, including metadata (period high, period low, price change).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Chart renders and displays data within 2 seconds of navigation (cached) or 3 seconds (network fetch).
- **SC-002**: Touch interaction on chart updates price indicator at 60fps with no perceptible lag.
- **SC-003**: Users can switch between all 7 time ranges within a single viewing session.
- **SC-004**: Chart displays accurate price data matching the source data provider.
- **SC-005**: Previously viewed charts are available offline using cached data.
- **SC-006**: 90% of users can successfully view and interact with price charts on first attempt.
- **SC-007**: Chart animations and transitions complete within 300ms.

## Assumptions

- CoinGecko API (or equivalent) provides historical OHLC data for candlestick charts and price data for line charts.

**Line Chart Time Ranges** (5 options):
| Range | Data Points | Granularity |
|-------|-------------|-------------|
| 1H | ~12 | 5-minute* |
| 1D | ~96 | 15-minute |
| 1W | ~42 | 4-hour |
| 1M | ~30 | Daily |
| 1Y | ~52 | Weekly |

*See Known Limitations - CoinGecko free tier constraint

**Candlestick Chart Time Ranges** (7 options):
| Range | Candles | Interval |
|-------|---------|----------|
| 15M | ~15 | 1-minute |
| 1H | ~60 | 1-minute |
| 4H | ~48 | 5-minute |
| 1D | ~24 | 1-hour |
| 1W | ~42 | 4-hour |
| 1M | ~30 | 1-day |
| 1Y | ~52 | 1-week |

- Chart data will be cached locally with a reasonable TTL:
  - Short-term (15M, 1H, 4H): 1 minute cache
  - Medium-term (1D): 5 minutes cache
  - Long-term (1W, 1M, 1Y): 1 hour cache
- User's chart type preference (Line/Candlestick) will be persisted locally.
- The chart will be displayed on a coin detail screen accessible from both Watchlist and Portfolio.

## Clarifications

### Session 2025-12-01

- Q: Does a coin detail screen exist or is this new? → A: Create new dedicated coin detail screen with chart as primary focus.
- Q: What content besides chart on coin detail screen? → A: Chart + coin header (name, symbol, logo, current price, 24h change) + market stats (market cap, volume, circulating supply).

## Dependencies

- CoinGecko API `/coins/{id}` endpoint for coin details (name, symbol, logo, market cap, volume, supply).
- CoinGecko API `/coins/{id}/market_chart` endpoint for line chart price data.
- CoinGecko API `/coins/{id}/ohlc` endpoint for candlestick OHLC data.
- Existing coin data models from Watchlist/Portfolio features.
- Navigation infrastructure to access coin detail screens.
- Local storage for persisting user's chart type preference.

## Known Limitations

**CoinGecko Free Tier Granularity:**
- 1-day API requests return ~5-minute intervals
- 1H time range displays ~12 data points (60 min ÷ 5 min intervals)
- This is an API limitation, not a bug - accepted as sufficient for trend visualization
