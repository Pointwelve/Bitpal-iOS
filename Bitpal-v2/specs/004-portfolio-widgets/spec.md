# Feature Specification: iOS Home Screen Widgets for Portfolio

**Feature Branch**: `004-portfolio-widgets`
**Created**: 2025-11-26
**Status**: Draft
**Input**: User description: "Add WidgetKit-based home screen widgets that display the user's portfolio value and holdings at a glance. Users should be able to see their total portfolio value, P&L, and top holdings without opening the app."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Quick Portfolio Check (Priority: P1)

As a crypto investor, I want to glance at my home screen to see my total portfolio value and profit/loss without opening any app, so I can stay informed throughout my day with zero friction.

**Why this priority**: This is the core value proposition. Crypto traders check prices 20-50 times daily; reducing this friction to a single glance creates habit-forming engagement and delivers immediate value.

**Independent Test**: Can be fully tested by adding the small widget to the home screen and verifying portfolio value and P&L display correctly with color coding. Delivers instant portfolio awareness.

**Acceptance Scenarios**:

1. **Given** I have added the small widget to my home screen and have holdings in my portfolio, **When** I view my home screen, **Then** I see my total portfolio value prominently displayed with P&L amount and directional indicator (green/up for profit, red/down for loss)
2. **Given** my portfolio value has changed, **When** I view the widget, **Then** I see the updated value with a timestamp showing when data was last refreshed
3. **Given** I tap the small widget, **When** the app opens, **Then** I am taken directly to the Portfolio tab

---

### User Story 2 - Top Holdings Overview (Priority: P2)

As a crypto investor with multiple holdings, I want to see my top performing or largest holdings at a glance on the medium widget, so I can quickly understand which assets are driving my portfolio performance.

**Why this priority**: After knowing total value, users want to understand composition. The medium widget extends the small widget value by showing top 2 holdings without requiring app launch.

**Independent Test**: Can be tested by adding the medium widget and verifying it displays total value, both realized and unrealized P&L, plus top 2 holdings with their individual performance metrics.

**Acceptance Scenarios**:

1. **Given** I have the medium widget on my home screen with 3+ holdings, **When** I view the widget, **Then** I see total portfolio value, unrealized P&L with percentage, realized P&L, and my top 2 holdings by value
2. **Given** my holdings include coins with positive and negative P&L, **When** I view each holding row, **Then** the P&L is color-coded appropriately (green for gains, red for losses)
3. **Given** I tap the medium widget, **When** the app opens, **Then** I am taken to the Portfolio tab

---

### User Story 3 - Detailed Holdings View (Priority: P3)

As a power user with a diverse portfolio, I want a large widget showing my top 5 holdings with comprehensive details, so I can monitor my entire portfolio composition without opening the app.

**Why this priority**: Serves power users who want maximum information density. Lower priority because it requires more screen real estate and serves a smaller user segment.

**Independent Test**: Can be tested by adding the large widget and verifying it shows total value, all P&L types (unrealized, realized, total), and top 5 holdings with symbol, name, value, P&L amount, and P&L percentage.

**Acceptance Scenarios**:

1. **Given** I have the large widget on my home screen with 5+ holdings, **When** I view the widget, **Then** I see total portfolio value, unrealized P&L %, realized P&L, total P&L, and my top 5 holdings
2. **Given** I tap anywhere on the large widget, **When** the app opens, **Then** I am taken to the Portfolio tab
3. **Given** I have fewer than 5 holdings, **When** I view the large widget, **Then** only my actual holdings are displayed without empty placeholder rows

---

### Edge Cases

- What happens when the user has no holdings in their portfolio? Widget displays "No holdings" message with prompt to add transactions
- What happens when the user has only 1 holding but uses the medium/large widget? Widget displays available holdings without empty placeholder rows
- What happens when price data is unavailable or stale (network offline)? Widget shows last known values with "Offline" or "Unable to refresh" indicator and stale timestamp
- What happens when the user deletes all transactions? Widget updates to show empty state on next refresh cycle
- What happens when background refresh fails repeatedly? Widget continues showing last known data with increasingly stale timestamp; user can manually refresh by opening the app

### Phase Scope Validation

**Feature Category** (check one):
- [ ] Watchlist feature (Phase 1)
- [ ] Manual Portfolio feature (Phase 1)
- [x] Home Screen Widgets (Phase 2 - ACTIVE)

**Phase 2 Scope Alignment**: This feature is explicitly within Phase 2 scope per constitution v2.0.0. The constitution was amended to mark Phase 1 as COMPLETE and Phase 2 (Widgets) as ACTIVE.

**Explicitly OUT OF SCOPE for Phase 2** (per constitution):
- Watchlist widgets (portfolio only)
- Lock screen widgets
- Widget configuration UI
- Widget customization (themes, colors)
- Interactive widgets (buttons)
- Live Activities
- Any monetization

## Requirements *(mandatory)*

### Functional Requirements

**Widget Types:**
- **FR-001**: System MUST provide a small widget (systemSmall) displaying total portfolio value, total P&L with color coding, and last-updated timestamp
- **FR-002**: System MUST provide a medium widget (systemMedium) displaying total portfolio value, P&L breakdown (unrealized/realized), top 2 holdings by value, and last-updated timestamp
- **FR-003**: System MUST provide a large widget (systemLarge) displaying total portfolio value, P&L breakdown (unrealized/realized/total), top 5 holdings with symbol/name/value/P&L, and last-updated timestamp

**Data & Refresh:**
- **FR-004**: Widget timeline MUST refresh every 30 minutes maximum (per constitution principle I)
- **FR-005**: Background fetch MUST only request prices for coins the user owns (no fetching all coins)
- **FR-006**: Widgets MUST share data with the main app using a shared App Group container
- **FR-007**: Widget P&L calculations MUST use shared code with main app (no duplication)
- **FR-008**: Widget extension MUST stay under 30MB memory footprint

**Display & Interaction:**
- **FR-009**: Widgets MUST use color coding for P&L display: green for positive values, red for negative values
- **FR-010**: All widgets MUST deep link to the Portfolio tab when tapped
- **FR-011**: Holdings displayed on widgets MUST be ordered by current value (highest first)
- **FR-012**: Widget design MUST follow the Liquid Glass design language with system widget backgrounds
- **FR-013**: Widgets MUST support Light and Dark mode automatically

**Error Handling:**
- **FR-014**: Widgets MUST display graceful empty states when the user has no portfolio holdings
- **FR-015**: Widgets MUST always show cached data when API is unavailable (blank widgets are forbidden)
- **FR-016**: Offline state MUST be visually distinct but not alarming

### Key Entities

- **WidgetPortfolioData**: Shared data structure containing total portfolio value, unrealized P&L, realized P&L, total P&L, last-updated timestamp, and array of top holdings
- **WidgetHolding**: Simplified holding representation with coin symbol, coin name, current value, P&L amount, and P&L percentage
- **Widget Configuration**: User's widget placement and size preferences (managed by iOS, not the app)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can view their total portfolio value on the home screen within 1 second of waking their device
- **SC-002**: Widget data refreshes every 30 minutes during active device usage
- **SC-003**: Tapping any widget opens the Portfolio tab in under 2 seconds
- **SC-004**: Widget P&L values match main app exactly (no approximations or rounding differences)
- **SC-005**: Offline mode displays cached data gracefully without blank or error widgets
- **SC-006**: All 3 widget sizes render correctly on all supported device sizes
- **SC-007**: Widget extension memory usage stays under 30MB
