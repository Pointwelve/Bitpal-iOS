# Feature Specification: Manual Portfolio

**Feature Branch**: `002-portfolio`
**Created**: 2025-11-16
**Status**: Draft
**Input**: Portfolio allows users to manually track their cryptocurrency investments by recording buy/sell transactions and viewing their current holdings with profit/loss calculations. This is the core value proposition of Bitpal - giving users a clear view of their crypto investment performance.

## User Scenarios & Testing

### User Story 1 - Add Buy/Sell Transactions (Priority: P1)

Users need to record their cryptocurrency purchases and sales to build an accurate portfolio history. This is the foundation of portfolio tracking - without transaction data, there's nothing to track.

**Why this priority**: This is the absolute MVP - the entire portfolio feature is meaningless without the ability to input transaction data. Everything else depends on this.

**Independent Test**: Can be fully tested by implementing transaction input form with validation and verifying data persists correctly. Does not require holdings calculation or price updates to validate data entry works.

**Acceptance Scenarios**:

1. **Given** user is on Portfolio tab, **When** they tap "Add Transaction" button, **Then** a transaction input sheet appears with fields for coin selection, transaction type (Buy/Sell), quantity, price per coin, date, and optional notes.

2. **Given** transaction form is open, **When** user selects "Bitcoin" from coin picker, enters type "Buy", quantity "1.5", price "$40,000", and date "Jan 15, 2025", **Then** all fields validate successfully and Save button becomes enabled.

3. **Given** user has filled transaction form, **When** they tap "Save", **Then** transaction is stored permanently and form dismisses with confirmation.

4. **Given** user enters invalid data (negative quantity, zero price, future date), **When** they attempt to save, **Then** clear error messages appear for each invalid field and save is prevented.

---

### User Story 2 - View Holdings with Profit/Loss Calculations (Priority: P2)

Users need to see their current cryptocurrency holdings computed from their transaction history, with accurate profit/loss calculations showing investment performance.

**Why this priority**: This delivers the core value proposition - seeing how investments are performing. P2 because it requires P1 (transactions) but is the primary reason users want portfolio tracking.

**Independent Test**: Can be tested by creating sample transactions and verifying holdings display correctly with accurate P&L calculations. Can use mock current prices to validate calculation accuracy without API integration.

**Acceptance Scenarios**:

1. **Given** user has recorded buy transactions for Bitcoin (2 BTC at $40,000 avg cost) and current price is $50,000, **When** they view Portfolio tab, **Then** they see "Bitcoin" holding showing: "2.0 BTC", "Avg Cost: $40,000", "Current Value: $100,000", "P&L: +$20,000 (+25%)" in green.

2. **Given** user has mixed buy/sell transactions (bought 3 ETH at $3,000, sold 1 ETH at $3,500, avg remaining cost $3,000) and current price is $2,800, **When** they view holdings, **Then** Ethereum shows "2.0 ETH", "Avg Cost: $3,000", "Current Value: $5,600", "P&L: -$800 (-13.3%)" in red.

3. **Given** user has sold all quantity of a coin (total amount = 0), **When** holdings list is displayed, **Then** that coin does not appear in holdings (only active positions shown).

4. **Given** current prices update from API, **When** holdings list is visible, **Then** current values and P&L recalculate automatically and update smoothly without jank.

---

### User Story 3 - View Portfolio Summary (Priority: P3)

Users need a high-level overview showing total portfolio value and overall profit/loss across all holdings.

**Why this priority**: Provides immediate portfolio health snapshot. P3 because users can still see individual holdings (P2) without summary, but this significantly improves user experience.

**Independent Test**: Can be tested by adding multiple holdings and verifying summary totals are computed correctly. Independent of transaction entry UI - can use preloaded transaction data.

**Acceptance Scenarios**:

1. **Given** user has holdings worth $127,456.89 total with $23,456 profit, **When** they open Portfolio tab, **Then** they see summary card at top displaying "Total Value: $127,456.89" and "Total P&L: +$23,456 (+22.5%)" in green with prominent typography.

2. **Given** user's portfolio has lost value (total cost $100,000, current value $85,000), **When** summary displays, **Then** it shows "Total P&L: -$15,000 (-15%)" in red with clear visual distinction from profit.

3. **Given** user has no holdings (empty portfolio), **When** Portfolio tab is viewed, **Then** summary shows "$0.00" for all values and displays empty state message "Start tracking by adding your first transaction."

4. **Given** prices update and portfolio value changes, **When** summary is visible, **Then** totals recalculate immediately and update with smooth animation.

---

### User Story 4 - View Transaction History Per Coin (Priority: P4)

Users need to access detailed transaction history for each holding to review their buy/sell decisions and verify portfolio accuracy.

**Why this priority**: Important for transparency and accuracy verification, but users can use portfolio without reviewing history. P4 because viewing current holdings (P2) delivers primary value.

**Independent Test**: Can be tested by adding transactions for a coin and verifying complete history displays correctly ordered by date. Does not require holdings calculation to work.

**Acceptance Scenarios**:

1. **Given** user taps on a Bitcoin holding in their portfolio, **When** detail view opens, **Then** they see complete list of all Bitcoin transactions ordered by date (newest first) showing type, quantity, price, date, and optional notes.

2. **Given** user views transaction history for Ethereum (5 transactions over 3 months), **When** list displays, **Then** each transaction shows clear visual distinction between Buy (green accent) and Sell (red accent) types.

3. **Given** user added notes to a transaction ("bought the dip"), **When** viewing transaction history, **Then** notes display below transaction details in lighter text.

4. **Given** user has no transactions for a coin yet, **When** attempting to view history, **Then** this scenario doesn't occur (can't have holding without transactions).

---

### User Story 5 - Edit and Delete Transactions (Priority: P5)

Users need to correct mistakes or remove erroneous transactions to maintain accurate portfolio records.

**Why this priority**: Essential for data accuracy but not needed for initial portfolio testing. P5 because users can add transactions (P1) and view portfolio (P2-P3) without editing capability initially.

**Independent Test**: Can be tested by modifying/deleting existing transactions and verifying holdings recalculate correctly. Independent of all other stories.

**Acceptance Scenarios**:

1. **Given** user is viewing transaction history, **When** they tap on a specific transaction, **Then** edit sheet opens prepopulated with that transaction's data (coin, type, quantity, price, date, notes).

2. **Given** edit sheet is open showing "Bitcoin Buy 1.5 BTC at $40,000", **When** user changes quantity to "2.0 BTC" and taps "Save", **Then** transaction updates, holdings recalculate to reflect new quantity, and sheet dismisses.

3. **Given** user is viewing transaction history, **When** they swipe left on a transaction and tap "Delete", **Then** confirmation alert appears asking "Delete this transaction? This will affect your holdings."

4. **Given** user confirms deletion of a transaction, **When** deletion completes, **Then** transaction is removed permanently, holdings recalculate without that transaction, and transaction list updates with smooth animation.

---

### Edge Cases

- What happens when user tries to sell more quantity than they own? Prevent save and show error "You only own X BTC. Cannot sell Y BTC."
- What happens when user has 1000+ transactions across 50+ coins? System maintains smooth scrolling; computations are optimized for performance.
- What happens when user enters transaction date in future? Prevent save and show error "Transaction date cannot be in the future."
- What happens when current price data is unavailable? Show holdings with last known prices and display "Prices last updated: X minutes ago" indicator.
- What happens when user deletes all transactions for a coin? That coin's holding disappears from portfolio (total amount = 0).
- What happens during price update if user is editing a transaction? Updates queue until edit sheet dismisses to avoid disrupting user input.
- What happens when user enters very large numbers (1,000,000 BTC at $1,000,000)? System handles precision correctly and validates reasonable ranges (e.g., max 10M USD per transaction).
- What happens when user has both old and new transactions (5 years of history)? All transactions remain accessible in history; holdings calculation uses all data regardless of age.
- What happens when calculating average cost after multiple buys at different prices? Use weighted average: (qty1×price1 + qty2×price2) / (qty1+qty2).
- What happens when prices update while portfolio summary is visible? All values (current price, current value, P&L) recalculate atomically to avoid showing inconsistent intermediate states.
- What happens when network fails during coin search for new transaction? Allow selection from cached/recently used coins; show error message for new coin searches with retry option.

### Phase Scope Validation

**� CONSTITUTION PRINCIPLE V CHECK**: Verify this feature is in Phase 1 scope (see CLAUDE.md and `.specify/memory/constitution.md`).

**Feature Category**:
- [ ] Watchlist feature (explicitly in Phase 1)
- [x] Manual Portfolio feature (explicitly in Phase 1)
- [ ] L OUT OF SCOPE - Requires constitution amendment and explicit approval

**Confirmed**: Manual Portfolio is explicitly listed in Phase 1 scope of CLAUDE.md:

> "#### 2. Manual Portfolio
> - **Add transactions** manually:
>   - Coin selection (from CoinGecko data)
>   - Quantity (decimal support, e.g., 0.5 BTC)
>   - Purchase price per coin
>   - Transaction date (date picker)
>   - Optional notes
>   - Transaction type: Buy or Sell"

**Out-of-scope features NOT included**:
-  No wallet integration (blockchain address monitoring) - Phase 2
-  No multiple portfolios (only single default portfolio) - Phase 2
-  No charts/graphs (only current values + P&L numbers)
-  No price alerts
-  No widgets
-  No ads/monetization
-  No social features (sharing, leaderboards)
-  No iCloud sync (local only)
-  No export functionality (CSV, PDF)

**Approval Required**: None - feature is within approved Phase 1 scope.

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to create new transactions by selecting coin, transaction type (Buy/Sell), quantity, price per coin, date, and optional notes
- **FR-002**: System MUST validate transaction inputs: quantity > 0, price > 0, date d today, coin selected
- **FR-003**: System MUST prevent selling more quantity than user owns for a given coin
- **FR-004**: System MUST permanently store all transactions (data survives app restarts)
- **FR-005**: System MUST compute holdings from transaction history: total quantity = sum(buy quantities) - sum(sell quantities)
- **FR-006**: System MUST calculate weighted average cost: total cost of buys / total buy quantity (sells don't reduce avg cost)
- **FR-007**: System MUST calculate current value: total quantity × current price
- **FR-008**: System MUST calculate profit/loss: current value - (total quantity × average cost)
- **FR-009**: System MUST calculate profit/loss percentage: ((current value / (total quantity × avg cost)) - 1) × 100
- **FR-010**: System MUST display holdings with: coin name, symbol, total quantity, average cost, current value, P&L amount, P&L percentage
- **FR-011**: System MUST use color coding: green text for positive P&L, red text for negative P&L, neutral for zero
- **FR-012**: System MUST display portfolio summary showing: total portfolio value (sum of all holdings), total P&L amount, total P&L percentage
- **FR-013**: System MUST hide holdings where total quantity = 0 (all sold) from portfolio list
- **FR-014**: System MUST display transaction history per coin ordered by date (newest first)
- **FR-015**: System MUST allow users to edit existing transactions (update any field and recalculate holdings)
- **FR-016**: System MUST allow users to delete transactions with confirmation (recalculate holdings after deletion)
- **FR-017**: System MUST fetch current prices for all held coins from price data source
- **FR-018**: System MUST optimize holdings calculations to maintain smooth UI performance
- **FR-019**: System MUST ensure precise decimal calculations for all monetary values and quantities (no rounding errors)
- **FR-020**: System MUST support fractional quantities (e.g., 0.5 BTC, 1.25 ETH) with high precision (minimum 8 decimal places)
- **FR-021**: System MUST maintain smooth scrolling performance when displaying 50+ holdings with 1000+ transactions
- **FR-022**: System MUST follow platform design standards for visual consistency
- **FR-023**: System MUST update portfolio values automatically when prices refresh periodically
- **FR-024**: System MUST display "last updated" timestamp for prices when price data is unavailable
- **FR-025**: System MUST use coin data from same source as Watchlist feature for consistency
- **FR-026**: System MUST display P&L percentages to 2 decimal places (e.g., +25.34%)
- **FR-027**: System MUST show prominent "Add Your First Transaction" button in empty portfolio state
- **FR-028**: System MUST allow coin selection from cached/recently used coins when network is unavailable for new searches
- **FR-029**: System MUST display user's owned coins at the top of coin selection list when transaction type is "Sell"

### Key Entities

- **Transaction**: User's recorded buy/sell action
  - Attributes: id (unique), coinId (reference to Coin), type (Buy/Sell), amount (quantity), pricePerCoin (USD price), date, notes (optional)
  - Relationship: References Coin by coinId
  - Persistence: Permanently stored (survives app restarts)
  - **Design Note**: Data structure designed to support future portfolioId field for Phase 2+ multi-portfolio feature (currently uses implicit default portfolio)

- **TransactionType**: Enumeration of transaction types
  - Values: Buy, Sell
  - Used to differentiate transaction direction for calculation logic

- **Holding**: Computed user position (NOT persisted, calculated on-demand)
  - Attributes: coinId, coin (reference with current price), totalAmount (computed quantity), avgCost (computed weighted average), currentValue (computed), profitLoss (computed), profitLossPercentage (computed)
  - Computation: Derived from all transactions for a coinId combined with current price
  - Lifecycle: Recalculated when transactions change or prices update
  - Performance: Computed values optimized to maintain smooth UI responsiveness

- **Coin**: Cryptocurrency reference (shared with Watchlist)
  - Attributes: id, symbol, name, currentPrice, priceChange24h, lastUpdated
  - Source: Same price data source as Watchlist feature
  - Note: Portfolio uses same Coin model as Watchlist for data consistency

## Success Criteria

### Measurable Outcomes

- **SC-001**: Users can complete transaction entry workflow in under 30 seconds (from "Add Transaction" tap to save confirmation)
- **SC-002**: Profit/loss calculations are mathematically accurate to 2 decimal places
- **SC-003**: Portfolio loads and displays holdings in under 500ms with cached price data
- **SC-004**: System maintains smooth, responsive scrolling when displaying 100+ transactions
- **SC-005**: Holdings recalculation completes in under 100ms for portfolios with 50 holdings and 500 transactions
- **SC-006**: Users can identify profit vs. loss at a glance (green/red color coding clearly visible)
- **SC-007**: Zero calculation errors during stress test (100 transactions with mixed buys/sells, fractional quantities, varying prices)
- **SC-008**: Transaction input form prevents all invalid states (negative values, future dates, overselling)
- **SC-009**: Portfolio values update within 1 second when prices refresh
- **SC-010**: Users can successfully complete full workflow (add transaction → view holding → check history → edit transaction → verify updated P&L) without errors
- **SC-011**: Visual design follows platform standards and passes design review for consistency
- **SC-012**: System maintains efficient resource usage even with large datasets (100 holdings, 1000+ transactions)

## Assumptions

The following assumptions are made for Phase 1 implementation:

- **Single Portfolio**: Phase 1 supports one default portfolio per user (no portfolio creation, naming, or switching UI)
- **Data Model Extensibility**: Transaction and Holding data structures are designed to accommodate future portfolioId field without requiring migration
- **Default Portfolio Behavior**: All transactions implicitly belong to the "default portfolio" in Phase 1; users are unaware of portfolio concept
- **Future Migration Path**: When Phase 2+ adds multi-portfolio support, existing transactions can be associated with a "Default Portfolio" ID without data loss or user disruption
- **Price Source Consistency**: Portfolio uses same price data source and update service as Watchlist (periodic refresh)
- **Local-Only Data**: All portfolio data stored locally only (no cloud sync in Phase 1; Phase 4+ feature)
- **Manual Entry Only**: Users manually enter all transactions (no wallet integration/automatic detection until Phase 2)
- **USD Currency Only**: All prices and values displayed in USD (multi-currency support not in scope)
- **No Tax Calculations**: Portfolio shows investment performance only (no tax reporting, FIFO/LIFO, or cost basis methods)

## Clarifications

### Session 2025-11-18

- Q: When API price fetch fails for portfolio holdings, what should the system display? → A: Show last cached prices with "Last updated X ago" badge, retry in background
- Q: What precision should be used for P&L percentage display? → A: 2 decimal places (e.g., +25.34%)
- Q: What empty state action should be shown for portfolio with no transactions? → A: Single prominent "Add Your First Transaction" button
- Q: When coin search fails due to network error during transaction creation? → A: Allow selection from recently used coins (cached), show error for new searches
- Q: When selling, should owned coins appear first in coin picker? → A: Yes, show coins user owns at top of selection list for Sell transactions

## Future Considerations

While out of scope for Phase 1, the following features are planned for future phases and inform current design decisions:

### Phase 2+: Multiple Portfolio Support

- **Portfolio Management**: Users can create, name, switch between, and delete multiple portfolios
- **Portfolio Settings**: Per-portfolio preferences (default currency, cost basis method)
- **Use Cases**: Separate portfolios for "Long-term Holdings", "Trading", "Family", etc.
- **Data Model**: Transaction model will include portfolioId field to associate transactions with specific portfolios
- **Migration Strategy**: Phase 1 transactions will be auto-associated with a "Default Portfolio" when upgrading

### Phase 2: Wallet Integration

- **Blockchain Monitoring**: Automatically detect transactions from wallet addresses
- **User Approval Workflow**: Review and approve detected transactions before adding to portfolio
- **Supported Networks**: Bitcoin, Ethereum, and major EVM chains initially

### Phase 3+: Advanced Features

- **Charts**: Historical portfolio value over time, individual coin performance graphs
- **Price Alerts**: Notifications when holdings reach target values or P&L thresholds
- **Tax Reporting**: Export cost basis reports, FIFO/LIFO calculations

### Phase 4+: Cloud & Sharing

- **iCloud Sync**: Multi-device portfolio synchronization
- **Export**: CSV, PDF portfolio reports
- **Backup/Restore**: Cloud backup of transaction history

**Design Impact**: The current single-portfolio implementation is intentionally designed to extend cleanly to multi-portfolio without breaking changes or requiring data migration.
