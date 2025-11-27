# Research: iOS Home Screen Widgets for Portfolio

**Feature**: 004-portfolio-widgets
**Date**: 2025-11-26

## Overview

This document consolidates research findings for implementing WidgetKit-based home screen widgets for the Bitpal portfolio app.

---

## 1. WidgetKit Architecture

### Decision: Use WidgetKit with TimelineProvider

**Rationale**: WidgetKit is Apple's official framework for iOS widgets. It provides:
- System-managed refresh scheduling
- Memory-efficient rendering
- Deep linking support
- Automatic Dark Mode handling

**Alternatives Considered**:
- ❌ Live Activities: Out of scope for Phase 2
- ❌ ClockKit complications: watchOS only

### Timeline Provider Pattern

```text
TimelineProvider
    ├── placeholder(in:) → Static preview entry
    ├── getSnapshot(in:completion:) → Quick preview for gallery
    └── getTimeline(in:completion:) → Array of entries with refresh policy
```

**Refresh Policy**: `.after(Date().addingTimeInterval(30 * 60))` - 30-minute refresh per constitution.

---

## 2. App Groups Data Sharing

### Decision: Use App Groups with Swift Data

**Rationale**: App Groups is the only supported mechanism for sharing data between app and widget extension. Swift Data can use a shared container.

**Implementation**:
1. Create App Group identifier: `group.com.bitpal.shared`
2. Enable App Groups capability in both app and widget targets
3. Configure Swift Data container to use shared URL

**Key Code Pattern**:
```swift
// Shared container URL
let containerURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.com.bitpal.shared")!

// Configure Swift Data for App Group
let modelConfiguration = ModelConfiguration(
    url: containerURL.appendingPathComponent("BitpalShared.sqlite")
)
```

**Alternatives Considered**:
- ❌ UserDefaults(suiteName:): Limited to 1MB, not suitable for portfolio data
- ❌ File-based sharing: More complex than Swift Data

---

## 3. Widget Data Structure

### Decision: Create Lightweight WidgetPortfolioData

**Rationale**: Widget extension has 30MB memory limit. Full Transaction and Holding models include unnecessary data. Create a simplified structure optimized for widget display.

**Structure**:
```swift
struct WidgetPortfolioData: Codable {
    let totalValue: Decimal
    let unrealizedPnL: Decimal
    let realizedPnL: Decimal
    let totalPnL: Decimal
    let holdings: [WidgetHolding]  // Top 5 max
    let lastUpdated: Date
}

struct WidgetHolding: Codable, Identifiable {
    let id: String  // coinId
    let symbol: String
    let name: String
    let currentValue: Decimal
    let pnlAmount: Decimal
    let pnlPercentage: Decimal
}
```

**Alternatives Considered**:
- ❌ Reuse full Holding model: Too much memory overhead
- ❌ Store only IDs and fetch: Widgets can't make network calls during render

---

## 4. Calculation Consistency

### Decision: Extract Shared Calculation Module

**Rationale**: Per FR-007, widget P&L calculations MUST match main app exactly. Extract calculation logic to shared module accessible by both targets.

**Functions to Extract**:
- `computeHoldings(transactions:currentPrices:)` - Already exists
- `computePortfolioSummary(holdings:closedPositions:)` - Already exists
- New: `prepareWidgetData(summary:holdings:)` - Transform to widget format

**Implementation**:
- Create `Shared/Calculations/` directory
- Move calculation functions to shared module
- Both app and widget import shared module

**Alternatives Considered**:
- ❌ Duplicate calculations in widget: Violates FR-007, high bug risk

---

## 5. Offline/Cache Strategy

### Decision: Always Show Cached Data

**Rationale**: Per FR-015, blank widgets are FORBIDDEN. Widget must always display last known data even if stale.

**Implementation**:
1. Main app writes `WidgetPortfolioData` to App Group on every portfolio update
2. Widget reads cached data during timeline generation
3. If cache is empty (new install), show empty state with "Add holdings" message
4. Include `lastUpdated` timestamp for staleness indication

**Cache Invalidation**:
- Main app calls `WidgetCenter.shared.reloadAllTimelines()` after:
  - Transaction added/edited/deleted
  - Price refresh completed

**Alternatives Considered**:
- ❌ Widget fetches from API: WidgetKit discourages network calls in timeline
- ❌ Background app refresh: Not reliable enough for widget data

---

## 6. Deep Linking

### Decision: URL Scheme with Portfolio Tab

**Rationale**: Per FR-010, all widgets must deep link to Portfolio tab when tapped.

**Implementation**:
```swift
// Widget link
Link(destination: URL(string: "bitpal://portfolio")!) {
    WidgetContent()
}

// App URL handling
.onOpenURL { url in
    if url.scheme == "bitpal" && url.host == "portfolio" {
        selectedTab = .portfolio
    }
}
```

**URL Scheme**: `bitpal://portfolio`

**Alternatives Considered**:
- ❌ Universal Links: Overkill for internal navigation
- ❌ App Intents: Better suited for interactive widgets (Phase 3+)

---

## 7. Widget Sizes and Layout

### Decision: Three Standard Sizes with Responsive Layout

**Rationale**: Per FR-001, FR-002, FR-003, support systemSmall, systemMedium, systemLarge.

**Layout Strategy**:

| Size | Dimensions (approx) | Content |
|------|---------------------|---------|
| Small | 169×169 pt | Total value, Total P&L, Timestamp |
| Medium | 360×169 pt | Total value, Unrealized/Realized P&L, Top 2 holdings |
| Large | 360×376 pt | Total value, All P&L types, Top 5 holdings |

**Adaptive Layout**:
- Use `@Environment(\.widgetFamily)` to switch layouts
- Use `ViewThatFits` for text truncation
- Use system fonts with Dynamic Type support

**Alternatives Considered**:
- ❌ Single adaptive view: Too complex, harder to maintain
- ❌ Extra large widgets: Out of scope for Phase 2

---

## 8. Memory Optimization

### Decision: Minimal Memory Footprint

**Rationale**: Per FR-008, widget extension must stay under 30MB.

**Strategies**:
1. **Lightweight data structures**: WidgetHolding instead of full Holding
2. **No images**: Use SF Symbols only for icons
3. **Lazy loading**: Read from cache only when needed
4. **Limited entries**: Generate only 2 timeline entries (current + next refresh)

**Validation**:
- Use Xcode Memory Debugger during development
- Add memory test to verify <30MB

---

## 9. Testing Strategy

### Decision: Unit Tests for Data Provider

**Rationale**: Per constitution Testing Strategy, widget data provider and shared calculations require tests.

**Test Coverage**:
1. `WidgetDataProviderTests`:
   - Test data transformation from portfolio to widget format
   - Test empty state handling
   - Test top N holdings selection
2. `PortfolioEntryTests`:
   - Test timeline entry creation
   - Test refresh policy generation
3. Manual testing:
   - Visual appearance in all sizes
   - Dark/Light mode
   - Empty state
   - Deep linking

**Alternatives Considered**:
- ❌ Snapshot testing: Not critical for Phase 2 MVP
- ❌ UI tests for widget: WidgetKit doesn't support XCUITest

---

## Summary of Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| Framework | WidgetKit | Apple standard, memory efficient |
| Data Sharing | App Groups + Swift Data | Only supported mechanism |
| Data Structure | Lightweight WidgetPortfolioData | 30MB memory limit |
| Calculations | Shared module | FR-007 consistency requirement |
| Offline | Always show cached | FR-015 no blank widgets |
| Deep Linking | URL scheme (bitpal://) | Simple, effective |
| Sizes | Small/Medium/Large | FR-001, FR-002, FR-003 |
| Testing | Unit tests for provider | Constitution testing strategy |

---

## Open Items

None - all NEEDS CLARIFICATION items resolved.
