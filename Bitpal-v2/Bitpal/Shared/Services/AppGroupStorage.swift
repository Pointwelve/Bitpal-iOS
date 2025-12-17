//
//  AppGroupStorage.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation
import OSLog

/// Service for reading/writing widget data to the shared App Group container.
/// Uses JSON file storage for simplicity and cross-process compatibility.
/// Per research.md: JSON chosen over Swift Data for simpler read-only widget access.
final class AppGroupStorage: Sendable {
    // MARK: - Singleton

    static let shared = AppGroupStorage()

    // MARK: - Constants

    /// App Group identifier - must match entitlements in both app and widget targets
    static let appGroupIdentifier = "group.com.bitpal.shared"

    /// Filename for widget portfolio data
    private static let portfolioFilename = "portfolio.json"

    /// Filename for widget refresh data (quantities for recalculation)
    private static let refreshDataFilename = "refresh_data.json"

    /// Directory for widget data within App Group container
    private static let widgetDataDirectory = "WidgetData"

    // MARK: - Initialization

    private init() {}

    // MARK: - File Paths

    /// Returns the URL for the App Group container
    private var containerURL: URL? {
        let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        )
        if url == nil {
            Logger.widget.error("App Group container URL is nil! Check entitlements for: \(Self.appGroupIdentifier)")
        } else {
            Logger.widget.debug("App Group container: \(url!.path)")
        }
        return url
    }

    /// Returns the URL for the widget data directory
    private var widgetDataDirectoryURL: URL? {
        containerURL?.appendingPathComponent(
            "Library/Application Support/\(Self.widgetDataDirectory)",
            isDirectory: true
        )
    }

    /// Returns the URL for the portfolio JSON file
    private var portfolioFileURL: URL? {
        widgetDataDirectoryURL?.appendingPathComponent(Self.portfolioFilename)
    }

    /// Returns the URL for the refresh data JSON file
    private var refreshDataFileURL: URL? {
        widgetDataDirectoryURL?.appendingPathComponent(Self.refreshDataFilename)
    }

    // MARK: - Write Operations

    /// Writes portfolio data to the App Group container.
    /// Called by main app after portfolio updates.
    /// - Parameter data: The portfolio data to persist
    /// - Throws: AppGroupStorageError if write fails
    func writePortfolioData(_ data: WidgetPortfolioData) throws {
        guard let directoryURL = widgetDataDirectoryURL,
              let fileURL = portfolioFileURL else {
            Logger.widget.error("Failed to get App Group container URL")
            throw AppGroupStorageError.containerNotAvailable
        }

        // Create directory if needed
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(data)

        // Write atomically to prevent corruption
        try jsonData.write(to: fileURL, options: .atomic)

        Logger.widget.info("Widget data written successfully: \(data.holdings.count) holdings")
    }

    /// Writes refresh data (quantities for recalculation) to the App Group container.
    /// Called by main app after portfolio updates.
    /// - Parameter data: The refresh data to persist
    /// - Throws: AppGroupStorageError if write fails
    func writeRefreshData(_ data: WidgetRefreshData) throws {
        guard let directoryURL = widgetDataDirectoryURL,
              let fileURL = refreshDataFileURL else {
            Logger.widget.error("Failed to get App Group container URL for refresh data")
            throw AppGroupStorageError.containerNotAvailable
        }

        // Create directory if needed
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(data)

        // Write atomically to prevent corruption
        try jsonData.write(to: fileURL, options: .atomic)

        Logger.widget.info("Refresh data written successfully: \(data.holdings.count) holdings")
    }

    // MARK: - Read Operations

    /// Reads portfolio data from the App Group container.
    /// Called by widget during timeline generation.
    /// - Returns: The cached portfolio data, or nil if not available
    func readPortfolioData() -> WidgetPortfolioData? {
        guard let fileURL = portfolioFileURL else {
            Logger.widget.warning("Failed to get portfolio file URL")
            return nil
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.widget.info("No cached portfolio data found")
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let data = try decoder.decode(WidgetPortfolioData.self, from: jsonData)
            Logger.widget.info("Widget data read successfully: \(data.holdings.count) holdings")
            return data
        } catch {
            Logger.widget.error("Failed to read portfolio data: \(error.localizedDescription)")
            return nil
        }
    }

    /// Reads refresh data (quantities for recalculation) from the App Group container.
    /// Called by widget during timeline generation to get holdings for price recalculation.
    /// - Returns: The cached refresh data, or nil if not available
    func readRefreshData() -> WidgetRefreshData? {
        guard let fileURL = refreshDataFileURL else {
            Logger.widget.warning("Failed to get refresh data file URL")
            return nil
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            Logger.widget.info("No cached refresh data found")
            return nil
        }

        do {
            let jsonData = try Data(contentsOf: fileURL)

            let decoder = JSONDecoder()

            let data = try decoder.decode(WidgetRefreshData.self, from: jsonData)
            Logger.widget.info("Refresh data read successfully: \(data.holdings.count) holdings")
            return data
        } catch {
            Logger.widget.error("Failed to read refresh data: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Cleanup

    /// Removes cached portfolio data from the App Group container.
    /// Called when user clears all data or signs out.
    func clearPortfolioData() throws {
        guard let fileURL = portfolioFileURL else {
            return // Nothing to clear
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // File doesn't exist
        }

        try FileManager.default.removeItem(at: fileURL)
        Logger.widget.info("Widget data cleared")
    }

    /// Removes cached refresh data from the App Group container.
    /// Called when user clears all data or signs out.
    func clearRefreshData() throws {
        guard let fileURL = refreshDataFileURL else {
            return // Nothing to clear
        }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return // File doesn't exist
        }

        try FileManager.default.removeItem(at: fileURL)
        Logger.widget.info("Refresh data cleared")
    }

    /// Clears all widget-related data (portfolio and refresh data).
    /// Called when user clears all data or signs out.
    func clearAllWidgetData() throws {
        try clearPortfolioData()
        try clearRefreshData()
        Logger.widget.info("All widget data cleared")
    }
}

// MARK: - Errors

enum AppGroupStorageError: LocalizedError {
    case containerNotAvailable
    case encodingFailed
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "App Group container is not available. Check entitlements."
        case .encodingFailed:
            return "Failed to encode portfolio data to JSON."
        case .writeFailed(let error):
            return "Failed to write data: \(error.localizedDescription)"
        }
    }
}
