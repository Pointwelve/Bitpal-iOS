# Tasks: Portfolio Import/Export

**Input**: Design documents from `/specs/006-portfolio-import-export/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Per Constitution Testing Strategy (Principle IV), tests are REQUIRED for critical business logic (round-trip data integrity) and OPTIONAL for UI/simple operations.

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

## Path Conventions

All paths relative to `Bitpal/` (main app target):
- **Models**: `Features/Portfolio/Models/`
- **ViewModels**: `Features/Portfolio/ViewModels/`
- **Views**: `Features/Portfolio/Views/`
- **Services**: `Features/Portfolio/Services/`
- **Utilities**: `Utilities/`
- **Tests**: `BitpalTests/PortfolioTests/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create new files and directories needed for the feature

- [x] T001 Create Services directory at Bitpal/Features/Portfolio/Services/ (if not exists)
- [x] T002 [P] Create ImportError.swift enum in Bitpal/Features/Portfolio/Models/ImportError.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and utilities that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Create ExportFile struct in Bitpal/Features/Portfolio/Models/ExportFile.swift (includes ExportTransaction with string-encoded Decimals)
- [x] T004 [P] Create ImportPreview struct in Bitpal/Features/Portfolio/Models/ImportPreview.swift (includes ImportRow and ImportSourceType)
- [x] T005 Create CSVParser utility in Bitpal/Utilities/CSVParser.swift (parses CSV with header matching, quoted values, validation)
- [x] T006 Create ImportExportService singleton in Bitpal/Features/Portfolio/Services/ImportExportService.swift (core export/import logic, JSON encoding/decoding, file URL creation)

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Export Portfolio Data (Priority: P1) 🎯 MVP

**Goal**: Users can export all transactions to a JSON file via iOS share sheet

**Independent Test**: Create sample transactions, tap export, verify JSON file contains all data with correct format

### Tests for User Story 1 (REQUIRED - round-trip integrity) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [US1] Create ImportExportServiceTests.swift in BitpalTests/PortfolioTests/ImportExportServiceTests.swift with export JSON encoding test (verify Decimal precision preserved as strings)
- [x] T008 [US1] Add round-trip integrity test to ImportExportServiceTests.swift (export→import preserves all fields exactly)

### Implementation for User Story 1

- [x] T009 [US1] Add exportTransactions() method to ImportExportService (converts [Transaction] to ExportFile JSON Data)
- [x] T010 [US1] Add createExportURL() method to ImportExportService (creates temp file with proper naming bitpal-portfolio-{date}.json)
- [x] T011 [US1] Add export action to PortfolioViewModel in Bitpal/Features/Portfolio/ViewModels/PortfolioViewModel.swift (fetches all transactions, calls service, provides URL for sharing)
- [x] T012 [US1] Add "..." menu button to PortfolioView toolbar in Bitpal/Features/Portfolio/Views/PortfolioView.swift
- [x] T013 [US1] Implement export button in menu with ShareLink integration (presents iOS share sheet with exported file)
- [x] T014 [US1] Handle empty portfolio case (show alert "No transactions to export" when portfolio empty)

**Checkpoint**: Export feature fully functional - can backup portfolio to JSON file

---

## Phase 4: User Story 2 - Import Portfolio Data (Priority: P2)

**Goal**: Users can import JSON backup files with preview and confirmation

**Independent Test**: Select a JSON file, see preview of transactions, confirm import, verify transactions appear in portfolio

### Tests for User Story 2 (REQUIRED - data validation) ⚠️

- [x] T015 [US2] Add JSON parsing test to ImportExportServiceTests.swift (valid JSON parses correctly)
- [x] T016 [US2] Add invalid JSON handling test to ImportExportServiceTests.swift (corrupted files produce clear error)
- [x] T017 [US2] Add row validation test to ImportExportServiceTests.swift (invalid rows flagged, valid rows pass)

### Implementation for User Story 2

- [x] T018 [US2] Add parseFile(at:) method to ImportExportService (detects file type, delegates to JSON/CSV parser)
- [x] T019 [US2] Add parseJSON() private method to ImportExportService (decodes ExportFile, creates ImportPreview with validation)
- [x] T020 [US2] Add validateRow() helper to ImportExportService (checks coinId non-empty, type valid, amounts positive, date parseable)
- [x] T021 [US2] Create ImportPreviewViewModel in Bitpal/Features/Portfolio/ViewModels/ImportPreviewViewModel.swift (@Observable, manages preview state, confirm/cancel actions)
- [x] T022 [US2] Create ImportPreviewView in Bitpal/Features/Portfolio/Views/ImportPreviewView.swift (LazyVStack of valid/invalid rows, confirm button, cancel button)
- [x] T023 [US2] Add import button to PortfolioView menu (triggers fileImporter modifier)
- [x] T024 [US2] Add fileImporter modifier to PortfolioView (allowedContentTypes: [.json, .commaSeparatedText])
- [x] T025 [US2] Add confirmImport() method to ImportPreviewViewModel (converts valid ImportRows to Transactions, inserts to SwiftData)
- [x] T026 [US2] Add navigation from PortfolioView to ImportPreviewView (sheet presentation after file selection)
- [x] T027 [US2] Handle import errors with alert (show ImportError.localizedDescription)

**Checkpoint**: JSON import fully functional - can restore backups with preview

---

## Phase 5: User Story 3 - Import from External Sources (Priority: P3)

**Goal**: Users can import CSV files prepared in spreadsheets with documented format

**Independent Test**: Create CSV file manually following documented format, import it, verify transactions created correctly

### Tests for User Story 3 (REQUIRED - CSV parsing) ⚠️

- [x] T028 [US3] Create CSVParserTests.swift in BitpalTests/PortfolioTests/CSVParserTests.swift with valid CSV parsing test
- [x] T029 [US3] Add missing column detection test to CSVParserTests.swift (throws missingRequiredColumn error)
- [x] T030 [US3] Add quoted values parsing test to CSVParserTests.swift (handles commas in notes field)
- [x] T031 [US3] Add case-insensitive header test to CSVParserTests.swift (COIN_ID, Coin_Id, coin_id all work)

### Implementation for User Story 3

- [x] T032 [US3] Add parseCSV() private method to ImportExportService (uses CSVParser, creates ImportPreview)
- [x] T033 [US3] Add validateCSVRow() helper to ImportExportService (validates row dictionary against column spec)
- [x] T034 [US3] Update ImportPreviewView to show row-level errors (display which fields failed validation per row)
- [x] T035 [US3] Add partial import support to ImportPreviewView (import only valid rows button when some rows invalid)
- [x] T036 [US3] Add import summary after completion (show "Imported X of Y transactions" message)

**Checkpoint**: CSV import fully functional - can import from spreadsheets/external tools

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T037 [P] Add logging to ImportExportService (use Logger.persistence for import/export operations)
- [x] T038 [P] Add progress indicator for large imports (>100 transactions show loading state)
- [x] T039 Verify performance: export 500 transactions in <3 seconds (profile with Instruments if needed)
- [x] T040 Verify performance: import preview appears in <2 seconds (profile with Instruments if needed)
- [x] T041 [P] Ensure Dynamic Type support in ImportPreviewView (test with accessibility sizes)
- [x] T042 [P] Ensure Dark Mode support in ImportPreviewView (verify with system appearance toggle)
- [ ] T043 Run quickstart.md validation (manual test all scenarios in quickstart.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed sequentially in priority order (US1 → US2 → US3)
  - US2 imports JSON which requires US1's export format understanding
  - US3 adds CSV parsing on top of US2's import infrastructure
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1 - Export)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2 - JSON Import)**: Can start after Foundational (Phase 2) - Uses same models as US1, independent test possible with sample file
- **User Story 3 (P3 - CSV Import)**: Depends on US2 infrastructure (ImportPreviewView, validateRow) - Extends import with CSV parser

### Within Each User Story

- Tests MUST be written and FAIL before implementation (for required tests)
- Models before services
- Services before ViewModels
- ViewModels before Views
- Core implementation before UI integration

### Parallel Opportunities

**Phase 2 (Foundational)**:
```
Parallel: T003, T004 (different model files)
Sequential: T005, T006 (CSVParser before ImportExportService)
```

**Phase 3 (US1 - Export)**:
```
Parallel: T007, T008 (different test cases)
Sequential: T009 → T010 → T011 → T012 → T013 → T014
```

**Phase 4 (US2 - JSON Import)**:
```
Parallel: T015, T016, T017 (different test cases)
Parallel: T021, T022 (ViewModel and View can be scaffolded together)
Sequential: T018 → T019 → T020 → T25 → T26 → T27
```

**Phase 5 (US3 - CSV Import)**:
```
Parallel: T028, T029, T030, T031 (different test cases)
Sequential: T032 → T033 → T034 → T035 → T036
```

**Phase 6 (Polish)**:
```
Parallel: T037, T038, T041, T042 (different files/concerns)
Sequential: T039, T040, T043 (validation tasks)
```

---

## Parallel Example: Phase 2 (Foundational)

```bash
# Launch model creation in parallel:
Task: "Create ExportFile struct in Bitpal/Features/Portfolio/Models/ExportFile.swift"
Task: "Create ImportPreview struct in Bitpal/Features/Portfolio/Models/ImportPreview.swift"

# Then sequential for service (depends on models):
Task: "Create CSVParser utility in Bitpal/Utilities/CSVParser.swift"
Task: "Create ImportExportService singleton in Bitpal/Features/Portfolio/Services/ImportExportService.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 (Export)
4. **STOP and VALIDATE**: Test export independently - can backup portfolio
5. Deploy/demo if ready - users can immediately backup their data

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Export) → Test independently → **MVP: Backup capability**
3. Add User Story 2 (JSON Import) → Test independently → **Restore capability**
4. Add User Story 3 (CSV Import) → Test independently → **External data import**
5. Each story adds value without breaking previous stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing (TDD for required tests)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Constitution Principle IV: Decimal precision preserved via string encoding in JSON
- Constitution Principle III: @Observable for ViewModels, singleton for service
