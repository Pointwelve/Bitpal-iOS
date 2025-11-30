//
//  CSVParserTests.swift
//  BitpalTests
//
//  Created by Claude Code on 2025-11-28.
//

import XCTest
@testable import Bitpal

/// Unit tests for CSVParser
/// Per Constitution Principle IV: Tests REQUIRED for CSV parsing
final class CSVParserTests: XCTestCase {

    // MARK: - T028: Valid CSV Parsing Tests

    func testParseValidCSV() throws {
        // Given: Valid CSV content
        let csv = """
        coin_id,type,amount,price,date,notes
        bitcoin,buy,1.5,45000,2025-01-10,First purchase
        ethereum,buy,10,3000,2025-01-11,DCA
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Rows are parsed correctly
        XCTAssertEqual(rows.count, 2)

        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["type"], "buy")
        XCTAssertEqual(rows[0]["amount"], "1.5")
        XCTAssertEqual(rows[0]["price"], "45000")
        XCTAssertEqual(rows[0]["date"], "2025-01-10")
        XCTAssertEqual(rows[0]["notes"], "First purchase")

        XCTAssertEqual(rows[1]["coin_id"], "ethereum")
        XCTAssertEqual(rows[1]["type"], "buy")
        XCTAssertEqual(rows[1]["amount"], "10")
        XCTAssertEqual(rows[1]["price"], "3000")
    }

    func testParseCSVWithMinimalColumns() throws {
        // Given: CSV with only required columns
        let csv = """
        coin_id,type,amount,price,date
        bitcoin,buy,1,50000,2025-01-15
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Parses successfully
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertNil(rows[0]["notes"]) // Optional column not present
    }

    func testParseEmptyCSVThrowsError() {
        // Given: Empty content
        let csv = ""

        // When/Then: Throws emptyFile error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            XCTAssertEqual(error as? ImportError, ImportError.emptyFile)
        }
    }

    func testParseHeaderOnlyCSVThrowsError() {
        // Given: Only header, no data
        let csv = "coin_id,type,amount,price,date"

        // When/Then: Throws emptyFile error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            XCTAssertEqual(error as? ImportError, ImportError.emptyFile)
        }
    }

    // MARK: - T029: Missing Column Detection Tests

    func testParseMissingCoinIdColumnThrowsError() {
        // Given: CSV missing coin_id column
        let csv = """
        type,amount,price,date
        buy,1,50000,2025-01-15
        """

        // When/Then: Throws missingRequiredColumn error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "coin_id")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    func testParseMissingTypeColumnThrowsError() {
        // Given: CSV missing type column
        let csv = """
        coin_id,amount,price,date
        bitcoin,1,50000,2025-01-15
        """

        // When/Then: Throws missingRequiredColumn error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "type")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    func testParseMissingAmountColumnThrowsError() {
        // Given: CSV missing amount column
        let csv = """
        coin_id,type,price,date
        bitcoin,buy,50000,2025-01-15
        """

        // When/Then: Throws missingRequiredColumn error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "amount")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    func testParseMissingPriceColumnThrowsError() {
        // Given: CSV missing price column
        let csv = """
        coin_id,type,amount,date
        bitcoin,buy,1,2025-01-15
        """

        // When/Then: Throws missingRequiredColumn error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "price")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    func testParseMissingDateColumnThrowsError() {
        // Given: CSV missing date column
        let csv = """
        coin_id,type,amount,price
        bitcoin,buy,1,50000
        """

        // When/Then: Throws missingRequiredColumn error
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "date")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    // MARK: - T030: Quoted Values Parsing Tests

    func testParseQuotedValuesWithCommas() throws {
        // Given: CSV with quoted notes containing commas
        let csv = """
        coin_id,type,amount,price,date,notes
        bitcoin,buy,1,50000,2025-01-15,"First purchase, very exciting!"
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Quoted value with comma is preserved
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["notes"], "First purchase, very exciting!")
    }

    func testParseMultipleQuotedFields() throws {
        // Given: CSV with multiple quoted fields
        let csv = """
        coin_id,type,amount,price,date,notes
        "bitcoin",buy,"1.5","50000",2025-01-15,"My notes, with comma"
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: All quoted values are parsed correctly
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["amount"], "1.5")
        XCTAssertEqual(rows[0]["price"], "50000")
        XCTAssertEqual(rows[0]["notes"], "My notes, with comma")
    }

    func testParseQuotedValuesWithSpaces() throws {
        // Given: CSV with quoted values containing leading/trailing spaces
        let csv = """
        coin_id,type,amount,price,date,notes
        bitcoin,buy,1,50000,2025-01-15,"  note with spaces  "
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Spaces inside quotes are preserved, outside are trimmed
        XCTAssertEqual(rows[0]["notes"], "  note with spaces  ")
    }

    // MARK: - T031: Case-Insensitive Header Tests

    func testParseUppercaseHeaders() throws {
        // Given: CSV with uppercase headers
        let csv = """
        COIN_ID,TYPE,AMOUNT,PRICE,DATE,NOTES
        bitcoin,buy,1,50000,2025-01-15,Test
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Headers are normalized to lowercase
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["type"], "buy")
    }

    func testParseMixedCaseHeaders() throws {
        // Given: CSV with mixed case headers
        let csv = """
        Coin_Id,Type,Amount,Price,Date,Notes
        ethereum,sell,5,3500,2025-01-15,Profit taking
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Headers are normalized to lowercase
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "ethereum")
        XCTAssertEqual(rows[0]["type"], "sell")
    }

    func testParseCamelCaseHeaders() throws {
        // Given: CSV with camelCase headers (should fail because underscore is required)
        let csv = """
        coinId,type,amount,price,date
        bitcoin,buy,1,50000,2025-01-15
        """

        // When/Then: Throws missingRequiredColumn for coin_id
        XCTAssertThrowsError(try CSVParser.parse(csv)) { error in
            if case ImportError.missingRequiredColumn(let column) = error {
                XCTAssertEqual(column, "coin_id")
            } else {
                XCTFail("Expected missingRequiredColumn error")
            }
        }
    }

    // MARK: - Edge Cases

    func testParseCSVWithExtraColumns() throws {
        // Given: CSV with extra columns beyond required
        let csv = """
        coin_id,type,amount,price,date,notes,extra_column,another
        bitcoin,buy,1,50000,2025-01-15,Test,value1,value2
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Extra columns are included in the result
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["extra_column"], "value1")
        XCTAssertEqual(rows[0]["another"], "value2")
    }

    func testParseCSVWithBlankLines() throws {
        // Given: CSV with blank lines
        let csv = """
        coin_id,type,amount,price,date
        bitcoin,buy,1,50000,2025-01-15

        ethereum,buy,10,3000,2025-01-16

        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Blank lines are skipped
        XCTAssertEqual(rows.count, 2)
    }

    func testParseCSVWithWhitespaceAroundValues() throws {
        // Given: CSV with whitespace around values
        let csv = """
        coin_id , type , amount , price , date
        bitcoin , buy , 1.5 , 50000 , 2025-01-15
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Whitespace is trimmed
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["type"], "buy")
        XCTAssertEqual(rows[0]["amount"], "1.5")
    }

    func testParseCSVWithMissingValues() throws {
        // Given: CSV with some missing values in a row
        let csv = """
        coin_id,type,amount,price,date,notes
        bitcoin,buy,1,50000,2025-01-15,
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Empty values are captured as empty strings
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["notes"], "")
    }

    func testParseCSVWithDifferentColumnOrder() throws {
        // Given: CSV with columns in different order
        let csv = """
        notes,date,price,amount,type,coin_id
        Test,2025-01-15,50000,1,buy,bitcoin
        """

        // When: Parsing
        let rows = try CSVParser.parse(csv)

        // Then: Columns are mapped correctly regardless of order
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0]["coin_id"], "bitcoin")
        XCTAssertEqual(rows[0]["type"], "buy")
        XCTAssertEqual(rows[0]["amount"], "1")
        XCTAssertEqual(rows[0]["price"], "50000")
        XCTAssertEqual(rows[0]["date"], "2025-01-15")
        XCTAssertEqual(rows[0]["notes"], "Test")
    }
}
