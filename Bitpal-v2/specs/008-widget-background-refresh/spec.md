# Feature Specification: Widget Background Refresh

**Feature Branch**: `008-widget-background-refresh`
**Created**: 2025-12-11
**Status**: Draft
**Input**: User description: "Widget data becomes stale because it only reads cached data from App Group. The main app must be opened for prices to refresh. Widget should fetch fresh prices directly when iOS refreshes the timeline."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Widget Shows Fresh Prices Without Opening App (Priority: P1)

As a user with a home screen widget, I want the widget to display fresh portfolio prices even when I haven't opened the app in hours, so that I can quickly glance at my portfolio value without needing to launch the full application.

**Why this priority**: This is the core value proposition - users add widgets for quick glances. Stale data defeats the entire purpose of having a widget.

**Independent Test**: Can be fully tested by adding the widget to home screen, waiting 15+ minutes without opening the app, and verifying prices update. Delivers the primary user value of up-to-date portfolio information at a glance.

**Acceptance Scenarios**:

1. **Given** I have a portfolio widget on my home screen and I haven't opened the app for 30 minutes, **When** I glance at my widget, **Then** I see prices that are no more than 15-30 minutes old
2. **Given** the widget timeline is refreshing, **When** fresh prices are fetched successfully, **Then** the widget displays updated values, P&L amounts, and P&L percentages
3. **Given** the widget has portfolio holdings, **When** iOS calls the timeline refresh, **Then** the system fetches current prices for all held coins in a single batched API request

---

### User Story 2 - Graceful Fallback on Network Failure (Priority: P2)

As a user in an area with poor network connectivity, I want the widget to display the most recent cached data when fresh prices cannot be fetched, so that I still see useful information rather than an error state.

**Why this priority**: Network failures are common (airplane mode, poor signal, offline). Users should always see something useful rather than a broken widget.

**Independent Test**: Can be tested by enabling airplane mode, waiting for a widget refresh, and verifying cached data is displayed with an appropriate staleness indicator.

**Acceptance Scenarios**:

1. **Given** the widget attempts to refresh but the network request fails, **When** the timeline update completes, **Then** the widget displays the most recent cached data
2. **Given** cached data is displayed after a network failure, **When** the data is older than 60 minutes, **Then** a visual indicator shows the data may be outdated
3. **Given** a network failure occurred, **When** the next refresh cycle runs and succeeds, **Then** fresh data replaces the stale cached data

---

### User Story 3 - Empty State for Users Without Holdings (Priority: P3)

As a new user who has added the widget but has no portfolio holdings yet, I want to see a helpful empty state that guides me to add holdings, so that I understand why the widget appears empty.

**Why this priority**: Edge case for new users. Important for onboarding but not the primary use case.

**Independent Test**: Can be tested by adding the widget when the user has no portfolio transactions, verifying an appropriate empty state message is displayed.

**Acceptance Scenarios**:

1. **Given** I have no portfolio holdings, **When** I view the widget, **Then** I see a message indicating I need to add holdings in the app
2. **Given** I add my first holding in the app, **When** the next widget refresh occurs, **Then** the widget displays my new holding with current price

---

### Edge Cases

- What happens when the API rate limit is exceeded? The widget falls back to cached data and tries again on the next refresh cycle.
- What happens if the refresh takes longer than WidgetKit's time budget (~15-30 seconds)? The request times out and cached data is used.
- What happens when a coin is removed from the portfolio? On next refresh, the widget recalculates holdings from the updated data.
- What happens if prices haven't changed since last refresh? The widget still updates the lastUpdated timestamp to indicate freshness.

### Phase Scope Validation

**Feature Category** (check one):
- [ ] Watchlist feature (explicitly in Phase 1)
- [x] Manual Portfolio feature (explicitly in Phase 1)
- [ ] OUT OF SCOPE - Requires constitution amendment and explicit approval

**Rationale**: This feature enhances the existing portfolio widget (004-portfolio-widgets) which displays portfolio data. It improves the existing Phase 1 portfolio functionality by ensuring the widget shows current data. This is an enhancement to existing functionality, not a new feature category.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Widget timeline provider MUST fetch current prices from the API when iOS requests a timeline refresh
- **FR-002**: System MUST store portfolio holding quantities and cost basis in the App Group for the widget to recalculate values
- **FR-003**: Widget MUST use a single batched API request to fetch prices for all held coins (not individual requests per coin)
- **FR-004**: Widget MUST fall back to cached data when the API request fails or times out
- **FR-005**: Widget MUST display a staleness indicator when cached data is older than 60 minutes
- **FR-006**: Widget timeline MUST request refresh every 15 minutes (WidgetKit may adjust based on system conditions)
- **FR-007**: Widget MUST recalculate P&L amounts and percentages using fresh prices and stored cost basis
- **FR-008**: Main app MUST write holding quantities and cost basis to App Group when portfolio data updates
- **FR-009**: Widget MUST handle empty portfolio state with appropriate messaging

### Key Entities

- **WidgetRefreshData**: Stored in App Group, contains coin IDs, quantities, average costs, and realized P&L needed for widget to recalculate values with fresh prices
- **WidgetPortfolioData**: Display data for the widget including total value, P&L, and individual holdings (already exists, updated by widget after fetching fresh prices)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Widget displays prices no more than 30 minutes old when device has network connectivity (measured by lastUpdated timestamp)
- **SC-002**: Widget data updates without user opening the main app (verified by comparing widget prices to main app after 30+ minutes of app inactivity)
- **SC-003**: Widget refresh completes within 15 seconds (WidgetKit time budget compliance)
- **SC-004**: Widget makes exactly one API request per refresh cycle regardless of number of holdings (batch efficiency)
- **SC-005**: Widget displays cached data 100% of the time when network is unavailable (no blank/error states)
- **SC-006**: Staleness indicator appears when data is older than 60 minutes (visual feedback accuracy)

### Assumptions

- WidgetKit will call `getTimeline()` periodically (every 15-30 minutes when widget is visible) - actual frequency is controlled by iOS based on battery, usage patterns, and system load
- Widget extensions have sufficient network access and time budget (~15-30 seconds) to complete an API request
- CoinGecko API `/coins/markets` endpoint can fetch prices for multiple coins in a single request (up to 250 IDs)
- Existing App Group infrastructure (`group.com.bitpal.shared`) is properly configured and accessible by both app and widget
- Users typically have fewer than 50 holdings, well within API batch limits
