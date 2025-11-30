# Research: Portfolio Import/Export

**Feature**: 006-portfolio-import-export
**Date**: 2025-11-28

## Research Topics

### 1. iOS File Sharing Patterns

**Decision**: Use `ShareLink` (iOS 16+) for export and `fileImporter` modifier for import.

**Rationale**:
- `ShareLink` is the modern SwiftUI approach for sharing files via iOS share sheet
- `fileImporter` provides native document picker integration
- Both are declarative SwiftUI APIs that align with Constitution Principle III
- No third-party dependencies required

**Alternatives Considered**:
- UIActivityViewController via UIViewControllerRepresentable - More complex, requires bridging
- Third-party file picker libraries - Violates no-external-dependencies rule

**Implementation Notes**:
```swift
// Export via ShareLink
ShareLink(item: exportFile, preview: SharePreview("Portfolio Backup"))

// Import via fileImporter modifier
.fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json, .commaSeparatedText])
```

---

### 2. JSON Encoding/Decoding for Decimal Values

**Decision**: Use custom `Decimal` coding strategy with string representation.

**Rationale**:
- JSON number type can lose precision for large Decimal values
- String encoding preserves full Decimal precision (Constitution Principle IV)
- Enables lossless round-trip for financial data

**Alternatives Considered**:
- Default JSONEncoder (Double conversion) - Loses precision, violates Principle IV
- Scientific notation - Less human-readable in exported files
- Custom number formatter - Adds complexity without benefit

**Implementation Notes**:
```swift
// In ExportTransaction (Codable struct)
struct ExportTransaction: Codable {
    let coinId: String
    let type: String  // "buy" or "sell"
    let amount: String  // Decimal as string for precision
    let pricePerCoin: String  // Decimal as string
    let date: Date
    let notes: String?

    init(from transaction: Transaction) {
        self.amount = "\(transaction.amount)"
        self.pricePerCoin = "\(transaction.pricePerCoin)"
        // ...
    }
}
```

---

### 3. CSV Parsing Strategy

**Decision**: Build simple CSV parser in-house using Foundation string APIs.

**Rationale**:
- CSV format is simple (comma-separated, header row, optional quotes)
- Foundation provides adequate string manipulation
- Avoids external dependencies (Constitution Principle III)
- Full control over error handling and validation

**Alternatives Considered**:
- CodableCSV library - External dependency, violates Principle III
- Swift-CSV package - External dependency
- Regular expressions - Over-engineered for simple CSV

**Implementation Notes**:
```swift
final class CSVParser {
    static func parse(_ content: String) throws -> [[String: String]] {
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        guard let headerLine = lines.first else {
            throw ImportError.emptyFile
        }
        let headers = headerLine.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        // Parse remaining rows...
    }
}
```

---

### 4. File Type Registration (UTType)

**Decision**: Use built-in `.json` and `.commaSeparatedText` content types.

**Rationale**:
- Standard UTTypes are recognized by iOS
- No custom UTType registration needed for common formats
- Simpler implementation, no Info.plist changes required

**Alternatives Considered**:
- Custom UTType for `.bitpal` extension - Unnecessary complexity for testing utility
- Multiple custom types - Over-engineered

**Implementation Notes**:
```swift
import UniformTypeIdentifiers

// Allowed types for import
let allowedTypes: [UTType] = [.json, .commaSeparatedText]

// Export generates .json file
let exportURL = try createExportFile(transactions: transactions)
// URL ends with .json extension
```

---

### 5. Validation Strategy for Import

**Decision**: Two-phase validation: structural validation during parse, content validation in preview.

**Rationale**:
- Structural validation (file format, required columns) fails fast
- Content validation (data types, ranges) provides detailed per-row feedback
- Users see exactly which rows have issues before committing
- Supports partial import of valid rows (FR-006)

**Alternatives Considered**:
- All-or-nothing validation - Poor UX for files with few bad rows
- No preview (import directly) - Risky, no user confirmation
- Background validation - Adds complexity without UX benefit

**Validation Phases**:
1. **Parse phase**: File structure, JSON/CSV validity, required columns present
2. **Preview phase**:
   - Required fields not empty
   - Amount > 0 (positive decimal)
   - Price > 0 (positive decimal)
   - Date parseable (ISO 8601)
   - Type is "buy" or "sell"
   - Coin ID format (non-empty string) - NOT validated against CoinGecko per spec

---

### 6. Swift Data Transaction Extension

**Decision**: Add `Codable` conformance via extension, not model modification.

**Rationale**:
- Transaction model uses `@Model` macro which has special Codable handling
- Extension keeps export/import concerns separate from persistence
- Avoids modifying existing tested model

**Implementation Notes**:
```swift
// Create separate ExportTransaction struct that mirrors Transaction
struct ExportTransaction: Codable {
    // ... fields

    init(from transaction: Transaction) { ... }

    func toTransaction() -> Transaction { ... }
}
```

---

### 7. Error Handling Taxonomy

**Decision**: Define typed `ImportError` enum with localized descriptions.

**Rationale**:
- Clear error taxonomy aids debugging and user messaging
- Conforms to `LocalizedError` per Constitution development standards
- Specific error cases enable targeted recovery suggestions

**Error Categories**:
```swift
enum ImportError: LocalizedError {
    case emptyFile
    case invalidFormat(String)  // JSON parse error, CSV structure error
    case missingRequiredColumn(String)  // Column name
    case invalidRowData(row: Int, field: String, reason: String)
    case noValidRows
    case fileAccessDenied

    var errorDescription: String? { ... }
}
```

---

## Technology Stack Summary

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| File Sharing | ShareLink, fileImporter | Native SwiftUI, iOS 16+ |
| JSON Encoding | JSONEncoder/Decoder | Foundation, no dependencies |
| CSV Parsing | Custom (Foundation) | Simple, no dependencies |
| File Types | UTType (.json, .csv) | Standard iOS types |
| Decimal Precision | String encoding | Preserves financial precision |
| Error Handling | Typed LocalizedError | Clear user messaging |

---

## Resolved Clarifications

All technical unknowns have been resolved. No NEEDS CLARIFICATION items remain.

| Question | Resolution |
|----------|------------|
| How to preserve Decimal precision? | String encoding in JSON |
| CSV parsing library? | Built in-house with Foundation |
| File type handling? | Standard UTTypes, no custom registration |
| Validation approach? | Two-phase: structural then content |
