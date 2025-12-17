# Tasks: Widget Background Refresh

**Input**: Design documents from `/specs/008-widget-background-refresh/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for critical business logic.

**Tests REQUIRED** (must write BEFORE implementation):
- P&L recalculation logic (critical financial calculations)
- API response parsing and error handling
- Decimal precision preservation

**Tests OPTIONAL** (manual testing acceptable):
- SwiftUI widget views (visual review)
- Simple getters/setters

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Architecture**: Per Constitution Principle III (MVVM + Modern Swift Patterns):
- Widget uses TimelineProvider (not ViewModel)
- Services use static methods (WidgetAPIClient)
- App Group JSON for widget sharing
- async/await concurrency
- NO external dependencies

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Main App**: `Bitpal/`
- **Shared Code**: `Bitpal/Shared/`
- **Widget Extension**: `BitpalWidget/`
- **Tests**: `BitpalTests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new data model for widget refresh data

- [x] T001 [P] Create WidgetRefreshData model with RefreshableHolding nested struct in Bitpal/Shared/Models/WidgetRefreshData.swift
- [x] T002 [P] Add refresh data read/write methods to Bitpal/Shared/Services/AppGroupStorage.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Enable main app to write refresh data that widget can use

**⚠️ CRITICAL**: Widget cannot fetch fresh prices until main app writes refresh data

- [x] T003 Modify WidgetDataProvider to write WidgetRefreshData when portfolio updates in Bitpal/Features/Widget/WidgetDataProvider.swift
- [x] T004 Create lightweight WidgetAPIClient for fetching prices in BitpalWidget/Services/WidgetAPIClient.swift

**Checkpoint**: Foundation ready - widget can now read quantities and fetch prices

---

## Phase 3: User Story 1 - Widget Shows Fresh Prices Without Opening App (Priority: P1) 🎯 MVP

**Goal**: Widget fetches fresh prices from CoinGecko API and recalculates P&L without requiring main app to be opened

**Independent Test**: Add widget to home screen, wait 15+ minutes without opening app, verify prices update (check lastUpdated timestamp)

### Tests for User Story 1 (REQUIRED - financial calculations)

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T005 [P] [US1] Write P&L recalculation test with mock prices in BitpalTests/WidgetTests/WidgetRefreshTests.swift
- [x] T006 [P] [US1] Write decimal precision preservation test in BitpalTests/WidgetTests/WidgetRefreshTests.swift
- [x] T007 [P] [US1] Write missing price handling test (when API returns partial data) in BitpalTests/WidgetTests/WidgetRefreshTests.swift

### Implementation for User Story 1

- [x] T008 [US1] Implement P&L recalculation logic in BitpalWidget/Helpers/PortfolioRecalculator.swift
- [x] T009 [US1] Modify PortfolioTimelineProvider.getTimeline() to read refresh data in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T010 [US1] Add API price fetching to PortfolioTimelineProvider.getTimeline() in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T011 [US1] Implement recalculation and write updated WidgetPortfolioData in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T012 [US1] Change timeline policy to .after(15 minutes) with single entry in BitpalWidget/Provider/PortfolioTimelineProvider.swift

**Checkpoint**: Widget now fetches fresh prices and displays updated P&L without opening main app

---

## Phase 4: User Story 2 - Graceful Fallback on Network Failure (Priority: P2)

**Goal**: Widget displays cached data with staleness indicator when network is unavailable

**Independent Test**: Enable airplane mode, wait for widget refresh, verify cached data displays with staleness indicator when data is >60 minutes old

### Tests for User Story 2 (REQUIRED - error handling)

- [x] T013 [P] [US2] Write network failure fallback test in BitpalTests/WidgetTests/WidgetRefreshTests.swift
- [x] T014 [P] [US2] Write staleness detection test (data >60 minutes old) in BitpalTests/WidgetTests/WidgetRefreshTests.swift

### Implementation for User Story 2

- [x] T015 [US2] Add try/catch with cached data fallback in PortfolioTimelineProvider.getTimeline() in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T016 [US2] Add staleness calculation to entry (compare lastUpdated to current time) in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T017 [US2] Update widget view to show staleness indicator when data >60 minutes old in BitpalWidget/Views/PortfolioWidgetView.swift

**Checkpoint**: Widget gracefully handles network failures and shows staleness indicator

---

## Phase 5: User Story 3 - Empty State for Users Without Holdings (Priority: P3)

**Goal**: New users with no holdings see helpful empty state instead of blank widget

**Independent Test**: Add widget when user has no portfolio transactions, verify appropriate empty state message

### Implementation for User Story 3

- [x] T018 [US3] Handle nil/empty refresh data in PortfolioTimelineProvider.getTimeline() in BitpalWidget/Provider/PortfolioTimelineProvider.swift
- [x] T019 [US3] Update empty state view with "Add holdings in app" message in BitpalWidget/Views/PortfolioWidgetView.swift

**Checkpoint**: All user stories complete - widget handles all states gracefully

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup

- [x] T020 Run all unit tests and verify 100% pass rate
- [ ] T021 Manual test: Add widget, verify fresh prices after 15+ minutes without opening app
- [ ] T022 Manual test: Enable airplane mode, verify cached fallback with staleness indicator
- [ ] T023 Manual test: Remove all holdings, verify empty state message
- [ ] T024 Run quickstart.md validation scenarios

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001, T002)
- **User Story 1 (Phase 3)**: Depends on Foundational (T003, T004)
- **User Story 2 (Phase 4)**: Depends on User Story 1 (T008-T012)
- **User Story 3 (Phase 5)**: Can start after Foundational, but logically follows US2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Core functionality - MUST complete before US2/US3
- **User Story 2 (P2)**: Builds on US1 (adds error handling to the same code)
- **User Story 3 (P3)**: Independent but shares code paths with US1/US2

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Core logic before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Phase 1 (Setup)**:
```
Parallel: T001, T002 (different files)
```

**Phase 3 (User Story 1 Tests)**:
```
Parallel: T005, T006, T007 (same test file but different test cases)
```

**Phase 4 (User Story 2 Tests)**:
```
Parallel: T013, T014 (same test file but different test cases)
```

---

## Parallel Example: User Story 1 Tests

```bash
# Launch all tests for User Story 1 together:
Task: "P&L recalculation test in BitpalTests/WidgetTests/WidgetRefreshTests.swift"
Task: "Decimal precision test in BitpalTests/WidgetTests/WidgetRefreshTests.swift"
Task: "Missing price handling test in BitpalTests/WidgetTests/WidgetRefreshTests.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T002)
2. Complete Phase 2: Foundational (T003-T004)
3. Complete Phase 3: User Story 1 (T005-T012)
4. **STOP and VALIDATE**: Test widget shows fresh prices
5. Deploy/demo if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → MVP complete!
3. Add User Story 2 → Test network failure handling → Enhanced reliability
4. Add User Story 3 → Test empty state → Complete feature

### Sequential Implementation (Recommended for This Feature)

This feature is best implemented sequentially due to code dependencies:

1. T001-T002: Setup (parallel)
2. T003-T004: Foundational (sequential - T003 before T004)
3. T005-T007: US1 Tests (parallel)
4. T008-T012: US1 Implementation (sequential)
5. T013-T014: US2 Tests (parallel)
6. T015-T017: US2 Implementation (sequential)
7. T018-T019: US3 Implementation (sequential)
8. T020-T024: Polish (sequential)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- P&L calculations MUST be tested before implementation (Constitution Principle IV)
- Widget uses WidgetKit TimelineProvider pattern (not MVVM ViewModels)
- All financial values use Decimal type for precision
- Never show blank widget - always fall back to cached data
- 15-minute refresh interval requested (iOS may adjust based on system conditions)
