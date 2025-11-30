//
//  CSVParser.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import Foundation

/// CSV parsing utility
/// Per research.md: Build simple CSV parser in-house using Foundation string APIs
enum CSVParser {
    /// Required columns for CSV import
    static let requiredColumns = ["coin_id", "type", "amount", "price", "date"]

    /// Parse CSV content into array of row dictionaries
    /// - Parameter content: Raw CSV string content
    /// - Returns: Array of dictionaries where keys are column headers (lowercased)
    /// - Throws: ImportError if file is empty or missing required columns
    static func parse(_ content: String) throws -> [[String: String]] {
        var lines = content.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard let headerLine = lines.first else {
            throw ImportError.emptyFile
        }

        let headers = parseCSVLine(headerLine).map { $0.lowercased() }

        // Validate required columns
        for column in requiredColumns {
            if !headers.contains(column) {
                throw ImportError.missingRequiredColumn(column)
            }
        }

        lines.removeFirst()

        guard !lines.isEmpty else {
            throw ImportError.emptyFile
        }

        return lines.map { line in
            let values = parseCSVLine(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() where index < values.count {
                row[header] = values[index]
            }
            return row
        }
    }

    /// Parse a single CSV line with quote support
    /// - Parameter line: Single line from CSV file
    /// - Returns: Array of values
    private static func parseCSVLine(_ line: String) -> [String] {
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
