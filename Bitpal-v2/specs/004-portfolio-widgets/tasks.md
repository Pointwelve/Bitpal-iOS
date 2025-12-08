# Tasks: iOS Home Screen Widgets for Portfolio

**Input**: Design documents from `/specs/004-portfolio-widgets/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for:
- Widget data transformation (prepareWidgetData function)
- App Group storage read/write
- Shared calculation consistency

**Tests OPTIONAL** (manual testing acceptable):
- SwiftUI widget views (visual review)
- Widget preview rendering
- Deep linking navigation

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each widget size.

**Architecture**: Per Constitution Principle III (MVVM + Modern Swift Patterns):
- Widget uses TimelineProvider (WidgetKit pattern)
- Views are stateless SwiftUI
- Data sharing via App Groups (JSON file)
- async/await concurrency
- NO external dependencies

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1=Small, US2=Medium, US3=Large)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Widget Extension Infrastructure) ✅ COMPLETE

**Purpose**: Project initialization - Add widget extension target and App Groups capability

- [x] T001 Add Widget Extension target "BitpalWidget" to Xcode project via File → New → Target → Widget Extension
- [x] T002 Enable App Groups capability in Bitpal target with identifier `group.com.bitpal.shared`
- [x] T003 Enable App Groups capability in BitpalWidget target with identifier `group.com.bitpal.shared`
- [x] T004 [P] Create directory structure: `Bitpal/Shared/Models/`, `Bitpal/Shared/Services/`
- [x] T005 [P] Create directory structure: `BitpalWidget/Provider/`, `BitpalWidget/Views/`, `BitpalWidget/Entry/`
- [x] T006 Add `.widget` category to Logger in `Bitpal/Utilities/Logger.swift`

---

## Phase 2: Foundational (Shared Data Layer) ✅ COMPLETE

**Purpose**: Core infrastructure that MUST be complete before ANY widget view can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational Phase (REQUIRED per Constitution Principle IV)

- [x] T007 [P] Create WidgetDataProviderTests in `BitpalTests/WidgetTests/WidgetDataProviderTests.swift` - Test prepareWidgetData transformation
- [x] T008 [P] Create AppGroupStorageTests in `BitpalTests/WidgetTests/AppGroupStorageTests.swift` - Test JSON read/write to App Group

### Shared Models

- [x] T009 [P] Create WidgetPortfolioData model in `Bitpal/Shared/Models/WidgetPortfolioData.swift` with Codable conformance
- [x] T010 [P] Create WidgetHolding model in `Bitpal/Shared/Models/WidgetHolding.swift` with Codable conformance
- [x] T011 Create sample data extensions in `Bitpal/Shared/Models/WidgetPortfolioData+Sample.swift` for widget previews

### Shared Services

- [x] T012 Create AppGroupStorage service in `Bitpal/Shared/Services/AppGroupStorage.swift` with read/write methods for portfolio.json
- [x] T013 Create prepareWidgetData function in `Bitpal/Shared/Services/WidgetDataTransformer.swift` to transform PortfolioSummary + Holdings → WidgetPortfolioData

### Main App Integration

- [x] T014 Create WidgetDataProvider in `Bitpal/Features/Widget/WidgetDataProvider.swift` to orchestrate data persistence
- [x] T015 Update PortfolioViewModel in `Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift` to call WidgetDataProvider.updateWidgetData() after portfolio load
- [x] T016 Add WidgetCenter.shared.reloadAllTimelines() call in PortfolioViewModel after transaction changes

### Widget Extension Foundation

- [x] T017 Create PortfolioEntry timeline entry in `BitpalWidget/Entry/PortfolioEntry.swift` conforming to TimelineEntry
- [x] T018 Create PortfolioTimelineProvider in `BitpalWidget/Provider/PortfolioTimelineProvider.swift` with placeholder, snapshot, and timeline methods
- [x] T019 Create BitpalWidgetBundle in `BitpalWidget/BitpalWidgetBundle.swift` as widget bundle entry point
- [x] T020 Create BitpalWidget configuration in `BitpalWidget/BitpalWidget.swift` with supportedFamilies [.systemSmall, .systemMedium, .systemLarge]

**Checkpoint**: Foundation ready - Widget extension can now render placeholder, individual widget views can be implemented

---

## Phase 3: User Story 1 - Quick Portfolio Check (Priority: P1) 🎯 MVP ✅ COMPLETE

**Goal**: Small widget displaying total portfolio value and P&L with color coding

**Independent Test**: Add small widget to home screen, verify portfolio value and P&L display with green/red colors, tap opens Portfolio tab

### Implementation for User Story 1

- [x] T021 [US1] Create SmallWidgetView in `BitpalWidget/Views/SmallWidgetView.swift` displaying totalValue, totalPnL with color, lastUpdated timestamp
- [x] T022 [US1] Add empty state to SmallWidgetView showing "Add holdings" message when data.isEmpty
- [x] T023 [US1] Add P&L color coding to SmallWidgetView (green for positive, red for negative per FR-009)
- [x] T024 [US1] Add containerBackground modifier with Liquid Glass styling per Constitution Principle II
- [x] T025 [US1] Add deep link URL "bitpal://portfolio" to SmallWidgetView Link wrapper per FR-010
- [x] T026 [US1] Add URL handling in BitpalApp.swift using .onOpenURL to navigate to Portfolio tab
- [x] T027 [US1] Update BitpalWidget.swift to render SmallWidgetView for .systemSmall family
- [x] T028 [US1] Add SwiftUI Preview for SmallWidgetView with sample data and empty state

**Checkpoint**: Small widget fully functional - User Story 1 independently testable (MVP Complete!)

---

## Phase 4: User Story 2 - Top Holdings Overview (Priority: P2) ✅ COMPLETE

**Goal**: Medium widget displaying portfolio value, P&L breakdown (unrealized/realized), and top 2 holdings

**Independent Test**: Add medium widget to home screen, verify total value, both P&L types, and top 2 holdings with individual P&L display

### Implementation for User Story 2

- [x] T029 [P] [US2] Create HoldingRowView in `BitpalWidget/Views/Components/HoldingRowView.swift` for displaying single holding with name, value, P&L
- [x] T030 [US2] Create MediumWidgetView in `BitpalWidget/Views/MediumWidgetView.swift` displaying totalValue, unrealizedPnL, realizedPnL, top 2 holdings
- [x] T031 [US2] Add P&L breakdown section to MediumWidgetView showing unrealized and realized P&L separately
- [x] T032 [US2] Add holdings list to MediumWidgetView using HoldingRowView (limit 2 holdings per FR-002)
- [x] T033 [US2] Add empty state to MediumWidgetView with graceful handling for 0-1 holdings
- [x] T034 [US2] Add containerBackground and deep link to MediumWidgetView matching SmallWidgetView styling
- [x] T035 [US2] Update BitpalWidget.swift to render MediumWidgetView for .systemMedium family
- [x] T036 [US2] Add SwiftUI Preview for MediumWidgetView with various holding counts (0, 1, 2, 3+)

**Checkpoint**: Medium widget fully functional - User Stories 1 AND 2 independently testable

---

## Phase 5: User Story 3 - Detailed Holdings View (Priority: P3) ✅ COMPLETE

**Goal**: Large widget displaying full P&L breakdown and top 5 holdings with comprehensive details

**Independent Test**: Add large widget to home screen, verify total value, all P&L types, and top 5 holdings with symbol, name, value, P&L amount, P&L percentage

### Implementation for User Story 3

- [x] T037 [US3] Create LargeWidgetView in `BitpalWidget/Views/LargeWidgetView.swift` displaying totalValue, unrealizedPnL, realizedPnL, totalPnL, top 5 holdings
- [x] T038 [US3] Add full P&L breakdown section to LargeWidgetView (unrealized, realized, total)
- [x] T039 [US3] Add holdings list to LargeWidgetView using HoldingRowView with extended details (limit 5 holdings per FR-003)
- [x] T040 [US3] Ensure holdings display symbol, name, currentValue, pnlAmount, pnlPercentage per FR-003
- [x] T041 [US3] Add empty state to LargeWidgetView with graceful handling for <5 holdings (no empty rows per Acceptance Scenario 3)
- [x] T042 [US3] Add containerBackground and deep link to LargeWidgetView matching other widget styling
- [x] T043 [US3] Update BitpalWidget.swift to render LargeWidgetView for .systemLarge family
- [x] T044 [US3] Add SwiftUI Preview for LargeWidgetView with various holding counts (0, 1, 3, 5, 6+)

**Checkpoint**: All three widget sizes fully functional - All user stories independently testable

---

## Phase 6: Polish & Cross-Cutting Concerns ✅ COMPLETE

**Purpose**: Error handling, edge cases, and refinements that affect all widget sizes

### Error Handling & Edge Cases

- [x] T045 [P] Add offline/stale indicator to all widget views when lastUpdated > 60 minutes (per FR-016)
- [x] T046 [P] Add "Updated X min ago" relative timestamp formatting to all widget views
- [x] T047 Verify all widgets show cached data when API unavailable (per FR-015 - blank widgets forbidden)
- [x] T048 Test widget behavior when user has only closed positions (realizedPnL > 0 but no holdings)

### Light/Dark Mode & Design

- [x] T049 [P] Verify all widgets support Light and Dark mode automatically (per FR-013)
- [x] T050 [P] Verify Liquid Glass design consistency across all widget sizes (per FR-012)
- [x] T051 [P] Test Dynamic Type scaling on all widget text elements

### Performance & Memory

- [x] T052 Verify widget extension memory usage stays under 30MB (per FR-008, SC-007)
- [x] T053 Verify 30-minute timeline refresh policy is set correctly (per FR-004, SC-002)
- [x] T054 Test widget render time is under 1 second (per SC-001)

### Final Validation

- [x] T055 Run all WidgetTests and verify passing
- [x] T056 Manual test: Add all 3 widget sizes to home screen, verify display
- [x] T057 Manual test: Tap each widget size, verify opens Portfolio tab (per SC-003)
- [x] T058 Manual test: Compare widget P&L values with main app values (per SC-004)
- [x] T059 Manual test: Test on multiple device sizes (iPhone SE, iPhone 15, iPhone 15 Pro Max)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - US1 (Small Widget): Can start after Foundational
  - US2 (Medium Widget): Can start after T029 (HoldingRowView) - Can run parallel with US1
  - US3 (Large Widget): Can start after T029 (HoldingRowView) - Can run parallel with US1/US2
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories - Small widget is standalone
- **User Story 2 (P2)**: Depends on T029 (HoldingRowView component) - Otherwise independent
- **User Story 3 (P3)**: Depends on T029 (HoldingRowView component) - Otherwise independent

### Within Each User Story

- Widget view before preview
- Core display before empty state
- Styling before integration
- Integration before testing

### Parallel Opportunities

- T004, T005 can run in parallel (directory creation)
- T007, T008 can run in parallel (different test files)
- T009, T010 can run in parallel (different model files)
- T029 (HoldingRowView) can run parallel with T021-T028 (US1)
- Once T029 complete, US2 and US3 can run in parallel
- All Phase 6 tasks marked [P] can run in parallel

---

## Parallel Example: User Stories 2 and 3 Together

```bash
# After T029 (HoldingRowView) is complete:

# Developer A: User Story 2
Task: T030 "Create MediumWidgetView in BitpalWidget/Views/MediumWidgetView.swift"
Task: T031 "Add P&L breakdown section to MediumWidgetView"
Task: T032 "Add holdings list to MediumWidgetView"

# Developer B: User Story 3 (parallel)
Task: T037 "Create LargeWidgetView in BitpalWidget/Views/LargeWidgetView.swift"
Task: T038 "Add full P&L breakdown section to LargeWidgetView"
Task: T039 "Add holdings list to LargeWidgetView"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T020)
3. Complete Phase 3: User Story 1 (T021-T028)
4. **STOP and VALIDATE**: Test small widget independently
5. Deploy to TestFlight if ready

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 (Small Widget) → Test → Deploy (MVP!)
3. Add User Story 2 (Medium Widget) → Test → Deploy
4. Add User Story 3 (Large Widget) → Test → Deploy
5. Polish phase → Final release

### Estimated Task Counts

| Phase | Tasks | Parallelizable |
|-------|-------|----------------|
| Phase 1: Setup | 6 | 2 |
| Phase 2: Foundational | 14 | 4 |
| Phase 3: US1 (Small) | 8 | 0 |
| Phase 4: US2 (Medium) | 8 | 1 |
| Phase 5: US3 (Large) | 8 | 0 |
| Phase 6: Polish | 15 | 5 |
| **TOTAL** | **59** | **12** |

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label: US1=Small Widget, US2=Medium Widget, US3=Large Widget
- Each widget size is independently completable and testable
- Small widget (US1) is MVP - can ship without US2/US3
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Widget extension requires physical device or simulator for full testing
