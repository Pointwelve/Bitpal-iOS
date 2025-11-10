# Feature Specification: Watchlist

**Feature Branch**: `001-watchlist`
**Created**: 2025-11-08
**Status**: Draft
**Input**: Watchlist feature for cryptocurrency price tracking

## User Scenarios & Testing

### User Story 1 - View and Monitor Watchlist (Priority: P1)

Users need a quick, at-a-glance view of their tracked cryptocurrencies with current prices and 24-hour changes. This is the core value proposition of the watchlist feature.

**Why this priority**: This is the MVP - without being able to view prices, the watchlist has no value. This must work perfectly before anything else.

**Independent Test**: Can be fully tested by adding sample data to Swift Data and verifying the list displays with smooth scrolling and accurate price data from CoinGecko API.

**Acceptance Scenarios**:

1. **Given** user has coins in their watchlist, **When** they open the Watchlist tab, **Then** they see a scrollable list of coins with names, symbols, current prices, and 24h price changes displayed with color coding (green for positive, red for negative).

2. **Given** the watchlist is displaying, **When** prices update from the API every 30 seconds, **Then** the UI updates smoothly without jank or blocking user interactions.

3. **Given** user has 50+ coins in watchlist, **When** they scroll through the list, **Then** scrolling maintains 60fps with no lag or stuttering.

4. **Given** user pulls down on the list, **When** they release (pull-to-refresh), **Then** prices refresh manually and display loading indicator.

---

### User Story 2 - Search and Add Cryptocurrencies (Priority: P2)

Users need to discover and add cryptocurrencies to their watchlist from CoinGecko's complete database.

**Why this priority**: Without this, users cannot populate their watchlist. It's P2 because we can test US1 with preloaded data, but this is essential for real usage.

**Independent Test**: Can be tested independently by implementing search functionality and verifying coins can be added to Swift Data. US1 does not need to be fully implemented to test search.

**Acceptance Scenarios**:

1. **Given** user is on Watchlist tab, **When** they tap the "+" Add Coin button, **Then** a search sheet appears with a search field.

2. **Given** search sheet is open, **When** user types "bit" into the search field, **Then** matching cryptocurrencies appear below (Bitcoin, Bitcoin Cash, etc.) within 1 second.

3. **Given** search results are displayed, **When** user taps on "Bitcoin", **Then** Bitcoin is added to their watchlist and the sheet dismisses.

4. **Given** user tries to add a coin already in watchlist, **When** they tap it in search, **Then** they see a message "Bitcoin is already in your watchlist" and the coin is not duplicated.

---

### User Story 3 - Sort and Organize Watchlist (Priority: P3)

Users want to view their watchlist sorted by different criteria (name, price, 24h change) to quickly find information.

**Why this priority**: Sorting enhances UX but is not critical for MVP. Users can still use the watchlist without sorting, just less efficiently.

**Independent Test**: Can be tested by adding multiple coins and verifying sort options reorder the list correctly. Does not depend on search (can use preloaded data).

**Acceptance Scenarios**:

1. **Given** user has multiple coins in watchlist, **When** they tap the "Sort" picker and select "Name (A-Z)", **Then** coins are sorted alphabetically by name.

2. **Given** watchlist is displayed, **When** user selects "Price (High-Low)" sort option, **Then** coins are sorted by current price in descending order.

3. **Given** watchlist is displayed, **When** user selects "24h Change (Best-Worst)" sort option, **Then** coins are sorted by 24h percentage change in descending order.

4. **Given** prices update via API, **When** the sort option is "Price (High-Low)", **Then** the list automatically re-sorts to maintain price order.

---

### User Story 4 - Remove Coins from Watchlist (Priority: P4)

Users need to clean up their watchlist by removing coins they no longer want to track.

**Why this priority**: Removal is necessary for long-term usage but not critical for initial MVP testing. Users can add coins and use the watchlist without removal initially.

**Independent Test**: Can be tested by adding coins and verifying swipe-to-delete removes them from Swift Data and UI. Independent of all other stories.

**Acceptance Scenarios**:

1. **Given** user has coins in watchlist, **When** they swipe left on a coin row, **Then** a red "Delete" button appears.

2. **Given** delete button is visible, **When** user taps "Delete", **Then** the coin is removed from the watchlist with a smooth animation.

3. **Given** user removed their last coin, **When** watchlist is empty, **Then** they see an empty state message "Your watchlist is empty. Tap + to add cryptocurrencies."

---

### Edge Cases

- What happens when CoinGecko API is unreachable? Display cached prices with "Last updated: X minutes ago" indicator and show error on refresh attempt.
- What happens when user has no internet connection? Show cached data and display "Offline - showing last known prices" message.
- What happens when a coin is delisted from CoinGecko? Display "Data unavailable" for that coin and allow user to remove it.
- What happens when user adds 1000+ coins? LazyVStack ensures smooth scrolling; warn user if approaching reasonable limits (100-200 coins).
- What happens during 30-second automatic update if user is scrolling? Updates queue until scrolling stops to avoid UI disruption.
- What happens if CoinGecko API rate limit is hit? Back off exponentially and show last cached data.

### Phase Scope Validation

**⚠️ CONSTITUTION PRINCIPLE V CHECK**: Verify this feature is in Phase 1 scope (see CLAUDE.md and `.specify/memory/constitution.md`).

**Feature Category**:
- [x] Watchlist feature (explicitly in Phase 1)
- [ ] Manual Portfolio feature (explicitly in Phase 1)
- [ ] ❌ OUT OF SCOPE - Requires constitution amendment and explicit approval

**Confirmed**: Watchlist is explicitly listed in Phase 1 scope of CLAUDE.md.

**Out-of-scope features NOT included**:
- ✅ No wallet integration
- ✅ No multiple portfolios
- ✅ No charts/graphs (only current price + 24h change)
- ✅ No price alerts
- ✅ No widgets
- ✅ No ads/monetization
- ✅ No social features
- ✅ No iCloud sync (local only)
- ✅ No export functionality

**Approval Required**: None - feature is within approved Phase 1 scope.

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to search cryptocurrencies by name or symbol via CoinGecko API
- **FR-002**: System MUST display coin name, symbol, current USD price, and 24-hour price change percentage for each watchlist item
- **FR-003**: System MUST provide sort options: Name (A-Z), Price (High-Low), 24h Change (Best-Worst)
- **FR-004**: Users MUST be able to remove coins from watchlist via swipe-to-delete gesture
- **FR-005**: System MUST support manual price refresh via pull-to-refresh gesture
- **FR-006**: System MUST automatically update prices every 30 seconds in background without blocking UI
- **FR-007**: System MUST persist watchlist locally using Swift Data (survives app restarts)
- **FR-008**: System MUST maintain 60fps scrolling performance for lists with 50+ coins
- **FR-009**: System MUST batch API requests (fetch multiple coin prices in single request)
- **FR-010**: System MUST cache API responses (in-memory + Swift Data) to minimize network requests
- **FR-011**: System MUST handle network errors gracefully (show cached data + error message)
- **FR-012**: System MUST prevent duplicate coins in watchlist (show error if user tries to add existing coin)
- **FR-013**: System MUST use Liquid Glass design language (translucent materials, system colors, iOS 26 standards)
- **FR-014**: System MUST use Decimal type for all price values (NOT Double/Float)

### Key Entities

- **Coin**: Cryptocurrency from CoinGecko API
  - Attributes: id (string), symbol (string), name (string), currentPrice (Decimal), priceChange24h (Decimal), lastUpdated (Date)
  - Source: CoinGecko /coins/markets API
  - Cached in memory for performance

- **WatchlistItem**: User's tracked cryptocurrency (persisted)
  - Attributes: coinId (string, unique), dateAdded (Date), sortOrder (int)
  - Relationship: References Coin by coinId
  - Storage: Swift Data (local persistence)

- **CoinListItem**: Cryptocurrency for search results
  - Attributes: id (string), symbol (string), name (string)
  - Source: CoinGecko /coins/list API
  - Cached locally for 7 days

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can complete search and add workflow in under 5 seconds (search + tap + add)
- **SC-002**: System maintains 60fps scrolling validated with Xcode Instruments Time Profiler
- **SC-003**: Price updates occur every 30 seconds without UI blocking (validated with Instruments)
- **SC-004**: Search returns results in under 1 second for any query
- **SC-005**: App remains responsive during API failures (shows cached data within 100ms)
- **SC-006**: Zero crashes during 1-hour stress test (add 100 coins, scroll, sort, refresh, delete)
- **SC-007**: Liquid Glass design passes visual review against iOS 26 HIG (translucent materials, proper spacing, system colors)
- **SC-008**: Users can identify price changes at a glance (color coding clearly visible)
- **SC-009**: API efficiency: <50 requests per hour per user (respects rate limits)
- **SC-010**: Memory usage stays under 100MB with 100 coins in watchlist
