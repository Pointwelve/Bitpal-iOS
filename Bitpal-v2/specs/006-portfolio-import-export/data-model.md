# Data Model: Portfolio Import/Export

**Feature**: 006-portfolio-import-export
**Date**: 2025-11-28

## Entity Overview

```
┌─────────────────────┐     ┌─────────────────────┐
│   ExportFile        │     │   ImportPreview     │
│   (JSON wrapper)    │     │   (ephemeral)       │
├─────────────────────┤     ├─────────────────────┤
│ - version           │     │ - validRows         │
│ - exportDate        │     │ - invalidRows       │
│ - appVersion        │     │ - sourceType        │
│ - transactions[]    │     │ - fileName          │
└─────────────────────┘     └─────────────────────┘
         │                           │
         │ contains                  │ contains
         ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ ExportTransaction   │     │  ImportRow          │
│ (Codable struct)    │     │  (preview row)      │
├─────────────────────┤     ├─────────────────────┤
│ - id                │     │ - rowNumber         │
│ - coinId            │     │ - coinId            │
│ - type              │     │ - type              │
│ - amount (string)   │     │ - amount            │
│ - pricePerCoin (str)│     │ - pricePerCoin      │
│ - date              │     │ - date              │
│ - notes             │     │ - notes             │
└─────────────────────┘     │ - errors[]          │
         │                  │ - isValid           │
         │ converts to      └─────────────────────┘
         ▼                           │
┌─────────────────────┐              │ converts to
│   Transaction       │◄─────────────┘
│   (Swift Data)      │
│   [EXISTING]        │
├─────────────────────┤
│ - id: UUID          │
│ - coinId: String    │
│ - type: TxType      │
│ - amount: Decimal   │
│ - pricePerCoin: Dec │
│ - date: Date        │
│ - notes: String?    │
└─────────────────────┘
```

## Entity Definitions

### ExportFile (NEW)

**Purpose**: JSON wrapper containing transactions with metadata for versioning and compatibility.

```swift
/// Export file format with metadata for future compatibility
struct ExportFile: Codable {
    /// Format version for migration support
    let version: String  // "1.0"

    /// When export was created
    let exportDate: Date

    /// App version that created export
    let appVersion: String  // e.g., "1.0.0"

    /// Array of transactions
    let transactions: [ExportTransaction]
}
```

**Validation Rules**:
- `version` must be a recognized format version
- `transactions` array can be empty (results in "no data" message on import)
- `appVersion` is informational only, not validated

---

### ExportTransaction (NEW)

**Purpose**: Codable representation of Transaction with string-encoded Decimals for precision.

```swift
/// Transaction representation for JSON export
/// Uses String for Decimal fields to preserve precision
struct ExportTransaction: Codable {
    /// Original transaction UUID
    let id: UUID

    /// CoinGecko coin identifier
    let coinId: String

    /// Transaction type: "buy" or "sell"
    let type: String

    /// Quantity as string (preserves Decimal precision)
    let amount: String

    /// Price per coin as string (preserves Decimal precision)
    let pricePerCoin: String

    /// Transaction date (ISO 8601)
    let date: Date

    /// Optional user notes
    let notes: String?
}
```

**Validation Rules**:
- `type` must be "buy" or "sell" (case-insensitive on import)
- `amount` must parse to positive Decimal
- `pricePerCoin` must parse to positive Decimal
- `coinId` must be non-empty string

**Relationships**:
- Converts from `Transaction` (for export)
- Converts to `Transaction` (for import)

---

### ImportPreview (NEW)

**Purpose**: Ephemeral container holding parsed import data before user confirmation.

```swift
/// Preview of import data before user confirms
struct ImportPreview {
    /// Source file type
    let sourceType: ImportSourceType  // .json or .csv

    /// Original file name for display
    let fileName: String

    /// Rows that passed validation
    let validRows: [ImportRow]

    /// Rows that failed validation with errors
    let invalidRows: [ImportRow]

    /// Total row count
    var totalRowCount: Int {
        validRows.count + invalidRows.count
    }

    /// Whether any valid rows exist to import
    var hasValidData: Bool {
        !validRows.isEmpty
    }
}

enum ImportSourceType: String {
    case json
    case csv
}
```

**Lifecycle**:
1. Created when user selects file
2. Displayed in preview screen
3. Discarded if user cancels
4. Valid rows converted to Transactions if user confirms

---

### ImportRow (NEW)

**Purpose**: Single row from import file with validation status.

```swift
/// Single row from import file
struct ImportRow: Identifiable {
    let id = UUID()

    /// Row number in source file (1-based for display)
    let rowNumber: Int

    /// Parsed values
    let coinId: String
    let type: TransactionType?  // nil if invalid
    let amount: Decimal?        // nil if invalid
    let pricePerCoin: Decimal?  // nil if invalid
    let date: Date?             // nil if invalid
    let notes: String?

    /// Validation errors for this row
    let errors: [String]

    /// Whether row is valid for import
    var isValid: Bool {
        errors.isEmpty && type != nil && amount != nil && pricePerCoin != nil && date != nil
    }
}
```

**Validation per Field**:
| Field | Validation | Error Message |
|-------|-----------|---------------|
| coinId | Non-empty | "Coin ID is required" |
| type | "buy" or "sell" | "Type must be 'buy' or 'sell'" |
| amount | Positive Decimal | "Amount must be a positive number" |
| pricePerCoin | Positive Decimal | "Price must be a positive number" |
| date | ISO 8601 parseable | "Date must be in YYYY-MM-DD format" |
| notes | (none) | N/A (optional) |

---

### ImportError (NEW)

**Purpose**: Typed errors for import failures with localized descriptions.

```swift
/// Import operation errors
enum ImportError: LocalizedError {
    /// File is empty or contains no data
    case emptyFile

    /// File format is invalid (parse error)
    case invalidFormat(String)

    /// CSV missing required column
    case missingRequiredColumn(String)

    /// File could not be accessed
    case fileAccessDenied

    /// No valid rows after validation
    case noValidRows

    /// Decimal parsing failed
    case invalidDecimal(field: String, value: String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or contains no transactions."
        case .invalidFormat(let detail):
            return "Invalid file format: \(detail)"
        case .missingRequiredColumn(let column):
            return "Missing required column: \(column)"
        case .fileAccessDenied:
            return "Unable to access the file. Please try again."
        case .noValidRows:
            return "No valid transactions found in the file."
        case .invalidDecimal(let field, let value):
            return "Invalid number '\(value)' for \(field)"
        }
    }
}
```

---

### Transaction (EXISTING - No Changes)

The existing `Transaction` model remains unchanged. Import/export uses conversion through `ExportTransaction` and `ImportRow`.

```swift
// Existing model - reference only
@Model
final class Transaction {
    var id: UUID
    var coinId: String
    var type: TransactionType
    var amount: Decimal
    var pricePerCoin: Decimal
    var date: Date
    var notes: String?
}
```

---

## Conversion Functions

### Export: Transaction → ExportTransaction

```swift
extension ExportTransaction {
    init(from transaction: Transaction) {
        self.id = transaction.id
        self.coinId = transaction.coinId
        self.type = transaction.type.rawValue  // "buy" or "sell"
        self.amount = "\(transaction.amount)"
        self.pricePerCoin = "\(transaction.pricePerCoin)"
        self.date = transaction.date
        self.notes = transaction.notes
    }
}
```

### Import: ImportRow → Transaction

```swift
extension ImportRow {
    func toTransaction() -> Transaction? {
        guard isValid,
              let type = type,
              let amount = amount,
              let pricePerCoin = pricePerCoin,
              let date = date else {
            return nil
        }

        return Transaction(
            id: UUID(),  // Generate new UUID on import
            coinId: coinId,
            type: type,
            amount: amount,
            pricePerCoin: pricePerCoin,
            date: date,
            notes: notes
        )
    }
}
```

---

## State Transitions

### Import Flow State Machine

```
┌─────────────────┐
│     Idle        │
│  (no file)      │
└────────┬────────┘
         │ User selects file
         ▼
┌─────────────────┐
│    Parsing      │──────────────┐
│                 │              │ Parse error
└────────┬────────┘              ▼
         │ Parse success    ┌─────────────────┐
         ▼                  │     Error       │
┌─────────────────┐         │  (show alert)   │
│    Preview      │         └────────┬────────┘
│ (show rows)     │                  │ Dismiss
└────────┬────────┘                  ▼
         │                  ┌─────────────────┐
    ┌────┴────┐             │     Idle        │
    │         │             └─────────────────┘
    ▼         ▼
┌───────┐ ┌───────┐
│Cancel │ │Confirm│
└───┬───┘ └───┬───┘
    │         │ Import valid rows
    │         ▼
    │     ┌─────────────────┐
    │     │   Importing     │
    │     │                 │
    │     └────────┬────────┘
    │              │ Complete
    ▼              ▼
┌─────────────────────────────┐
│          Idle               │
│   (portfolio refreshed)     │
└─────────────────────────────┘
```

---

## File Format Examples

### JSON Export Format

```json
{
  "version": "1.0",
  "exportDate": "2025-11-28T10:30:00Z",
  "appVersion": "1.0.0",
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "coinId": "bitcoin",
      "type": "buy",
      "amount": "0.5",
      "pricePerCoin": "45000.00",
      "date": "2025-01-15T00:00:00Z",
      "notes": "DCA purchase"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "coinId": "ethereum",
      "type": "buy",
      "amount": "2.0",
      "pricePerCoin": "3200.50",
      "date": "2025-01-20T00:00:00Z",
      "notes": null
    }
  ]
}
```

### CSV Import Format

```csv
coin_id,type,amount,price,date,notes
bitcoin,buy,0.5,45000.00,2025-01-15,DCA purchase
ethereum,buy,2.0,3200.50,2025-01-20,
cardano,sell,100,0.52,2025-01-25,Taking profits
```
