# Research: Widget Background Refresh

**Feature**: 008-widget-background-refresh
**Date**: 2025-12-11
**Purpose**: Resolve technical unknowns before implementation

## Research Questions

### Q1: Can Widget Extensions Make Network Requests?

**Decision**: Yes, widget extensions can make network requests in `getTimeline()`.

**Rationale**:
- WidgetKit allows async/await and URLSession requests within `getTimeline()`
- iOS provides a time budget of approximately 15-30 seconds for timeline generation
- Network requests should be performant (batched, minimal payload) to complete within budget
- If the request times out, the completion handler must still be called with cached data

**Alternatives Considered**:
- BGAppRefreshTask: More complex, requires separate entitlements and scheduling. Widget-side fetch is simpler and sufficient.
- Push notifications to trigger refresh: Over-engineered for this use case.

**Source**: Apple WidgetKit documentation, WWDC sessions on widgets.

---

### Q2: What's the Optimal Timeline Refresh Policy?

**Decision**: Use `.after(Date)` policy with 15-minute interval.

**Rationale**:
- Current implementation uses 2-hour window with multiple entries - creates illusion of refresh but same stale data
- Shorter interval (15 minutes) ensures fresher data
- Single entry per timeline (with fresh data) is cleaner than multiple entries with same data
- iOS may extend the interval based on battery/usage, but 15 minutes is a reasonable request

**Code Pattern**:
```swift
let refreshDate = Date().addingTimeInterval(15 * 60) // 15 minutes
let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
```

**Alternatives Considered**:
- `.atEnd`: Would refresh immediately after displaying, too aggressive
- `.never`: Requires manual reload, defeats purpose
- Multiple entries with same data: Current approach, creates false impression of refresh

---

### Q3: How to Handle API Failures Gracefully?

**Decision**: Fall back to cached WidgetPortfolioData, display staleness indicator at 60+ minutes.

**Rationale**:
- Constitution requires: "Always show cached data when API unavailable. Blank widgets are FORBIDDEN."
- Existing staleness indicator infrastructure already implemented (orange exclamation mark)
- Don't disrupt user experience for temporary network issues
- Schedule next refresh as normal (iOS will retry)

**Implementation Pattern**:
```swift
func getTimeline(...) {
    Task {
        // Try to fetch fresh data
        if let freshData = try? await fetchAndRecalculate() {
            // Use fresh data
            completion(Timeline(entries: [freshEntry], policy: .after(nextRefresh)))
        } else {
            // Fall back to cached data
            let cachedData = storage.readPortfolioData() ?? .empty
            completion(Timeline(entries: [cachedEntry], policy: .after(nextRefresh)))
        }
    }
}
```

---

### Q4: What Data Does Widget Need to Recalculate P&L?

**Decision**: Store coin IDs, quantities, and average costs in `WidgetRefreshData`.

**Rationale**:
- Current `WidgetPortfolioData` only stores computed values (total value, P&L amounts)
- Cannot recalculate with fresh prices without knowing quantities
- Average cost needed for accurate P&L calculation: `P&L = (currentPrice - avgCost) × quantity`
- Realized P&L doesn't change during refresh (no transactions in widget)

**Data Structure**:
```swift
struct WidgetRefreshData: Codable, Sendable {
    let holdings: [RefreshableHolding]
    let realizedPnL: Decimal  // Static, doesn't change

    struct RefreshableHolding: Codable, Sendable {
        let coinId: String      // For API request
        let symbol: String      // For display
        let name: String        // For display
        let quantity: Decimal   // For value calculation
        let avgCost: Decimal    // For P&L calculation
    }
}
```

---

### Q5: CoinGecko API Endpoint for Widget?

**Decision**: Use `/coins/markets` endpoint (same as main app).

**Rationale**:
- Supports batched requests: `?ids=bitcoin,ethereum,cardano`
- Returns current price, 24h change, and other metadata
- Already tested and working in main app's `CoinGeckoService`
- No API key required for free tier
- Rate limit: 50 calls/minute (widgets refresh every 15-30 min, well under limit)

**API Contract**:
```
GET https://api.coingecko.com/api/v3/coins/markets
    ?vs_currency=usd
    &ids=bitcoin,ethereum,cardano  (comma-separated)
    &price_change_percentage=24h
```

**Response** (simplified):
```json
[
  {
    "id": "bitcoin",
    "current_price": 45000.50,
    "price_change_percentage_24h": 2.5
  }
]
```

---

### Q6: Shared Code Between App and Widget?

**Decision**: Place shared models in `Bitpal/Shared/` directory, use separate API client in widget.

**Rationale**:
- `WidgetRefreshData` and `WidgetPortfolioData` must be accessible by both targets
- Existing `AppGroupStorage` already in `Shared/` - add refresh data methods
- Widget API client should be lightweight (no rate limiter, no caching needed)
- Main app's `CoinGeckoService` has dependencies unsuitable for widget (rate limiter state, cache)

**File Organization**:
```
Bitpal/Shared/           # Shared between app and widget
├── Models/
│   ├── WidgetPortfolioData.swift  # Existing
│   └── WidgetRefreshData.swift    # NEW
└── Services/
    └── AppGroupStorage.swift      # Existing, add methods

BitpalWidget/            # Widget extension only
└── Services/
    └── WidgetAPIClient.swift      # NEW, lightweight
```

---

## Summary of Decisions

| Topic | Decision |
|-------|----------|
| Network in widget | Yes, use URLSession async/await in getTimeline() |
| Refresh policy | `.after(15 minutes)` with single entry |
| Error handling | Fall back to cached data, never show blank |
| Data for recalc | WidgetRefreshData with quantities and avgCost |
| API endpoint | CoinGecko `/coins/markets` (batched) |
| Code sharing | Shared models in `Shared/`, separate widget API client |

## Unresolved Questions

None - all technical questions resolved.
