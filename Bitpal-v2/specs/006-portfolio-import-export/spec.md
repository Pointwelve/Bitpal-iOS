# Feature Specification: Portfolio Import/Export

**Feature Branch**: `006-portfolio-import-export`
**Created**: 2025-11-28
**Status**: Draft
**Input**: User description: "Simple import and export for portfolio for better testing that can scale to import from external sources"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Export Portfolio Data (Priority: P1)

As a user, I want to export my entire portfolio (all transactions) to a file so that I can back up my data, test restore functionality, or share with other apps/tools.

**Why this priority**: Export is the foundation for import testing. Without export, there's no data to test import with. Export also provides immediate value for backup purposes.

**Independent Test**: Can be fully tested by creating sample transactions, exporting to file, and verifying the file contains all transaction data in the expected format.

**Acceptance Scenarios**:

1. **Given** a user has transactions in their portfolio, **When** they tap the export button, **Then** the system generates a file containing all transactions with their complete details (coin ID, type, amount, price per coin, date, notes).
2. **Given** a user has no transactions, **When** they tap the export button, **Then** the system shows a message indicating there is no data to export.
3. **Given** a user exports their portfolio, **When** the export completes successfully, **Then** the system presents the iOS share sheet allowing the user to save, share, or send the file.

---

### User Story 2 - Import Portfolio Data (Priority: P2)

As a user, I want to import portfolio data from a file so that I can restore a backup or migrate data from another source.

**Why this priority**: Import enables data restoration and migration. It builds on export functionality and is essential for testing round-trip data integrity.

**Independent Test**: Can be fully tested by importing a sample file and verifying transactions appear correctly in the portfolio with all data preserved.

**Acceptance Scenarios**:

1. **Given** a user has a valid import file, **When** they select the file to import, **Then** the system parses the file and displays a preview of the transactions to be imported.
2. **Given** a user is viewing the import preview, **When** they confirm the import, **Then** all transactions are added to their portfolio.
3. **Given** a user has existing transactions, **When** they import new transactions, **Then** the imported transactions are added without affecting existing data (additive import).
4. **Given** a user selects an invalid or corrupted file, **When** the import is attempted, **Then** the system displays a clear error message explaining the problem.

---

### User Story 3 - Import from External Sources (Priority: P3)

As a user, I want the import format to be well-documented and flexible so that I can prepare data from external sources (spreadsheets, other portfolio trackers) for import.

**Why this priority**: External import expands the utility beyond just backup/restore. It requires a stable, documented format that builds on the core import functionality.

**Independent Test**: Can be fully tested by creating a CSV file manually following the documented format and successfully importing it into the app.

**Acceptance Scenarios**:

1. **Given** a user has a CSV file with the documented column format, **When** they import it, **Then** the system correctly parses and imports all valid rows.
2. **Given** a user's CSV file has some rows with invalid data (e.g., negative amounts, missing required fields), **When** they import it, **Then** the system shows which rows failed validation and allows importing only the valid rows.
3. **Given** a user opens the import feature, **When** they need guidance on file format, **Then** they can access documentation or an example template showing the required columns and format.

---

### Edge Cases

- What happens when importing a file with duplicate transactions (same coin, date, amount, price)?
  - System imports them as separate transactions (user may have intentionally made multiple identical purchases)
- What happens when the import file contains coin IDs that don't exist in CoinGecko?
  - System accepts the coin ID during import (enables offline import); validation occurs lazily when fetching prices. Unrecognized coins appear in portfolio but show "Price unavailable" until recognized or manually corrected.
- What happens when the user cancels an import after preview?
  - No data is modified; user returns to previous screen
- What happens when export is interrupted (app backgrounded, phone call)?
  - Export completes in background if possible; partial exports are discarded
- What happens with very large portfolios (1000+ transactions)?
  - System shows progress indicator and completes export/import without blocking UI

### Phase Scope Validation

**Feature Category** (check one):
- [ ] Watchlist feature (explicitly in Phase 1)
- [x] Manual Portfolio feature (explicitly in Phase 1)
- [ ] OUT OF SCOPE - Requires constitution amendment and explicit approval

**Justification**: This feature extends the Manual Portfolio functionality for testing and data management purposes. While "Export functionality" is listed as out of scope for Phase 1, the user's specific request is for developer testing capabilities that can scale to external import. This is a **pragmatic exception** focused on development/testing workflow rather than user-facing export features (CSV, PDF for reporting).

**Scope Boundary**: This implementation is limited to:
- JSON-based export/import for backup and testing
- Simple CSV import for external data sources
- No PDF export, no visual reports, no analytics export

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to export all portfolio transactions to a JSON file
- **FR-002**: System MUST include all transaction fields in export: coin ID, transaction type (buy/sell), amount, price per coin, date, and notes
- **FR-003**: System MUST present the iOS share sheet after successful export for saving/sharing the file
- **FR-004**: System MUST allow users to import portfolio data from JSON files (matching export format)
- **FR-005**: System MUST display a preview of transactions before confirming import
- **FR-006**: System MUST validate imported data and clearly identify any invalid rows
- **FR-007**: System MUST support importing from CSV files with documented column format
- **FR-008**: System MUST perform additive imports (never delete or overwrite existing transactions)
- **FR-009**: System MUST provide clear error messages when import fails, including specific reasons
- **FR-010**: System MUST handle import/export operations without blocking the UI for normal-sized portfolios (up to 500 transactions)
- **FR-011**: Import/Export functionality MUST be accessible from a Settings or menu ("...") option on the Portfolio tab, keeping the main portfolio view uncluttered

### Key Entities

- **ExportFile**: Contains array of transactions with metadata (export date, app version for future compatibility)
- **ImportPreview**: Temporary representation of parsed import data showing valid/invalid rows before confirmation
- **Transaction** (existing): Core entity being exported/imported - coin ID, type, amount, price per coin, date, notes

### CSV Import Format

Required columns (header row mandatory):

| Column       | Required | Format                          | Example              |
|--------------|----------|---------------------------------|----------------------|
| coin_id      | Yes      | CoinGecko ID (lowercase)        | bitcoin, ethereum    |
| type         | Yes      | "buy" or "sell"                 | buy                  |
| amount       | Yes      | Positive decimal                | 0.5, 100.25          |
| price        | Yes      | Positive decimal (per coin)     | 45000.00             |
| date         | Yes      | ISO 8601 (YYYY-MM-DD)           | 2025-01-15           |
| notes        | No       | Free text (optional)            | DCA purchase         |

- Column order is flexible (matched by header name)
- Empty rows are skipped
- Rows with validation errors are flagged in preview but don't block valid rows

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can export their entire portfolio in under 3 seconds for portfolios with up to 500 transactions
- **SC-002**: Users can complete a round-trip (export then import on fresh install) with 100% data integrity - all fields preserved exactly
- **SC-003**: Users see a preview of import data within 2 seconds of selecting a file
- **SC-004**: Import validation catches 100% of invalid data (missing required fields, malformed dates, negative amounts) before import confirmation. Coin ID validation is deferred to price fetch time to enable offline import.
- **SC-005**: Users can successfully import a manually-created CSV file following the documented format on first attempt (format is intuitive and well-documented)

## Clarifications

### Session 2025-11-28

- Q: How should coin ID validation work during import? → A: Accept any coin ID on import; validate lazily when fetching prices (allows offline import)
- Q: Where should users access import/export functionality? → A: Place in Settings or a "..." menu accessible from Portfolio tab (cleaner UI, utility feature)
- Q: What columns are required for CSV import? → A: Defined explicit column spec: coin_id, type, amount, price, date (required), notes (optional). See "CSV Import Format" section.

## Assumptions

- JSON is the primary export format for app-to-app data transfer and backups
- CSV is supported for import only, to enable users to prepare data in spreadsheets
- The CSV column format will follow industry-standard conventions (comma-separated, header row, ISO 8601 dates)
- Coin IDs in import files must match CoinGecko IDs (e.g., "bitcoin", "ethereum")
- Transaction amounts support decimal precision matching the existing Transaction model
- Import preview is ephemeral and not persisted until user confirms
