//
//  ImportExportService.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import Foundation
import OSLog
import UniformTypeIdentifiers

/// Singleton service for portfolio import/export operations
/// Per Constitution Principle III: Singleton pattern for services
final class ImportExportService {
    static let shared = ImportExportService()
    private init() {}

    // MARK: - Export

    /// Export transactions to JSON data
    /// - Parameter transactions: Array of transactions to export
    /// - Returns: JSON data ready to be written to file
    /// - Throws: Encoding errors
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

        Logger.persistence.info("Exporting \(transactions.count) transactions")
        return try encoder.encode(exportFile)
    }

    /// Create temporary file URL for export
    /// - Parameter data: JSON data to write
    /// - Returns: URL to temporary file
    /// - Throws: File write errors
    func createExportURL(data: Data) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "bitpal-portfolio-\(dateFormatter.string(from: Date())).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)

        Logger.persistence.info("Created export file at \(tempURL.path)")
        return tempURL
    }

    // MARK: - Import

    /// Parse import file and create preview
    /// - Parameter url: URL to import file (JSON or CSV)
    /// - Returns: ImportPreview with valid and invalid rows
    /// - Throws: ImportError for parsing failures
    func parseFile(at url: URL) throws -> ImportPreview {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileAccessDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let fileName = url.lastPathComponent

        Logger.persistence.info("Parsing import file: \(fileName)")

        if url.pathExtension.lowercased() == "csv" {
            return try parseCSV(data: data, fileName: fileName)
        } else {
            return try parseJSON(data: data, fileName: fileName)
        }
    }

    // MARK: - Private JSON Parsing

    private func parseJSON(data: Data, fileName: String) throws -> ImportPreview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportFile: ExportFile
        do {
            exportFile = try decoder.decode(ExportFile.self, from: data)
        } catch {
            throw ImportError.invalidFormat("Invalid JSON structure: \(error.localizedDescription)")
        }

        guard !exportFile.transactions.isEmpty else {
            throw ImportError.emptyFile
        }

        let rows = exportFile.transactions.enumerated().map { index, tx in
            validateJSONRow(
                rowNumber: index + 1,
                coinId: tx.coinId,
                typeString: tx.type,
                amountString: tx.amount,
                priceString: tx.pricePerCoin,
                date: tx.date,
                notes: tx.notes
            )
        }

        let validRows = rows.filter { $0.isValid }
        let invalidRows = rows.filter { !$0.isValid }

        Logger.persistence.info("JSON parse complete: \(validRows.count) valid, \(invalidRows.count) invalid rows")

        return ImportPreview(
            sourceType: .json,
            fileName: fileName,
            validRows: validRows,
            invalidRows: invalidRows
        )
    }

    private func validateJSONRow(
        rowNumber: Int,
        coinId: String,
        typeString: String,
        amountString: String,
        priceString: String,
        date: Date,
        notes: String?
    ) -> ImportRow {
        var errors: [String] = []

        // Validate coinId
        let trimmedCoinId = coinId.trimmingCharacters(in: .whitespaces)
        if trimmedCoinId.isEmpty {
            errors.append("Missing coin ID")
        }

        // Validate type
        let type = TransactionType(rawValue: typeString.lowercased())
        if type == nil {
            errors.append("Invalid type '\(typeString)' (must be 'buy' or 'sell')")
        }

        // Validate amount
        let amount = Decimal(string: amountString)
        if amount == nil {
            errors.append("Invalid amount '\(amountString)'")
        } else if amount! <= 0 {
            errors.append("Amount must be positive")
        }

        // Validate price
        let price = Decimal(string: priceString)
        if price == nil {
            errors.append("Invalid price '\(priceString)'")
        } else if price! <= 0 {
            errors.append("Price must be positive")
        }

        return ImportRow(
            rowNumber: rowNumber,
            coinId: trimmedCoinId,
            type: type,
            amount: amount,
            pricePerCoin: price,
            date: date,
            notes: notes,
            errors: errors
        )
    }

    // MARK: - Private CSV Parsing

    private func parseCSV(data: Data, fileName: String) throws -> ImportPreview {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat("Unable to read file as text")
        }

        let rows = try CSVParser.parse(content)

        guard !rows.isEmpty else {
            throw ImportError.emptyFile
        }

        let importRows = rows.enumerated().map { index, row in
            validateCSVRow(rowNumber: index + 2, row: row) // +2 for 1-based + header offset
        }

        let validRows = importRows.filter { $0.isValid }
        let invalidRows = importRows.filter { !$0.isValid }

        Logger.persistence.info("CSV parse complete: \(validRows.count) valid, \(invalidRows.count) invalid rows")

        return ImportPreview(
            sourceType: .csv,
            fileName: fileName,
            validRows: validRows,
            invalidRows: invalidRows
        )
    }

    private func validateCSVRow(rowNumber: Int, row: [String: String]) -> ImportRow {
        var errors: [String] = []

        // Extract and validate coinId
        let coinId = row["coin_id"]?.trimmingCharacters(in: .whitespaces) ?? ""
        if coinId.isEmpty {
            errors.append("Missing coin_id")
        }

        // Extract and validate type
        let typeString = row["type"]?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        let type = TransactionType(rawValue: typeString)
        if type == nil && !typeString.isEmpty {
            errors.append("Invalid type '\(typeString)' (must be 'buy' or 'sell')")
        } else if typeString.isEmpty {
            errors.append("Missing type")
        }

        // Extract and validate amount
        let amountString = row["amount"]?.trimmingCharacters(in: .whitespaces) ?? ""
        var amount: Decimal?
        if amountString.isEmpty {
            errors.append("Missing amount")
        } else if let parsed = Decimal(string: amountString) {
            if parsed <= 0 {
                errors.append("Amount must be positive")
            } else {
                amount = parsed
            }
        } else {
            errors.append("Invalid amount '\(amountString)'")
        }

        // Extract and validate price
        let priceString = row["price"]?.trimmingCharacters(in: .whitespaces) ?? ""
        var price: Decimal?
        if priceString.isEmpty {
            errors.append("Missing price")
        } else if let parsed = Decimal(string: priceString) {
            if parsed <= 0 {
                errors.append("Price must be positive")
            } else {
                price = parsed
            }
        } else {
            errors.append("Invalid price '\(priceString)'")
        }

        // Extract and validate date
        let dateString = row["date"]?.trimmingCharacters(in: .whitespaces) ?? ""
        var date: Date?
        if dateString.isEmpty {
            errors.append("Missing date")
        } else {
            date = parseDate(dateString)
            if date == nil {
                errors.append("Invalid date '\(dateString)' (use YYYY-MM-DD or ISO 8601)")
            }
        }

        // Extract notes (optional)
        let notes = row["notes"]?.trimmingCharacters(in: .whitespaces)
        let finalNotes = (notes?.isEmpty ?? true) ? nil : notes

        return ImportRow(
            rowNumber: rowNumber,
            coinId: coinId,
            type: type,
            amount: amount,
            pricePerCoin: price,
            date: date,
            notes: finalNotes,
            errors: errors
        )
    }

    /// Parse date string supporting multiple formats
    private func parseDate(_ string: String) -> Date? {
        // Try ISO 8601 first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try without fractional seconds
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        if let date = iso8601Formatter.date(from: string) {
            return date
        }

        // Try simple date format YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateFormatter.date(from: string) {
            return date
        }

        // Try with time
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: string) {
            return date
        }

        return nil
    }
}
