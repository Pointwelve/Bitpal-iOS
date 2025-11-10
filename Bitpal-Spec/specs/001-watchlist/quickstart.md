# Quickstart: Watchlist Feature

**Feature**: 001-watchlist
**Date**: 2025-11-08
**Audience**: Developers implementing and testing the Watchlist feature

## Overview

This guide provides step-by-step instructions for building, running, and testing the Watchlist feature. Follow this guide to validate the implementation meets all Constitution principles and success criteria.

---

## Prerequisites

### Required

- **Xcode 17+** (for iOS 26 SDK)
- **macOS 15+** (Sequoia or later)
- **Physical device or simulator** running iOS 26+
- **Internet connection** (for CoinGecko API)

### Recommended

- **iPhone 13 or newer** (for 60fps performance validation)
- **Xcode Instruments** (for performance profiling)

---

## Build and Run

### 1. Open Project

```bash
cd /path/to/Bitpal-iOS
open Bitpal.xcodeproj
```

### 2. Select Target

- **Scheme**: Bitpal
- **Destination**: iPhone 16 Simulator (or your preferred iOS 26+ simulator)

### 3. Build Project

**Via Xcode**:
- Press `⌘B` to build

**Via Command Line**:
```bash
xcodebuild -project Bitpal.xcodeproj \
           -scheme Bitpal \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build
```

**Expected output**:
```
** BUILD SUCCEEDED **
```

### 4. Run on Simulator

**Via Xcode**:
- Press `⌘R` to run

**Via Command Line**:
```bash
xcodebuild -project Bitpal.xcodeproj \
           -scheme Bitpal \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           run
```

**Expected behavior**:
- App launches to Watchlist tab (default view)
- Empty state message shown: "Your watchlist is empty. Tap + to add cryptocurrencies."

---

## Manual Testing Checklist

### User Story 1: View and Monitor Watchlist (P1)

**Prerequisites**: Add 3+ coins to watchlist first (via User Story 2 flow)

- [ ] **US1.1**: Open Watchlist tab → See list of added coins with names, symbols, prices, 24h changes
- [ ] **US1.2**: Observe prices → Color coded (green for positive, red for negative) 24h changes displayed
- [ ] **US1.3**: Wait 30 seconds → Prices auto-update without UI jank or freezing
- [ ] **US1.4**: Pull down on list → Pull-to-refresh triggers, loading indicator shows, prices refresh
- [ ] **US1.5**: Scroll through 50+ coins → Scrolling is smooth (visually 60fps, no lag)
- [ ] **US1.6**: Rotate device → Layout adapts correctly, prices still visible

**Success Criteria**:
- ✅ List displays without delay (<500ms load time)
- ✅ Colors match price direction (green = up, red = down)
- ✅ Auto-updates don't cause UI stutter
- ✅ Pull-to-refresh completes in <2 seconds
- ✅ Scrolling feels buttery smooth (60fps)

---

### User Story 2: Search and Add Cryptocurrencies (P2)

- [ ] **US2.1**: Tap "+" button → Search sheet appears with search field
- [ ] **US2.2**: Type "bit" → See results (Bitcoin, Bitcoin Cash, etc.) within 1 second
- [ ] **US2.3**: Tap "Bitcoin" → Sheet dismisses, Bitcoin appears in watchlist immediately
- [ ] **US2.4**: Try to add Bitcoin again → Error message "Bitcoin is already in your watchlist"
- [ ] **US2.5**: Search for "ethereum" → Ethereum appears in results
- [ ] **US2.6**: Tap Ethereum → Added successfully to watchlist
- [ ] **US2.7**: Search for nonsense "xyzabc123" → "No results" message shown
- [ ] **US2.8**: Dismiss sheet without selecting → Watchlist unchanged

**Success Criteria**:
- ✅ Search returns results in <1 second (FR-001)
- ✅ Duplicate detection works (FR-012)
- ✅ Add workflow completes in <5 seconds (SC-001)
- ✅ Search is responsive during typing (no lag)

---

### User Story 3: Sort and Organize Watchlist (P3)

**Prerequisites**: Have 5+ coins in watchlist with varying prices/changes

- [ ] **US3.1**: Tap "Sort" picker → Options appear (Name, Price, 24h Change)
- [ ] **US3.2**: Select "Name (A-Z)" → List sorts alphabetically by coin name
- [ ] **US3.3**: Select "Price (High-Low)" → List sorts by current price (highest first)
- [ ] **US3.4**: Select "24h Change (Best-Worst)" → List sorts by % change (best gainers first)
- [ ] **US3.5**: While sorted by Price, wait for price update → List re-sorts automatically
- [ ] **US3.6**: Switch between sort options rapidly → No crashes, smooth transitions

**Success Criteria**:
- ✅ Sorting completes instantly (<100ms)
- ✅ List maintains sort order during updates
- ✅ Sort animations are smooth (Constitution Principle II)

---

### User Story 4: Remove Coins from Watchlist (P4)

- [ ] **US4.1**: Swipe left on a coin row → Red "Delete" button appears
- [ ] **US4.2**: Tap "Delete" → Coin removed with smooth fade-out animation
- [ ] **US4.3**: Remove all coins → Empty state message appears
- [ ] **US4.4**: Add coin back after removing → Works correctly
- [ ] **US4.5**: Swipe left but tap outside → Delete button dismissed, coin not removed

**Success Criteria**:
- ✅ Swipe gesture is responsive
- ✅ Delete animation is smooth (Constitution Principle II)
- ✅ Empty state displays correctly

---

## Edge Cases Testing

### Network Scenarios

**Test: Offline Mode**
```bash
# Turn off network on simulator
# Open Watchlist
```
- [ ] Shows cached prices
- [ ] Displays "Offline - showing last known prices" indicator
- [ ] Pull-to-refresh shows error message
- [ ] No crashes

**Test: Slow Network**
```bash
# In Xcode: Debug → Network Link Conditioner → 3G
```
- [ ] Search still responds within 1 second (uses cached coin list)
- [ ] Price updates may be slow but UI not blocked
- [ ] Loading indicators shown appropriately

**Test: API Rate Limit**
```bash
# Rapidly refresh 50+ times
```
- [ ] App shows last cached data
- [ ] Error message displayed (not crash)
- [ ] Automatic retry with backoff

### Data Scenarios

**Test: Empty Watchlist**
- [ ] Empty state message displayed
- [ ] "+" button clearly visible
- [ ] No crashes or blank screens

**Test: 100+ Coins**
```bash
# Add 100 coins to watchlist
```
- [ ] Scrolling still smooth (60fps)
- [ ] Memory usage <100MB (verify in Xcode Debug Navigator)
- [ ] Batch API request works (all coins fetched at once)

**Test: Invalid Coin Data**
```bash
# Manually add WatchlistItem with fake coinId in Swift Data
```
- [ ] App handles gracefully (skips invalid coin)
- [ ] No crashes
- [ ] Other coins display correctly

---

## Performance Validation (REQUIRED per Constitution)

### 60fps Scrolling Validation

**Steps**:
1. Add 50+ coins to watchlist
2. Open Xcode Instruments → Time Profiler
3. Start recording
4. Scroll through entire list rapidly
5. Stop recording
6. Analyze results

**Success Criteria** (Constitution Principle I):
- ✅ Frame rate stays at 60fps (16.67ms per frame max)
- ✅ No dropped frames during scrolling
- ✅ Main thread CPU usage <80%

**Command Line Profiling**:
```bash
instruments -t "Time Profiler" \
            -D /tmp/watchlist-profile.trace \
            -w "iPhone 16" \
            Bitpal.app
```

### Memory Usage Validation

**Steps**:
1. Open Xcode Debug Navigator (⌘6)
2. Add 100 coins to watchlist
3. Monitor memory usage

**Success Criteria** (plan.md constraints):
- ✅ Memory usage <100MB with 100 coins
- ✅ No memory leaks (use Instruments → Leaks)

---

## API Testing

### Test CoinGecko Integration

**Test: Coin List Endpoint**
```bash
curl "https://api.coingecko.com/api/v3/coins/list" | jq '.[0:5]'
```

**Expected Output**:
```json
[
  {"id": "bitcoin", "symbol": "btc", "name": "Bitcoin"},
  {"id": "ethereum", "symbol": "eth", "name": "Ethereum"},
  ...
]
```

**Test: Market Data Endpoint**
```bash
curl "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum&price_change_percentage=24h" | jq
```

**Expected Output**:
```json
[
  {
    "id": "bitcoin",
    "current_price": 45000.50,
    "price_change_percentage_24h": 2.5,
    ...
  }
]
```

### Rate Limit Testing

**Test: Respect Rate Limits**
```bash
# In app code, enable debug logging for RateLimiter
# Trigger rapid refreshes (50+ times)
# Check logs show 1.2s minimum interval between requests
```

---

## Unit Tests (REQUIRED per Constitution)

### Run All Tests

**Via Xcode**:
- Press `⌘U` to run all tests

**Via Command Line**:
```bash
xcodebuild test \
           -project Bitpal.xcodeproj \
           -scheme Bitpal \
           -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Required Test Coverage

Per Constitution Principle IV, the following tests are **REQUIRED**:

**1. API Response Parsing** (`CoinGeckoServiceTests.swift`)
- [ ] Test valid JSON parsing
- [ ] Test invalid JSON handling
- [ ] Test missing fields handling
- [ ] Test Decimal conversion accuracy

**2. Price Update Logic** (`PriceUpdateTests.swift`)
- [ ] Test 30-second interval enforced
- [ ] Test cancellation works
- [ ] Test error handling and retry

**Example Test**:
```swift
import XCTest
@testable import Bitpal

final class CoinGeckoServiceTests: XCTestCase {
    func testMarketDataParsing() async throws {
        let json = """
        [
          {
            "id": "bitcoin",
            "symbol": "btc",
            "name": "Bitcoin",
            "current_price": 45000.50,
            "price_change_percentage_24h": 2.5,
            "last_updated": "2025-01-15T10:30:00.000Z"
          }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let coins = try decoder.decode([Coin].self, from: json)

        XCTAssertEqual(coins.count, 1)
        XCTAssertEqual(coins[0].id, "bitcoin")
        XCTAssertEqual(coins[0].currentPrice, Decimal(45000.50))
        XCTAssertEqual(coins[0].priceChange24h, Decimal(2.5))
    }
}
```

---

## Design Validation (Constitution Principle II)

### Liquid Glass Design Checklist

- [ ] **Translucent materials**: Coin rows use `.ultraThinMaterial` background
- [ ] **Rounded corners**: Cards have 12-16pt corner radius
- [ ] **System colors**: Price changes use `.green` and `.red`
- [ ] **Dynamic Type**: Text scales correctly (test in Settings → Accessibility)
- [ ] **Spring animations**: Add/delete animations use `spring(response: 0.3, dampingFraction: 0.7)`
- [ ] **Minimum tap targets**: All buttons >44x44pt (verify in Accessibility Inspector)
- [ ] **Spacing**: Consistent 12pt spacing between cards

**Visual Validation**:
1. Compare against CLAUDE.md mockup (lines 1155-1175)
2. Verify against iOS 26 HIG guidelines
3. Test in both Light and Dark modes

---

## Troubleshooting

### Build Errors

**Error**: `Module 'SwiftData' not found`
- **Fix**: Ensure Xcode 17+ and iOS 26+ SDK installed

**Error**: `Cannot find 'Decimal' in scope`
- **Fix**: `import Foundation` in file

### Runtime Errors

**Error**: App crashes on launch
- **Check**: Swift Data model container configured in BitpalApp.swift
- **Check**: No force unwrapping (`!`) in production code

**Error**: Prices not updating
- **Check**: Network connection available
- **Check**: PriceUpdateService started in WatchlistViewModel
- **Check**: Logs show API requests happening

### Performance Issues

**Problem**: Scrolling is laggy
- **Check**: Using LazyVStack (not VStack)
- **Check**: CoinRowView conforms to Equatable
- **Check**: No heavy computation in view body
- **Profile**: Use Instruments Time Profiler to identify bottlenecks

---

## Success Criteria Validation

Before marking Watchlist as complete, verify ALL success criteria from spec.md:

- [ ] **SC-001**: Search + add workflow <5 seconds ✓
- [ ] **SC-002**: 60fps scrolling validated with Instruments ✓
- [ ] **SC-003**: Price updates every 30s without blocking (validated in logs) ✓
- [ ] **SC-004**: Search returns results in <1 second ✓
- [ ] **SC-005**: App responsive during API failures (cached data shown) ✓
- [ ] **SC-006**: Zero crashes during 1-hour stress test ✓
- [ ] **SC-007**: Liquid Glass design passes visual review ✓
- [ ] **SC-008**: Color-coded price changes clearly visible ✓
- [ ] **SC-009**: <50 API requests per hour per user (validated in logs) ✓
- [ ] **SC-010**: Memory <100MB with 100 coins (validated in Xcode) ✓

---

## Next Steps

After Watchlist feature is complete and validated:

1. **Generate tasks.md**: Run `/speckit.tasks` to create implementation task list
2. **Begin implementation**: Follow tasks.md and Constitution principles
3. **Continuous validation**: Re-run this quickstart guide after each milestone
4. **Performance monitoring**: Regular profiling with Instruments

---

**Last Updated**: 2025-11-08
**Status**: Ready for implementation
