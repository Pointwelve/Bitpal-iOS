# Tasks: Manual Portfolio

**Feature**: 002-portfolio
**Generated**: 2025-11-18
**Source**: spec.md, plan.md, data-model.md

---

## Phase 1: Setup

Project initialization and configuration.

**Goal**: Prepare project structure and enable Portfolio feature in app.

- [ ] T001 Create Portfolio feature directory structure at Bitpal/Features/Portfolio/Models/, Bitpal/Features/Portfolio/Views/, Bitpal/Features/Portfolio/ViewModels/
- [ ] T002 Create PortfolioTests directory at BitpalTests/PortfolioTests/
- [ ] T003 Update BitpalApp.swift to add Transaction.self to modelContainer array in Bitpal/App/BitpalApp.swift
- [ ] T004 Enable Portfolio tab in ContentView.swift by adding PortfolioView() tab item in Bitpal/App/ContentView.swift

---

## Phase 2: Foundational

Core models and calculation logic that all user stories depend on.

**Goal**: Establish data models and calculation infrastructure.

### Models

- [ ] T005 [P] Create TransactionType enum with buy/sell cases and displayName computed property in Bitpal/Features/Portfolio/Models/TransactionType.swift
- [ ] T006 [P] Create PortfolioError enum with all error cases and LocalizedError conformance in Bitpal/Features/Portfolio/Models/PortfolioError.swift
- [ ] T007 Create Transaction @Model class with all properties (id, coinId, type, amount, pricePerCoin, date, notes) using Decimal types in Bitpal/Features/Portfolio/Models/Transaction.swift
- [ ] T008 Create Holding struct with stored properties (id, coin, totalAmount, avgCost, currentValue) and computed properties (profitLoss, profitLossPercentage) in Bitpal/Features/Portfolio/Models/Holding.swift

### Unit Tests (BEFORE implementation per Constitution Principle IV)

- [ ] T009 [P] Create HoldingCalculationTests with tests for weighted average cost calculation in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T010 [P] Add test for profit calculation (currentValue > totalCost) in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T011 [P] Add test for loss calculation (currentValue < totalCost) in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T012 [P] Add test for P&L percentage accuracy to 2 decimal places in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T013 [P] Add test for mixed buy/sell transactions computing correct remaining quantity in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T014 [P] Add test for zero holdings when all sold (should return nil) in BitpalTests/PortfolioTests/HoldingCalculationTests.swift
- [ ] T015 [P] Add test for fractional quantities (0.00000001 BTC) in BitpalTests/PortfolioTests/HoldingCalculationTests.swift

### Calculation Logic

- [ ] T016 Implement computeHoldings function that groups transactions by coinId and calculates holdings in Bitpal/Features/Portfolio/Models/Holding.swift

---

## Phase 3: User Story 1 - Add Buy/Sell Transactions (P1)

**Goal**: Users can record cryptocurrency purchases and sales with validation.

**Independent Test**: Transaction input form with validation, data persistence verification.

**Acceptance Criteria**:
- Transaction sheet appears with all required fields
- Validation prevents invalid data (negative qty, zero price, future date)
- Transaction persists after app restart

### Tests

- [ ] T017 [P] [US1] Create TransactionModelTests with test for transaction creation and persistence in BitpalTests/PortfolioTests/TransactionModelTests.swift
- [ ] T018 [P] [US1] Add validation tests for amount > 0, price > 0, date <= today in BitpalTests/PortfolioTests/TransactionModelTests.swift
- [ ] T019 [P] [US1] Create AddTransactionViewModelTests with test for form validation logic in BitpalTests/PortfolioTests/AddTransactionViewModelTests.swift
- [ ] T020 [P] [US1] Add test for insufficient balance check on sell transactions in BitpalTests/PortfolioTests/AddTransactionViewModelTests.swift

### ViewModel

- [ ] T021 [US1] Create AddTransactionViewModel with @Observable macro, form state (selectedCoin, transactionType, amount, pricePerCoin, date, notes), validation methods, and save action in Bitpal/Features/Portfolio/ViewModels/AddTransactionViewModel.swift

### Views

- [ ] T022 [US1] Create AddTransactionView sheet with coin picker, transaction type segmented control, amount TextField, price TextField, date picker, notes TextField, and Save button in Bitpal/Features/Portfolio/Views/AddTransactionView.swift
- [ ] T023 [US1] Add form validation display showing inline error messages for invalid fields in Bitpal/Features/Portfolio/Views/AddTransactionView.swift
- [ ] T024 [US1] Implement coin search/selection using existing CoinSearchView pattern with owned coins appearing first for sell type (FR-029) in Bitpal/Features/Portfolio/Views/AddTransactionView.swift

---

## Phase 4: User Story 2 - View Holdings with P&L (P2)

**Goal**: Users see computed holdings with accurate profit/loss calculations.

**Independent Test**: Create sample transactions, verify holdings display with correct P&L calculations using mock prices.

**Acceptance Criteria**:
- Holdings show coin, quantity, avg cost, current value, P&L
- Green color for profit, red for loss
- Zero holdings hidden from list
- Values update when prices refresh

### Tests

- [ ] T025 [P] [US2] Create PortfolioViewModelTests with test for loadPortfolioWithPrices fetching transactions and computing holdings in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift
- [ ] T026 [P] [US2] Add test for holdings array excluding coins with zero total quantity in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift
- [ ] T027 [P] [US2] Add test for price update triggering holdings recalculation in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift

### ViewModel

- [ ] T028 [US2] Create PortfolioViewModel with @Observable macro, holdings array, isLoading, errorMessage, lastUpdateTime state in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift
- [ ] T029 [US2] Implement loadPortfolioWithPrices method fetching transactions from Swift Data, computing holdings, fetching prices from CoinGeckoService in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift
- [ ] T030 [US2] Add startPeriodicUpdates and stopPeriodicUpdates methods using PriceUpdateService pattern in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift

### Views

- [ ] T031 [US2] Create HoldingRowView with LiquidGlassCard showing coin name/symbol, quantity, avg cost, current value, P&L amount, P&L percentage with color coding in Bitpal/Features/Portfolio/Views/HoldingRowView.swift
- [ ] T032 [US2] Add Equatable conformance to HoldingRowView for performance optimization in Bitpal/Features/Portfolio/Views/HoldingRowView.swift
- [ ] T033 [US2] Create PortfolioView with NavigationStack, LazyVStack for holdings list, add transaction button, pull-to-refresh in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [ ] T034 [US2] Connect PortfolioView to PortfolioViewModel with .task modifier for loading and .onDisappear for cleanup in Bitpal/Features/Portfolio/Views/PortfolioView.swift

---

## Phase 5: User Story 3 - View Portfolio Summary (P3)

**Goal**: Users see total portfolio value and overall P&L at top of screen.

**Independent Test**: Add multiple holdings, verify summary totals computed correctly.

**Acceptance Criteria**:
- Summary card shows total value, total P&L, P&L percentage
- Green/red color coding for profit/loss
- Empty state shows $0 and "Add Your First Transaction" button (FR-027)
- Smooth animation on price updates

### Tests

- [ ] T035 [P] [US3] Add test for totalValue computed property summing all holdings in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift
- [ ] T036 [P] [US3] Add test for totalProfitLoss computed property in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift
- [ ] T037 [P] [US3] Add test for totalProfitLossPercentage computed property in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift

### ViewModel

- [ ] T038 [US3] Add totalValue, totalProfitLoss, totalProfitLossPercentage computed properties to PortfolioViewModel in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift
- [ ] T039 [US3] Add isEmpty computed property for empty state detection in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift

### Views

- [ ] T040 [US3] Create PortfolioSummaryCard view with LiquidGlassCard showing total value, P&L amount, P&L percentage with prominent typography in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [ ] T041 [US3] Add empty state view with message and "Add Your First Transaction" button in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [ ] T042 [US3] Add smooth spring animation for summary value updates in Bitpal/Features/Portfolio/Views/PortfolioView.swift

---

## Phase 6: User Story 4 - View Transaction History (P4)

**Goal**: Users can view complete transaction history for each holding.

**Independent Test**: Add transactions for a coin, verify history displays correctly ordered by date.

**Acceptance Criteria**:
- Transaction list shows type, quantity, price, date, notes
- Ordered by date (newest first)
- Buy/Sell visual distinction (green/red accent)
- Notes display below transaction details

### Views

- [ ] T043 [US4] Create TransactionHistoryView as NavigationLink destination showing all transactions for a coinId in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift
- [ ] T044 [US4] Create TransactionRowView with type indicator (green buy/red sell), quantity, price, date, optional notes in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift
- [ ] T045 [US4] Add @Query with filter for coinId and sort by date descending in TransactionHistoryView in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift
- [ ] T046 [US4] Add NavigationLink from HoldingRowView to TransactionHistoryView passing coinId in Bitpal/Features/Portfolio/Views/HoldingRowView.swift

---

## Phase 7: User Story 5 - Edit and Delete Transactions (P5)

**Goal**: Users can correct mistakes or remove transactions.

**Independent Test**: Modify/delete transactions, verify holdings recalculate correctly.

**Acceptance Criteria**:
- Tap transaction opens edit sheet with prepopulated data
- Edit saves and recalculates holdings
- Swipe to delete with confirmation alert
- Delete removes permanently and recalculates holdings

### Tests

- [ ] T047 [P] [US5] Add test for transaction edit updating Swift Data and triggering recalculation in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift
- [ ] T048 [P] [US5] Add test for transaction delete removing from Swift Data and triggering recalculation in BitpalTests/PortfolioTests/PortfolioViewModelTests.swift

### ViewModel

- [ ] T049 [US5] Add editTransaction method to AddTransactionViewModel for prepopulating form with existing transaction in Bitpal/Features/Portfolio/ViewModels/AddTransactionViewModel.swift
- [ ] T050 [US5] Add updateTransaction method to PortfolioViewModel for saving edited transaction in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift
- [ ] T051 [US5] Add deleteTransaction method to PortfolioViewModel with confirmation handling in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift

### Views

- [ ] T052 [US5] Add tap gesture to TransactionRowView to open edit sheet with prepopulated AddTransactionView in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift
- [ ] T053 [US5] Add swipe-to-delete action on TransactionRowView with .destructive button in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift
- [ ] T054 [US5] Add delete confirmation alert with message "Delete this transaction? This will affect your holdings." in Bitpal/Features/Portfolio/Views/TransactionHistoryView.swift

---

## Phase 8: Polish & Cross-Cutting Concerns

Final integration, error handling, and performance optimization.

**Goal**: Ensure feature is production-ready with proper error handling and performance.

### Error Handling

- [ ] T055 Show "Last updated X ago" badge when price data is stale (FR-024) in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [ ] T056 Handle network errors in coin search with cached coin fallback (FR-028) in Bitpal/Features/Portfolio/Views/AddTransactionView.swift
- [ ] T057 Add error alert display for PortfolioError cases in PortfolioView in Bitpal/Features/Portfolio/Views/PortfolioView.swift

### Performance Optimization

- [ ] T058 Ensure LazyVStack usage for holdings list in PortfolioView in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [ ] T059 Profile with Instruments to verify 60fps scrolling and <500ms load time
- [ ] T060 Verify holdings calculation completes in <100ms for 50 holdings with 500 transactions

### Final Verification

- [ ] T061 Run all unit tests and verify passing
- [ ] T062 Complete manual testing of full workflow: add transaction → view holding → check history → edit transaction → verify P&L
- [ ] T063 Verify visual design follows Liquid Glass design system and iOS 26 HIG

---

## Dependencies

### Story Completion Order

```
Phase 2 (Foundational) ─────┬──▶ US1 (P1) ──▶ US2 (P2) ──▶ US3 (P3)
                            │                    │
                            │                    └──▶ US4 (P4)
                            │                              │
                            └──────────────────────────────└──▶ US5 (P5)
```

**Notes**:
- US1 required before US2 (need transactions to compute holdings)
- US2 required before US3 (summary computed from holdings)
- US2 required before US4 (history accessed from holding row)
- US4 required before US5 (edit/delete accessed from history)

### Parallel Opportunities Per Story

**Phase 2 (Foundational)**:
- T005 + T006 can run in parallel (independent enums)
- T009-T015 can all run in parallel (independent test files)

**US1**:
- T017-T020 can all run in parallel (independent test files)

**US2**:
- T025-T027 can all run in parallel (test cases in same file but independent)
- T031 + T032 can run in parallel with T028-T030

**US3**:
- T035-T037 can all run in parallel (independent test cases)

**US4**:
- T043-T045 can run in parallel with T046

**US5**:
- T047 + T048 can run in parallel (independent test cases)
- T052 + T053 can run in parallel (independent view modifications)

---

## Implementation Strategy

### MVP Scope

**Recommended MVP**: Complete through User Story 2 (Phase 4)

This delivers:
- ✅ Transaction entry (US1)
- ✅ Holdings display with P&L (US2)
- Core value proposition is functional

Can ship and iterate on:
- Summary card (US3)
- Transaction history (US4)
- Edit/delete (US5)

### Incremental Delivery

1. **Sprint 1**: Phase 1-3 (Setup + Foundational + US1)
   - Project structure
   - Models and tests
   - Transaction entry
   - **Deliverable**: Users can add transactions

2. **Sprint 2**: Phase 4 (US2)
   - Holdings calculation
   - Portfolio view
   - **Deliverable**: Users can see holdings with P&L

3. **Sprint 3**: Phase 5-6 (US3 + US4)
   - Summary card
   - Transaction history
   - **Deliverable**: Complete viewing experience

4. **Sprint 4**: Phase 7-8 (US5 + Polish)
   - Edit/delete
   - Error handling
   - Performance optimization
   - **Deliverable**: Production-ready feature

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 63 |
| **Setup Tasks** | 4 |
| **Foundational Tasks** | 12 |
| **US1 Tasks** | 8 |
| **US2 Tasks** | 10 |
| **US3 Tasks** | 8 |
| **US4 Tasks** | 4 |
| **US5 Tasks** | 8 |
| **Polish Tasks** | 9 |
| **Parallelizable Tasks** | 25 |

### Independent Test Criteria Per Story

| Story | Test Criteria |
|-------|---------------|
| US1 | Transaction form validation, data persistence |
| US2 | Holdings display, P&L accuracy with mock prices |
| US3 | Summary totals from multiple holdings |
| US4 | History list ordered by date |
| US5 | Edit/delete with recalculation |

### Key Files

**Models** (4 files):
- Transaction.swift
- Holding.swift
- TransactionType.swift
- PortfolioError.swift

**ViewModels** (2 files):
- PortfolioViewModel.swift
- AddTransactionViewModel.swift

**Views** (4 files):
- PortfolioView.swift
- AddTransactionView.swift
- HoldingRowView.swift
- TransactionHistoryView.swift

**Tests** (4 files):
- HoldingCalculationTests.swift
- TransactionModelTests.swift
- AddTransactionViewModelTests.swift
- PortfolioViewModelTests.swift
