# Quickstart: Portfolio Import/Export

**Feature**: 006-portfolio-import-export
**Date**: 2025-11-28

## Overview

This feature adds import/export functionality to the Portfolio tab, enabling users to backup transactions to JSON files and import from JSON or CSV files.

## Implementation Order

```
1. Models (ExportFile, ImportRow, ImportError)
2. ImportExportService (core logic)
3. CSVParser (utility)
4. ImportPreviewViewModel
5. Views (Menu, Preview)
6. Integration with PortfolioView
7. Tests
```

## Quick Implementation Guide

### Step 1: Create Export Models

**File**: `Bitpal/Features/Portfolio/Models/ExportFile.swift`

```swift
import Foundation

struct ExportFile: Codable {
    let version: String
    let exportDate: Date
    let appVersion: String
    let transactions: [ExportTransaction]

    static let currentVersion = "1.0"
}

struct ExportTransaction: Codable {
    let id: UUID
    let coinId: String
    let type: String
    let amount: String      // Decimal as string
    let pricePerCoin: String // Decimal as string
    let date: Date
    let notes: String?

    init(from transaction: Transaction) {
        self.id = transaction.id
        self.coinId = transaction.coinId
        self.type = transaction.type.rawValue
        self.amount = "\(transaction.amount)"
        self.pricePerCoin = "\(transaction.pricePerCoin)"
        self.date = transaction.date
        self.notes = transaction.notes
    }
}
```

### Step 2: Create Import Models

**File**: `Bitpal/Features/Portfolio/Models/ImportPreview.swift`

```swift
import Foundation

struct ImportPreview {
    let sourceType: ImportSourceType
    let fileName: String
    let validRows: [ImportRow]
    let invalidRows: [ImportRow]

    var hasValidData: Bool { !validRows.isEmpty }
}

enum ImportSourceType: String {
    case json, csv
}

struct ImportRow: Identifiable {
    let id = UUID()
    let rowNumber: Int
    let coinId: String
    let type: TransactionType?
    let amount: Decimal?
    let pricePerCoin: Decimal?
    let date: Date?
    let notes: String?
    let errors: [String]

    var isValid: Bool { errors.isEmpty }

    func toTransaction() -> Transaction? {
        guard isValid, let type, let amount, let pricePerCoin, let date else { return nil }
        return Transaction(coinId: coinId, type: type, amount: amount,
                          pricePerCoin: pricePerCoin, date: date, notes: notes)
    }
}
```

### Step 3: Create ImportExportService

**File**: `Bitpal/Features/Portfolio/Services/ImportExportService.swift`

```swift
import Foundation
import UniformTypeIdentifiers

final class ImportExportService {
    static let shared = ImportExportService()
    private init() {}

    // MARK: - Export

    func exportTransactions(_ transactions: [Transaction]) throws -> Data {
        let exportFile = ExportFile(
            version: ExportFile.currentVersion,
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            transactions: transactions.map { ExportTransaction(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportFile)
    }

    func createExportURL(data: Data) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "bitpal-portfolio-\(dateFormatter.string(from: Date())).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        return tempURL
    }

    // MARK: - Import

    func parseFile(at url: URL) throws -> ImportPreview {
        let data = try Data(contentsOf: url)
        let fileName = url.lastPathComponent

        if url.pathExtension.lowercased() == "csv" {
            return try parseCSV(data: data, fileName: fileName)
        } else {
            return try parseJSON(data: data, fileName: fileName)
        }
    }

    private func parseJSON(data: Data, fileName: String) throws -> ImportPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportFile = try decoder.decode(ExportFile.self, from: data)
        let rows = exportFile.transactions.enumerated().map { index, tx in
            validateRow(
                rowNumber: index + 1,
                coinId: tx.coinId,
                typeString: tx.type,
                amountString: tx.amount,
                priceString: tx.pricePerCoin,
                date: tx.date,
                notes: tx.notes
            )
        }

        return ImportPreview(
            sourceType: .json,
            fileName: fileName,
            validRows: rows.filter { $0.isValid },
            invalidRows: rows.filter { !$0.isValid }
        )
    }

    private func parseCSV(data: Data, fileName: String) throws -> ImportPreview {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat("Unable to read file as text")
        }

        let rows = try CSVParser.parse(content)
        let importRows = rows.enumerated().map { index, row in
            validateCSVRow(rowNumber: index + 2, row: row) // +2 for header offset
        }

        return ImportPreview(
            sourceType: .csv,
            fileName: fileName,
            validRows: importRows.filter { $0.isValid },
            invalidRows: importRows.filter { !$0.isValid }
        )
    }
}
```

### Step 4: Create CSV Parser

**File**: `Bitpal/Utilities/CSVParser.swift`

```swift
import Foundation

enum CSVParser {
    static func parse(_ content: String) throws -> [[String: String]] {
        var lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            throw ImportError.emptyFile
        }

        let headers = parseCSVLine(headerLine).map { $0.lowercased() }

        // Validate required columns
        let required = ["coin_id", "type", "amount", "price", "date"]
        for column in required {
            if !headers.contains(column) {
                throw ImportError.missingRequiredColumn(column)
            }
        }

        lines.removeFirst()

        return lines.map { line in
            let values = parseCSVLine(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < values.count {
                row[header] = values[index]
            }
            return row
        }
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        // Simple CSV parsing with quote support
        var values: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                values.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        values.append(current.trimmingCharacters(in: .whitespaces))

        return values
    }
}
```

### Step 5: Add Menu to PortfolioView

**File**: Update `Bitpal/Features/Portfolio/Views/PortfolioView.swift`

```swift
// Add toolbar menu
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu {
            Button {
                showingExport = true
            } label: {
                Label("Export Portfolio", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.isEmpty)

            Button {
                showingImporter = true
            } label: {
                Label("Import Portfolio", systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
.fileImporter(
    isPresented: $showingImporter,
    allowedContentTypes: [.json, .commaSeparatedText]
) { result in
    // Handle import
}
```

## Key Files to Create

| File | Purpose |
|------|---------|
| `Models/ExportFile.swift` | Export wrapper + ExportTransaction |
| `Models/ImportPreview.swift` | Import preview + ImportRow |
| `Models/ImportError.swift` | Typed import errors |
| `Services/ImportExportService.swift` | Core import/export logic |
| `Utilities/CSVParser.swift` | CSV parsing utility |
| `ViewModels/ImportPreviewViewModel.swift` | Preview state management |
| `Views/ImportPreviewView.swift` | Preview UI before confirm |

## Testing Checklist

- [ ] Export creates valid JSON
- [ ] Import JSON round-trip preserves all fields
- [ ] Import CSV with valid data works
- [ ] Import CSV with invalid rows shows errors
- [ ] Empty portfolio shows disabled export
- [ ] Large file (500+ transactions) completes in <3s
- [ ] Decimal precision preserved (test with 0.00000001)
