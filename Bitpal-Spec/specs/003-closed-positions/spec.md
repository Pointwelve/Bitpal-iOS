# Feature Specification: Closed Positions & Realized P&L

**Feature Branch**: `003-closed-positions`
**Created**: 2025-01-21
**Status**: Draft
**Input**: User description: "Show closed positions and realized P&L in portfolio. In the future, show entire portfolio performance including closed positions."

## Clarifications

### Session 2025-01-22

- Q: How should multiple close/reopen cycles for the same coin be tracked? → A: Each close/reopen cycle creates separate entry identified by close date
- Q: What is the collapsed state behavior when there are more than 5 closed positions? → A: Show header with count (e.g., "Closed Positions (12)"), tap to expand/collapse all entries

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Closed Positions List (Priority: P1)

Users who have completely sold out of a cryptocurrency position want to see their historical realized profit/loss for that coin, separate from their active holdings.

**Why this priority**: Core functionality - provides immediate visibility into past trading performance. Users need to see which coins they made or lost money on after closing positions.

**Independent Test**: Can be fully tested by creating buy/sell transactions that net to zero (e.g., buy 1 BTC, sell 1 BTC) and verifying that the coin appears in a "Closed Positions" section with calculated realized P&L. Delivers immediate value by showing trading history.

**Acceptance Scenarios**:

1. **Given** user has fully sold a coin (total sold = total bought), **When** viewing Portfolio screen, **Then** the coin appears in a "Closed Positions" section below active holdings
2. **Given** user has a closed position with profit, **When** viewing the closed position, **Then** realized P&L shows positive value in green with % gain
3. **Given** user has a closed position with loss, **When** viewing the closed position, **Then** realized P&L shows negative value in red with % loss
4. **Given** user has only active holdings (no closed positions), **When** viewing Portfolio screen, **Then** "Closed Positions" section is not displayed
5. **Given** user closes a position (makes final sell transaction), **When** transaction is saved, **Then** coin moves from active holdings to closed positions automatically
6. **Given** user has more than 5 closed positions, **When** viewing Portfolio screen, **Then** Closed Positions section shows collapsed header with count (e.g., "Closed Positions (12)") and no entries visible
7. **Given** Closed Positions section is collapsed, **When** user taps the header, **Then** section expands to show all closed position entries
8. **Given** Closed Positions section is expanded, **When** user taps the header again, **Then** section collapses back to header-only view

---

### User Story 2 - Portfolio Summary with Realized Gains (Priority: P2)

Users want to see their total portfolio performance including both current holdings (unrealized P&L) and closed positions (realized P&L) in the portfolio summary at the top.

**Why this priority**: Provides complete financial picture. Without this, users only see current holdings and miss the bigger picture of their trading performance.

**Independent Test**: Can be tested by creating a mix of open and closed positions, then verifying that the portfolio summary shows separate values for unrealized P&L (open) and realized P&L (closed), plus total P&L. Demonstrates complete portfolio transparency.

**Acceptance Scenarios**:

1. **Given** user has both open holdings and closed positions, **When** viewing Portfolio summary, **Then** summary shows: Total Value, Unrealized P&L (from open holdings), Realized P&L (from closed positions), Total P&L (sum)
2. **Given** user has only closed positions (no open holdings), **When** viewing Portfolio summary, **Then** Total Value is $0, Unrealized P&L is $0, Realized P&L shows cumulative gains/losses
3. **Given** user has profitable closed trades and losing open holdings, **When** viewing summary, **Then** realized P&L is green (positive), unrealized P&L is red (negative), total P&L shows net result
4. **Given** user taps on Realized P&L in summary, **When** tapped, **Then** scrolls/navigates to Closed Positions section

---

### User Story 3 - Closed Position Details (Priority: P3)

Users want to see detailed breakdown of closed positions including transaction history, average cost, average sale price, and total gain/loss.

**Why this priority**: Nice-to-have detail view. While helpful for understanding trades, the P1 list view provides core value. This enhances understanding but isn't critical for MVP.

**Independent Test**: Can be tested by tapping a closed position and verifying that a detail view shows all buy/sell transactions, weighted averages, and P&L calculation breakdown. Provides educational value for users wanting to understand their trades.

**Acceptance Scenarios**:

1. **Given** user taps a closed position in the list, **When** detail view opens, **Then** shows: coin name, total quantity traded, average buy price, average sell price, realized P&L ($), realized P&L (%), transaction history
2. **Given** user has multiple buy/sell transactions for a closed position, **When** viewing detail, **Then** transaction history shows all buys and sells in chronological order with running balance
3. **Given** user views closed position detail, **When** user wants to re-enter the position, **Then** can tap "Buy Again" button which opens Add Transaction sheet pre-filled with the coin

---

### Edge Cases

- **Partial Sales**: What happens when user sells part of holdings? Position remains in active holdings, not moved to closed.
- **Multiple Close/Reopen Cycles**: When user fully sells a coin (closes position), then buys it again later, each close/reopen cycle creates a separate closed position entry identified by the close date. This preserves complete trading history and allows users to track performance of individual trades over time. Example: Buy BTC on Jan 1, sell on Jan 15 (Cycle 1), buy again on Feb 1, sell on Feb 20 (Cycle 2) → Creates two separate closed position entries. **CRITICAL**: Cycles are isolated - new open holdings MUST NOT include transactions from closed cycles in their average cost or P&L calculations (FR-016). Transaction history views MUST show only the relevant cycle's transactions (FR-017).
- **Fractional Amounts**: If buy/sell amounts don't exactly match due to decimals (e.g., buy 1.0 BTC, sell 0.999999 BTC), when is position considered "closed"? (Threshold: if remaining amount < 0.00000001, consider closed)
- **Zero-Cost Positions**: If user receives coins as gifts (no cost basis), then sells, how to calculate P&L? (Use $0 cost basis - entire sale is profit)
- **Transaction Deletions**: If user deletes a sell transaction that closed a position, position should move back to active holdings with recalculated amount.
- **Collapse Threshold Boundary**: If user has exactly 5 closed positions, section displays expanded (shows all 5 entries). Collapse behavior only activates at 6+ closed positions.
- **Only Closed Positions**: When user has closed all positions (no open holdings), the isEmpty check must consider both holdings AND closedPositions to prevent incorrect empty state display. The system must show Portfolio Summary + Closed Positions Section, not the "No Holdings Yet" empty state. Implementation: `isEmpty` returns `holdings.isEmpty && closedPositions.isEmpty`.

### Phase Scope Validation

**� CONSTITUTION PRINCIPLE V CHECK**: Verify this feature is in Phase 1 scope (see CLAUDE.md and `.specify/memory/constitution.md`).

**Feature Category** (check one):
- [x] Manual Portfolio feature (explicitly in Phase 1)
- [ ] Watchlist feature (explicitly in Phase 1)
- [ ] L OUT OF SCOPE - Requires constitution amendment and explicit approval

**Justification**: This is a natural extension of the Manual Portfolio feature (002-portfolio). It uses the same Transaction model and calculations, just adds a view for positions where total sold = total bought. No new data sources, no out-of-scope dependencies.

**If OUT OF SCOPE, explicitly forbidden features include**:
- Wallet integration, Multiple portfolios, Charts/graphs, Price alerts, Widgets, Ads/monetization, Social features, News feeds, iCloud sync, Export functionality, Biometric authentication

**Approval Required**:  No approval needed - within Phase 1 scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST identify closed positions by comparing total buy quantity vs total sell quantity for each coin (closed when buy = sell within tolerance of 0.00000001)
- **FR-002**: System MUST calculate realized P&L for closed positions as: (weighted avg sale price - weighted avg cost price) � total quantity sold
- **FR-003**: System MUST display closed positions in a separate "Closed Positions" section below active holdings on Portfolio screen
- **FR-004**: System MUST show for each closed position: coin name, symbol, total quantity traded, realized P&L ($), realized P&L (%), close date (date of final sell transaction)
- **FR-005**: System MUST use profit/loss color coding (green for gains, red for losses) for realized P&L display
- **FR-006**: System MUST hide "Closed Positions" section if no positions have been fully sold
- **FR-007**: System MUST automatically move positions from active holdings to closed when final sell transaction brings balance to zero (or within tolerance)
- **FR-008**: System MUST update portfolio summary to show: Total Value (open holdings only), Unrealized P&L (open), Realized P&L (closed), Total P&L (unrealized + realized)
- **FR-009**: System MUST allow users to tap closed position to view transaction history (all buys/sells for that specific cycle only, not all cycles for that coin)
- **FR-010**: System MUST handle multiple close/reopen cycles by creating separate closed position entries for each cycle, where each cycle is identified by the close date (date of final sell transaction) and includes only transactions between the previous close and current close
- **FR-011**: System MUST sort closed positions by close date (most recent first)
- **FR-012**: System MUST recalculate closed positions if user deletes/edits transactions that affect closed status
- **FR-013**: System MUST display Closed Positions section in collapsed state (header with count only) when user has more than 5 closed positions
- **FR-014**: System MUST allow users to expand/collapse Closed Positions section by tapping the section header, toggling between header-only view and full list view
- **FR-015**: System MUST persist the expanded/collapsed state of Closed Positions section during the current session (state resets to collapsed on app restart)
- **FR-016**: System MUST exclude transactions from closed cycles when computing open holdings (average cost, total amount, profit/loss calculations must only use current cycle transactions)
- **FR-017**: System MUST display cycle-isolated transaction history: closed positions show only that cycle's transactions, open holdings show only current cycle's transactions (not all historical transactions for that coin)

### Key Entities *(include if feature involves data)*

- **ClosedPosition (Computed Model - NOT stored)**:
  - Represents a single buy-to-sell cycle for a specific coin
  - Derived from Transaction records where total buy quantity = total sell quantity for a cycle
  - Attributes: coinId, coin (Coin details), totalQuantity (amount traded in this cycle), avgCostPrice (weighted average for cycle), avgSalePrice (weighted average for cycle), realizedPnL (profit/loss $ for cycle), realizedPnLPercentage (% for cycle), closedDate (date of final sell that closed this cycle)
  - Relationships: References Transaction records via coinId, grouped by cycle (transactions between previous close and current close)
  - Calculation: Group transactions by coinId and cycle boundary, filter where SUM(buy amounts) ≈ SUM(sell amounts), compute weighted averages and P&L per cycle
  - Multiple cycles: If same coin is bought/sold multiple times, each complete cycle creates a separate ClosedPosition entry

- **PortfolioSummary (Enhanced)**:
  - Existing entity extended with new attributes:
  - totalValue (current holdings value - existing)
  - unrealizedPnL (open positions P&L - existing, renamed for clarity)
  - realizedPnL (closed positions cumulative P&L - NEW)
  - totalPnL (unrealized + realized - NEW)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can identify all coins they've fully sold within 2 seconds of opening Portfolio screen
- **SC-002**: Realized P&L calculation is accurate within $0.01 for all closed positions (tested against manual calculation)
- **SC-003**: Portfolio summary displays complete performance picture (open + closed P&L) without user needing to navigate to separate screen
- **SC-004**: System correctly handles 50+ closed positions without performance degradation (list scrolls smoothly at 60fps)
- **SC-005**: 95% of users can understand the difference between unrealized (open) and realized (closed) P&L without additional explanation
- **SC-006**: When user closes a position (final sell), it appears in Closed Positions section immediately (< 500ms update)

## Assumptions *(auto-generated during spec creation)*

1. **Close Threshold**: A position is considered "closed" when `|total bought - total sold| < 0.00000001` (to handle floating-point precision issues)
2. **Multiple Cycles**: Each close/reopen cycle creates a separate closed position entry identified by close date, including only transactions for that specific cycle (preserves complete trading history)
3. **Weighted Averages**: Cost and sale prices use weighted average calculation per cycle (same calculation method as existing Holding model)
4. **UI Placement**: Closed Positions section appears below active holdings; when > 5 closed positions exist, section displays collapsed with header showing count (e.g., "Closed Positions (12)"), expandable by tapping header
5. **Transaction History Access**: Tapping closed position entry (when expanded) opens same TransactionHistoryView used for active holdings
6. **Data Storage**: Closed positions are computed on-the-fly from Transaction records (not stored separately in database)
7. **Performance**: Computing closed positions from transactions is fast enough for real-time display (< 100ms for 100 transactions)

## Dependencies

- **Existing Features**: Requires 002-portfolio feature (Transaction model, Holding calculations)
- **Data Models**: Uses Transaction (@Model), extends Holding calculation logic
- **UI Components**: Reuses LiquidGlassCard, TransactionHistoryView, portfolio summary components

## Future Considerations *(not in current scope)*

- **Charts**: Visualize portfolio performance over time including closed positions (Phase 2+)
- **Export**: Generate tax reports from closed positions (Phase 3+)
- **Filtering**: Filter closed positions by date range, coin type, profit/loss (Phase 2+)
- **Statistics**: Advanced metrics like win rate (% profitable closes), average hold time (Phase 2+)
