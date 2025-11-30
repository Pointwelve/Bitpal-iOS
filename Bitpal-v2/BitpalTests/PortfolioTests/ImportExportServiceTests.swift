//
//  ImportExportServiceTests.swift
//  BitpalTests
//
//  Created by Claude Code on 2025-11-28.
//

import XCTest
@testable import Bitpal

/// Unit tests for ImportExportService
/// Per Constitution Principle IV: Tests REQUIRED for round-trip data integrity
final class ImportExportServiceTests: XCTestCase {

    let service = ImportExportService.shared

    // MARK: - T007: Export JSON Encoding Tests

    func testExportEncodesDecimalsAsStrings() throws {
        // Given: A transaction with precise decimal values
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "0.12345678")!,
            pricePerCoin: Decimal(string: "45678.99")!,
            date: Date()
        )

        // When: Exporting to JSON
        let jsonData = try service.exportTransactions([transaction])
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let transactions = json["transactions"] as! [[String: Any]]
        let firstTx = transactions[0]

        // Then: Decimal values are encoded as strings to preserve precision
        XCTAssertEqual(firstTx["amount"] as? String, "0.12345678")
        XCTAssertEqual(firstTx["pricePerCoin"] as? String, "45678.99")
    }

    func testExportIncludesMetadata() throws {
        // Given: Transactions to export
        let transaction = Transaction(
            coinId: "ethereum",
            type: .sell,
            amount: Decimal(2),
            pricePerCoin: Decimal(3500),
            date: Date()
        )

        // When: Exporting to JSON
        let jsonData = try service.exportTransactions([transaction])
        let json = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

        // Then: Metadata is present
        XCTAssertEqual(json["version"] as? String, "1.0")
        XCTAssertNotNil(json["exportDate"])
        XCTAssertNotNil(json["appVersion"])
    }

    func testExportPreservesAllFields() throws {
        // Given: A transaction with all fields including notes
        let id = UUID()
        let date = Date()
        let transaction = Transaction(
            id: id,
            coinId: "cardano",
            type: .buy,
            amount: Decimal(1000),
            pricePerCoin: Decimal(string: "0.45")!,
            date: date,
            notes: "DCA purchase"
        )

        // When: Exporting to JSON
        let jsonData = try service.exportTransactions([transaction])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportFile = try decoder.decode(ExportFile.self, from: jsonData)

        // Then: All fields are preserved
        XCTAssertEqual(exportFile.transactions.count, 1)
        let exported = exportFile.transactions[0]
        XCTAssertEqual(exported.id, id)
        XCTAssertEqual(exported.coinId, "cardano")
        XCTAssertEqual(exported.type, "buy")
        XCTAssertEqual(exported.amount, "1000")
        XCTAssertEqual(exported.pricePerCoin, "0.45")
        XCTAssertEqual(exported.notes, "DCA purchase")
    }

    func testExportMultipleTransactions() throws {
        // Given: Multiple transactions
        let transactions = [
            Transaction(
                coinId: "bitcoin",
                type: .buy,
                amount: Decimal(1),
                pricePerCoin: Decimal(40000),
                date: Date()
            ),
            Transaction(
                coinId: "ethereum",
                type: .buy,
                amount: Decimal(10),
                pricePerCoin: Decimal(3000),
                date: Date()
            ),
            Transaction(
                coinId: "bitcoin",
                type: .sell,
                amount: Decimal(string: "0.5")!,
                pricePerCoin: Decimal(45000),
                date: Date()
            )
        ]

        // When: Exporting
        let jsonData = try service.exportTransactions(transactions)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportFile = try decoder.decode(ExportFile.self, from: jsonData)

        // Then: All transactions are exported
        XCTAssertEqual(exportFile.transactions.count, 3)
    }

    // MARK: - T008: Round-Trip Integrity Tests

    func testRoundTripPreservesAllFields() throws {
        // Given: A transaction with all fields
        let originalId = UUID()
        let originalDate = Date()
        let originalTransaction = Transaction(
            id: originalId,
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(string: "1.23456789")!,
            pricePerCoin: Decimal(string: "45678.12")!,
            date: originalDate,
            notes: "Test transaction"
        )

        // When: Export and then parse the JSON
        let jsonData = try service.exportTransactions([originalTransaction])

        // Create a temporary file for import
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-roundtrip.json")
        try jsonData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try service.parseFile(at: tempURL)

        // Then: All fields are preserved exactly
        XCTAssertEqual(preview.validRows.count, 1)
        XCTAssertEqual(preview.invalidRows.count, 0)

        let importedRow = preview.validRows[0]
        XCTAssertEqual(importedRow.coinId, "bitcoin")
        XCTAssertEqual(importedRow.type, .buy)
        XCTAssertEqual(importedRow.amount, Decimal(string: "1.23456789")!)
        XCTAssertEqual(importedRow.pricePerCoin, Decimal(string: "45678.12")!)
        XCTAssertEqual(importedRow.notes, "Test transaction")

        // Verify the row can be converted to a Transaction
        let convertedTransaction = importedRow.toTransaction()
        XCTAssertNotNil(convertedTransaction)
        XCTAssertEqual(convertedTransaction?.coinId, originalTransaction.coinId)
        XCTAssertEqual(convertedTransaction?.type, originalTransaction.type)
        XCTAssertEqual(convertedTransaction?.amount, originalTransaction.amount)
        XCTAssertEqual(convertedTransaction?.pricePerCoin, originalTransaction.pricePerCoin)
        XCTAssertEqual(convertedTransaction?.notes, originalTransaction.notes)
    }

    func testRoundTripPreservesDecimalPrecision() throws {
        // Given: Transactions with high precision decimals
        let transactions = [
            Transaction(
                coinId: "bitcoin",
                type: .buy,
                amount: Decimal(string: "0.00000001")!, // 1 satoshi
                pricePerCoin: Decimal(string: "99999.99")!,
                date: Date()
            ),
            Transaction(
                coinId: "ethereum",
                type: .sell,
                amount: Decimal(string: "123.456789012345")!,
                pricePerCoin: Decimal(string: "0.000001")!,
                date: Date()
            )
        ]

        // When: Round-trip through JSON
        let jsonData = try service.exportTransactions(transactions)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-precision.json")
        try jsonData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try service.parseFile(at: tempURL)

        // Then: Decimal precision is preserved
        XCTAssertEqual(preview.validRows.count, 2)

        // Check first transaction
        XCTAssertEqual(preview.validRows[0].amount, Decimal(string: "0.00000001")!)
        XCTAssertEqual(preview.validRows[0].pricePerCoin, Decimal(string: "99999.99")!)

        // Check second transaction
        XCTAssertEqual(preview.validRows[1].amount, Decimal(string: "123.456789012345")!)
        XCTAssertEqual(preview.validRows[1].pricePerCoin, Decimal(string: "0.000001")!)
    }

    func testRoundTripWithSellTransactions() throws {
        // Given: Sell transactions
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .sell,
            amount: Decimal(string: "0.5")!,
            pricePerCoin: Decimal(50000),
            date: Date(),
            notes: "Taking profits"
        )

        // When: Round-trip
        let jsonData = try service.exportTransactions([transaction])
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-sell.json")
        try jsonData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try service.parseFile(at: tempURL)

        // Then: Sell type is preserved
        XCTAssertEqual(preview.validRows[0].type, .sell)
    }

    func testRoundTripWithNilNotes() throws {
        // Given: Transaction without notes
        let transaction = Transaction(
            coinId: "dogecoin",
            type: .buy,
            amount: Decimal(10000),
            pricePerCoin: Decimal(string: "0.1")!,
            date: Date(),
            notes: nil
        )

        // When: Round-trip
        let jsonData = try service.exportTransactions([transaction])
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-nil-notes.json")
        try jsonData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let preview = try service.parseFile(at: tempURL)

        // Then: Nil notes is preserved
        XCTAssertNil(preview.validRows[0].notes)
    }

    // MARK: - Export File URL Tests

    func testCreateExportURLCreatesFile() throws {
        // Given: JSON data
        let transaction = Transaction(
            coinId: "bitcoin",
            type: .buy,
            amount: Decimal(1),
            pricePerCoin: Decimal(50000),
            date: Date()
        )
        let jsonData = try service.exportTransactions([transaction])

        // When: Creating export URL
        let url = try service.createExportURL(data: jsonData)
        defer { try? FileManager.default.removeItem(at: url) }

        // Then: File exists and is readable
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let readData = try Data(contentsOf: url)
        XCTAssertEqual(readData, jsonData)
    }

    func testExportFileNameFormat() throws {
        // Given: JSON data
        let jsonData = try service.exportTransactions([])

        // When: Creating export URL
        let url = try service.createExportURL(data: jsonData)
        defer { try? FileManager.default.removeItem(at: url) }

        // Then: Filename matches expected pattern
        let filename = url.lastPathComponent
        XCTAssertTrue(filename.hasPrefix("bitpal-portfolio-"))
        XCTAssertTrue(filename.hasSuffix(".json"))
    }

    // MARK: - JSON Import Tests

    func testParseValidJSON() throws {
        // Given: Valid JSON export data
        let jsonString = """
        {
            "version": "1.0",
            "exportDate": "2025-01-15T10:30:00Z",
            "appVersion": "1.0",
            "transactions": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "coinId": "bitcoin",
                    "type": "buy",
                    "amount": "1.5",
                    "pricePerCoin": "45000.50",
                    "date": "2025-01-10T09:00:00Z",
                    "notes": "First purchase"
                }
            ]
        }
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-valid.json")
        try jsonString.data(using: .utf8)!.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // When: Parsing the file
        let preview = try service.parseFile(at: tempURL)

        // Then: Parse succeeds with correct values
        XCTAssertEqual(preview.sourceType, .json)
        XCTAssertEqual(preview.validRows.count, 1)
        XCTAssertEqual(preview.invalidRows.count, 0)
        XCTAssertTrue(preview.hasValidData)

        let row = preview.validRows[0]
        XCTAssertEqual(row.coinId, "bitcoin")
        XCTAssertEqual(row.type, .buy)
        XCTAssertEqual(row.amount, Decimal(string: "1.5")!)
        XCTAssertEqual(row.pricePerCoin, Decimal(string: "45000.50")!)
        XCTAssertEqual(row.notes, "First purchase")
    }

    func testParseInvalidJSONThrowsError() {
        // Given: Invalid JSON
        let invalidJSON = "{ invalid json }"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-invalid.json")
        try? invalidJSON.data(using: .utf8)!.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // When/Then: Parsing throws error
        XCTAssertThrowsError(try service.parseFile(at: tempURL)) { error in
            XCTAssertTrue(error is ImportError)
            if case ImportError.invalidFormat = error {
                // Expected
            } else {
                XCTFail("Expected invalidFormat error")
            }
        }
    }

    func testParseJSONWithInvalidRows() throws {
        // Given: JSON with some invalid rows
        let jsonString = """
        {
            "version": "1.0",
            "exportDate": "2025-01-15T10:30:00Z",
            "appVersion": "1.0",
            "transactions": [
                {
                    "id": "550e8400-e29b-41d4-a716-446655440000",
                    "coinId": "bitcoin",
                    "type": "buy",
                    "amount": "1.5",
                    "pricePerCoin": "45000",
                    "date": "2025-01-10T09:00:00Z",
                    "notes": null
                },
                {
                    "id": "550e8400-e29b-41d4-a716-446655440001",
                    "coinId": "",
                    "type": "invalid",
                    "amount": "notanumber",
                    "pricePerCoin": "-100",
                    "date": "2025-01-10T09:00:00Z",
                    "notes": null
                }
            ]
        }
        """

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test-mixed.json")
        try jsonString.data(using: .utf8)!.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // When: Parsing the file
        let preview = try service.parseFile(at: tempURL)

        // Then: Valid and invalid rows are separated
        XCTAssertEqual(preview.validRows.count, 1)
        XCTAssertEqual(preview.invalidRows.count, 1)

        // Check invalid row has errors
        let invalidRow = preview.invalidRows[0]
        XCTAssertFalse(invalidRow.isValid)
        XCTAssertFalse(invalidRow.errors.isEmpty)
    }
}
