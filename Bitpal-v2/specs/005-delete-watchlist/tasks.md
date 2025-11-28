# Tasks: Delete Watchlist

**Input**: Design documents from `/specs/005-delete-watchlist/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are OPTIONAL for this feature as it involves UI changes only (no financial calculations).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

**Architecture**: Per Constitution Principle III (MVVM + Modern Swift Patterns):
- ViewModels MUST use @Observable (NOT ObservableObject)
- Views MUST be stateless (no business logic)
- Services use singleton pattern
- Swift Data for persistence (NOT Core Data)
- async/await concurrency (NOT Combine)
- NO external dependencies

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup

**Purpose**: No setup required - using existing project infrastructure

*No tasks - existing watchlist infrastructure is already in place.*

---

## Phase 2: Foundational

**Purpose**: No foundational tasks required - all dependencies exist

*No tasks - WatchlistViewModel.removeCoin() and WatchlistItem model already implemented.*

---

## Phase 3: User Story 1 - Remove Individual Coin from Watchlist (Priority: P1) 🎯 MVP

**Goal**: Enable users to delete coins from watchlist via long-press context menu

**Independent Test**: Long-press a coin row → tap Delete → coin disappears and stays deleted after app restart

### Implementation for User Story 1

- [x] T001 [US1] Replace `.swipeActions` with `.contextMenu` modifier in `Bitpal/Features/Watchlist/Views/WatchlistView.swift:43-51`

**Checkpoint**: User Story 1 complete - users can now delete coins via long-press context menu

---

## Phase 4: User Story 2 - Cancel Delete Action (Priority: P2)

**Goal**: Allow users to dismiss the context menu without deleting

**Independent Test**: Long-press a coin row → tap outside menu → menu dismisses, coin remains

### Implementation for User Story 2

*No tasks - native SwiftUI `.contextMenu` behavior handles dismissal automatically when user taps outside*

**Checkpoint**: User Story 2 complete - built-in SwiftUI behavior

---

## Phase 5: User Story 3 - Visual Feedback During Deletion (Priority: P3)

**Goal**: Smooth animation when coin is deleted

**Independent Test**: Delete a coin → observe smooth row removal and list reflow animation

### Implementation for User Story 3

- [x] T002 [US3] Verify `withAnimation(.spring(response: 0.3, dampingFraction: 0.7))` is applied in context menu delete action in `Bitpal/Features/Watchlist/Views/WatchlistView.swift`

**Checkpoint**: User Story 3 complete - deletion has smooth spring animation

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and edge case handling

- [x] T003 Build and run app to verify context menu appears on long-press
- [ ] T004 Test deletion persists after app restart
- [ ] T005 Test empty state appears when last coin is deleted
- [ ] T006 Verify 60fps animation performance with Xcode Instruments (Constitution Principle I)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No tasks
- **Foundational (Phase 2)**: No tasks
- **User Story 1 (Phase 3)**: T001 - Core implementation
- **User Story 2 (Phase 4)**: No tasks (native behavior)
- **User Story 3 (Phase 5)**: T002 - Verify animation
- **Polish (Phase 6)**: T003-T006 - Testing and verification

### User Story Dependencies

- **User Story 1 (P1)**: Independent - core functionality
- **User Story 2 (P2)**: Depends on US1 (context menu must exist to dismiss)
- **User Story 3 (P3)**: Depends on US1 (deletion must work to animate)

### Parallel Opportunities

- T003, T004, T005, T006 can run in parallel after T001 and T002 complete

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001: Replace `.swipeActions` with `.contextMenu`
2. **STOP and VALIDATE**: Test long-press deletion works
3. Ready for use

### Full Implementation

1. T001 → Core deletion via context menu
2. T002 → Verify animation is applied
3. T003-T006 → Testing and polish

---

## Notes

- This is a minimal change - single file modification
- ViewModel logic (`removeCoin()`) already works correctly
- Animation code already exists, just needs correct container
- No new files required
- Constitution compliance already verified in plan.md
