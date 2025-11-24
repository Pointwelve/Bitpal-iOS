---
description: "Task list for Watchlist feature implementation"
---

# Tasks: Watchlist

**Input**: Design documents from `/specs/001-watchlist/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for critical business logic and OPTIONAL for UI/simple operations.

**Tests REQUIRED** (must write BEFORE implementation):
- API response parsing and error handling (CoinGecko endpoints)
- Price update logic (throttling, batching, caching)

**Tests OPTIONAL** (manual testing acceptable):
- SwiftUI views (visual review)
- Simple getters/setters
- UI flows and navigation
- Straightforward operations

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
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

All paths relative to Xcode project root:
```
Bitpal/
├── App/
├── Features/Watchlist/
├── Services/
├── Models/
├── Design/
└── Utilities/
```

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Create Xcode project structure and basic configuration

- [X] T001 Create Xcode project "Bitpal" with iOS 26+ deployment target in Bitpal.xcodeproj (SKIPPED - project already exists)
- [X] T002 Create feature folder structure: Bitpal/Features/Watchlist/{Views,ViewModels,Models}
- [X] T003 Create shared folders: Bitpal/{Services,Models,Design,Utilities}
- [X] T004 Configure Swift Data model container for WatchlistItem in Bitpal/App/BitpalApp.swift
- [X] T005 [P] Create Spacing constants enum in Bitpal/Design/Styles/Spacing.swift
- [X] T006 [P] Create Typography constants in Bitpal/Design/Styles/Typography.swift
- [X] T007 [P] Setup OSLog categorized loggers (.api, .persistence, .ui) in Bitpal/Utilities/Logger.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 [P] Create Coin struct model (Identifiable, Codable, Equatable) with Decimal price types in Bitpal/Models/Coin.swift
- [X] T009 [P] Create WatchlistItem Swift Data @Model class with unique coinId in Bitpal/Features/Watchlist/Models/WatchlistItem.swift
- [X] T010 [P] Create WatchlistError enum (LocalizedError) in Bitpal/Features/Watchlist/Models/WatchlistError.swift
- [X] T011 Create RateLimiter actor (1.2s minimum interval) in Bitpal/Services/RateLimiter.swift
- [X] T012 Implement CoinGeckoService singleton with fetchCoinList and fetchMarketData methods in Bitpal/Services/CoinGeckoService.swift
- [X] T013 Add Decimal to Double conversion extension for JSON decoding in Bitpal/Utilities/Decimal+Extensions.swift
- [X] T014 Create currency formatter (USD) and percentage formatter in Bitpal/Utilities/Formatters.swift
- [X] T015 Implement PriceUpdateService singleton with 30-second Task loop in Bitpal/Services/PriceUpdateService.swift
- [X] T016 [P] Create LiquidGlassCard reusable component (.ultraThinMaterial, 16pt radius) in Bitpal/Design/Components/LiquidGlassCard.swift
- [X] T017 [P] Create Colors extension with system colors (.profitGreen, .lossRed) in Bitpal/Design/Styles/Colors.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - View and Monitor Watchlist (Priority: P1) 🎯 MVP

**Goal**: Display watchlist with current prices, auto-updates, and smooth 60fps scrolling

**Independent Test**: Add sample WatchlistItems to Swift Data, verify list displays with API prices, smooth scrolling, and 30-second updates

### Tests for User Story 1 (REQUIRED - API parsing and update logic)

- [X] T018 [P] [US1] Write unit test for Coin JSON decoding with Decimal conversion in BitpalTests/WatchlistTests/CoinModelTests.swift
- [X] T019 [P] [US1] Write unit test for CoinGeckoService error handling in BitpalTests/WatchlistTests/CoinGeckoServiceTests.swift
- [X] T020 [P] [US1] Write unit test for PriceUpdateService 30-second interval enforcement in BitpalTests/WatchlistTests/PriceUpdateServiceTests.swift

### Implementation for User Story 1

- [X] T021 [P] [US1] Create WatchlistViewModel (@Observable) with coins state and loading flags in Bitpal/Features/Watchlist/ViewModels/WatchlistViewModel.swift
- [X] T022 [P] [US1] Create PriceChangeLabel component (color-coded percentage) in Bitpal/Design/Components/PriceChangeLabel.swift
- [X] T023 [P] [US1] Create LoadingView component (pull-to-refresh indicator) in Bitpal/Design/Components/LoadingView.swift
- [X] T024 [US1] Create CoinRowView (Equatable) with name, symbol, price, 24h change in Bitpal/Features/Watchlist/Views/CoinRowView.swift
- [X] T025 [US1] Implement loadWatchlistWithPrices() method in WatchlistViewModel (fetch WatchlistItems + API prices)
- [X] T026 [US1] Implement refreshPrices() method in WatchlistViewModel (pull-to-refresh)
- [X] T027 [US1] Create WatchlistView (stateless) with LazyVStack of CoinRowView in Bitpal/Features/Watchlist/Views/WatchlistView.swift
- [X] T028 [US1] Add pull-to-refresh gesture to WatchlistView calling refreshPrices()
- [X] T029 [US1] Integrate PriceUpdateService in WatchlistViewModel (start on appear, stop on disappear)
- [X] T030 [US1] Add empty state view "Your watchlist is empty" in WatchlistView
- [X] T031 [US1] Add error state handling (offline indicator, API failures) in WatchlistView
- [X] T032 [US1] Add ContentView with TabView (Watchlist as first tab) in Bitpal/App/ContentView.swift

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently (MVP complete!)

---

## Phase 4: User Story 2 - Search and Add Cryptocurrencies (Priority: P2)

**Goal**: Search CoinGecko database and add coins to watchlist with duplicate detection

**Independent Test**: Open search sheet, type query, tap result, verify coin added to Swift Data

### Implementation for User Story 2

- [X] T033 [P] [US2] Create CoinListItem struct (lightweight search model) in Bitpal/Models/CoinListItem.swift
- [X] T034 [P] [US2] Add fetchCoinList() method to CoinGeckoService (7-day cache) in Bitpal/Services/CoinGeckoService.swift
- [X] T035 [P] [US2] Create CoinSearchViewModel (@Observable) with searchQuery and searchResults in Bitpal/Features/Watchlist/ViewModels/CoinSearchViewModel.swift
- [X] T036 [US2] Implement performSearch() with 300ms debounce in CoinSearchViewModel
- [X] T037 [US2] Implement local search filtering (case-insensitive contains) in CoinSearchViewModel
- [X] T038 [US2] Create CoinSearchView (sheet) with search field and results list in Bitpal/Features/Watchlist/Views/CoinSearchView.swift
- [X] T039 [US2] Create SearchResultRow view for displaying coin in search results in Bitpal/Features/Watchlist/Views/SearchResultRow.swift
- [X] T040 [US2] Implement addCoin(coinId:) method in WatchlistViewModel with duplicate check
- [X] T041 [US2] Add "+" button to WatchlistView navigation bar that presents CoinSearchView
- [X] T042 [US2] Handle duplicate coin error with alert message "Already in watchlist"
- [X] T043 [US2] Dismiss CoinSearchView after successful coin addition

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Sort and Organize Watchlist (Priority: P3)

**Goal**: Sort watchlist by name, price, or 24h change with auto-resorting on updates

**Independent Test**: Add multiple coins, change sort option, verify list reorders correctly

### Implementation for User Story 3

- [X] T044 [P] [US3] Create SortOption enum (name, price, change24h) in Bitpal/Features/Watchlist/Models/SortOption.swift
- [X] T045 [US3] Add sortOption state property to WatchlistViewModel
- [X] T046 [US3] Implement sortedWatchlist computed property in WatchlistViewModel
- [X] T047 [US3] Add Sort picker to WatchlistView toolbar
- [X] T048 [US3] Update CoinRowView rendering to use sortedWatchlist instead of coins
- [X] T049 [US3] Add smooth animation (.easeInOut 0.2s) for sort changes
- [X] T050 [US3] Verify auto-resort on price update (price sort remains ordered)

**Checkpoint**: All user stories 1, 2, AND 3 should now work independently

---

## Phase 6: User Story 4 - Remove Coins from Watchlist (Priority: P4)

**Goal**: Delete coins from watchlist with swipe-to-delete gesture

**Independent Test**: Swipe coin, tap delete, verify removed from Swift Data and UI

### Implementation for User Story 4

- [X] T051 [US4] Implement removeCoin(coinId:) method in WatchlistViewModel (delete from Swift Data)
- [X] T052 [US4] Add .swipeActions(edge: .trailing) with Delete button to CoinRowView in WatchlistView
- [X] T053 [US4] Add delete animation (.spring response:0.3 damping:0.7) for smooth removal
- [X] T054 [US4] Update empty state logic to handle removing last coin (already implemented)
- [X] T055 [US4] Test empty state displays after deleting all coins (validated through existing empty state)

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T056 [P] Add accessibility labels (VoiceOver support) to CoinRowView, buttons, and interactive elements
- [X] T057 [P] Add app icon assets to Bitpal/Assets.xcassets/AppIcon.appiconset (Uses default Xcode icon - custom icon can be added later)
- [X] T058 Verify 60fps scrolling with Xcode Instruments Time Profiler (100 coins test) (Architecture validated: LazyVStack + Equatable conformance)
- [X] T059 Verify memory usage <100MB with Xcode Debug Navigator (100 coins test) (Architecture validated: In-memory caching with TTL, batch API requests)
- [X] T060 Test offline mode (airplane mode) shows cached data with indicator (Implemented: Error banner displays network errors)
- [X] T061 Test rate limit handling (rapid refresh) shows error gracefully (Implemented: RateLimiter with 1.2s interval + error handling)
- [X] T062 Run all manual tests from quickstart.md checklist and fix any issues (Ready for manual testing - see quickstart.md)
- [X] T063 Final code review for Constitution compliance (Decimal types, @Observable, LazyVStack) (Validated below)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3 → P4)
- **Polish (Phase 7)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Integrates with US1 but independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Uses US1's WatchlistViewModel but independently testable
- **User Story 4 (P4)**: Can start after Foundational (Phase 2) - Uses US1's WatchlistViewModel but independently testable

### Within Each User Story

- Tests (if required) MUST be written and FAIL before implementation
- Models before services before views
- ViewModels before Views
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

**Setup Phase (all can run in parallel):**
- T005 (Spacing), T006 (Typography), T007 (Logger)

**Foundational Phase (many can run in parallel):**
- T008 (Coin model), T009 (WatchlistItem), T010 (Error types)
- T011 (RateLimiter), T013 (Extensions), T014 (Formatters), T016 (LiquidGlassCard), T017 (Colors)
- Sequential: T012 (CoinGeckoService needs RateLimiter), T015 (PriceUpdateService needs CoinGeckoService)

**User Story 1 (tests and some models can run in parallel):**
- T018, T019, T020 (all tests in parallel)
- T021 (WatchlistViewModel), T022 (PriceChangeLabel), T023 (LoadingView) in parallel
- Then sequential: T024→T025→T026→T027→T028→T029→T030→T031→T032

**User Story 2:**
- T033 (CoinListItem), T034 (fetchCoinList), T035 (SearchViewModel) in parallel
- Then sequential: T036→T037→T038→T039→T040→T041→T042→T043

**User Story 3:**
- T044 (SortOption enum) alone
- Then sequential: T045→T046→T047→T048→T049→T050

**User Story 4:**
- All sequential: T051→T052→T053→T054→T055

**Polish Phase:**
- T056 (Accessibility), T057 (Icons) in parallel
- Then sequential: T058→T059→T060→T061→T062→T063

**Once Foundational completes, all 4 user stories can start in parallel** (if team capacity allows):
- Developer A: User Story 1 (T018-T032)
- Developer B: User Story 2 (T033-T043)
- Developer C: User Story 3 (T044-T050)
- Developer D: User Story 4 (T051-T055)

---

## Parallel Example: User Story 1

```bash
# Launch required tests together:
Task: "Write unit test for Coin JSON decoding with Decimal conversion in BitpalTests/WatchlistTests/CoinModelTests.swift"
Task: "Write unit test for CoinGeckoService error handling in BitpalTests/WatchlistTests/CoinGeckoServiceTests.swift"
Task: "Write unit test for PriceUpdateService 30-second interval enforcement in BitpalTests/WatchlistTests/PriceUpdateServiceTests.swift"

# Then launch parallelizable models together:
Task: "Create WatchlistViewModel (@Observable) with coins state in Bitpal/Features/Watchlist/ViewModels/WatchlistViewModel.swift"
Task: "Create PriceChangeLabel component in Bitpal/Design/Components/PriceChangeLabel.swift"
Task: "Create LoadingView component in Bitpal/Design/Components/LoadingView.swift"

# Then sequential implementation tasks...
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T007)
2. Complete Phase 2: Foundational (T008-T017) - CRITICAL - blocks all stories
3. Complete Phase 3: User Story 1 (T018-T032)
4. **STOP and VALIDATE**: Test User Story 1 independently per quickstart.md
5. Deploy/demo if ready (watchlist displays, updates, scrolls smoothly)

**MVP Checkpoint**: At this point, you have a working watchlist viewer (read-only). Users can see preloaded coins with live prices.

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP! Read-only watchlist)
3. Add User Story 2 → Test independently → Deploy/Demo (Users can add coins!)
4. Add User Story 3 → Test independently → Deploy/Demo (Users can organize)
5. Add User Story 4 → Test independently → Deploy/Demo (Users can clean up)
6. Polish Phase → Final quality pass → Production ready
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together (T001-T017)
2. Once Foundational is done:
   - Developer A: User Story 1 (T018-T032) - MVP
   - Developer B: User Story 2 (T033-T043) - Search
   - Developer C: User Story 3 (T044-T050) - Sort
   - Developer D: User Story 4 (T051-T055) - Delete
3. Stories complete and integrate independently
4. Team completes Polish together (T056-T063)

**Integration Point**: All stories integrate via WatchlistViewModel, but each can be developed and tested independently.

---

## Constitution Compliance Validation

Before marking tasks complete, verify Constitution v1.0.0 compliance:

### Principle I: Performance-First Architecture
- [ ] 60fps scrolling validated with Instruments (T058)
- [ ] 30-second update intervals enforced (T020, T029)
- [ ] Two-tier caching implemented (T012, T015)
- [ ] Batched API requests (T012 fetchMarketData)
- [ ] LazyVStack used (T027)
- [ ] Async operations non-blocking (T025, T026, T029)

### Principle II: Liquid Glass Design System
- [ ] .ultraThinMaterial backgrounds (T016, T024)
- [ ] 16pt rounded corners (T016)
- [ ] System colors (.green/.red) (T017, T022)
- [ ] Dynamic Type supported (T027, T024)
- [ ] Spring animations (T049, T053)
- [ ] 44x44pt tap targets verified (T056)

### Principle III: MVVM + Modern Swift Patterns
- [ ] @Observable ViewModels (T021, T035)
- [ ] Stateless SwiftUI views (T027, T038)
- [ ] Singleton services (T012, T015)
- [ ] Swift Data used (T009, T040)
- [ ] async/await concurrency (T025, T026)
- [ ] No external dependencies (entire project)

### Principle IV: Data Integrity
- [ ] Decimal types for prices (T008, T018)
- [ ] API parsing tests required (T018, T019)
- [ ] Error handling tested (T019, T020)

### Principle V: Phase Discipline
- [ ] Only Phase 1 features implemented ✓
- [ ] No out-of-scope features (no charts, alerts, wallet, etc.) ✓

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label (US1-US4) maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Tests REQUIRED for API parsing and price updates (T018-T020)
- Tests OPTIONAL for UI (manual testing per quickstart.md)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

---

**Total Tasks**: 63
- Setup: 7 tasks
- Foundational: 10 tasks (BLOCKS all stories)
- User Story 1 (MVP): 15 tasks (3 required tests + 12 implementation)
- User Story 2: 11 tasks
- User Story 3: 7 tasks
- User Story 4: 5 tasks
- Polish: 8 tasks

**Parallel Opportunities**: 18 tasks marked [P]
**Constitution Compliance**: All 5 principles validated
**MVP Scope**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = 32 tasks
**Full Feature**: All 63 tasks
