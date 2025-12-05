//
//  PortfolioTimelineProvider.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import WidgetKit
import OSLog

/// Timeline provider for portfolio widgets.
/// Reads cached data from App Group and generates timeline entries.
/// Per FR-004: Refreshes every 30 minutes (maximum WidgetKit allows).
struct PortfolioTimelineProvider: TimelineProvider {
    // MARK: - Dependencies

    private let storage = AppGroupStorage.shared

    // MARK: - TimelineProvider Protocol

    /// Provides a placeholder entry for the widget gallery.
    /// Per WidgetKit: Should return immediately with sample data.
    func placeholder(in context: Context) -> PortfolioEntry {
        Logger.widget.debug("Generating placeholder entry")
        return .placeholder()
    }

    /// Provides a snapshot entry for widget gallery preview.
    /// Per WidgetKit: Should return quickly with representative data.
    func getSnapshot(in context: Context, completion: @escaping (PortfolioEntry) -> Void) {
        Logger.widget.debug("Generating snapshot entry")

        // Use sample data for gallery preview, real data for home screen
        if context.isPreview {
            completion(.snapshot())
        } else {
            let entry = createEntryFromStorage()
            completion(entry)
        }
    }

    /// Provides timeline entries for the widget.
    /// Creates multiple entries at 15-minute intervals so widget appears to refresh when viewed.
    func getTimeline(in context: Context, completion: @escaping (Timeline<PortfolioEntry>) -> Void) {
        Logger.widget.info("Generating timeline")

        let currentDate = Date()
        let data = storage.readPortfolioData()

        // Create entries for the next 2 hours at 15-minute intervals
        // This allows widget to "update" when viewed if time has passed
        var entries: [PortfolioEntry] = []
        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = currentDate.addingTimeInterval(Double(minuteOffset) * 60)
            let entry: PortfolioEntry
            if let data = data {
                entry = .entry(data: data, at: entryDate)
            } else {
                entry = PortfolioEntry(date: entryDate, data: .empty)
            }
            entries.append(entry)
        }

        // Request refresh after last entry (2 hours)
        let refreshDate = currentDate.addingTimeInterval(2 * 60 * 60)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))

        Logger.widget.info("Timeline created with \(entries.count) entries, next refresh at \(refreshDate)")
        completion(timeline)
    }

    // MARK: - Private Methods

    /// Creates a timeline entry from cached storage data.
    /// Returns empty state if no data is available.
    private func createEntryFromStorage() -> PortfolioEntry {
        if let data = storage.readPortfolioData() {
            Logger.widget.info("Loaded portfolio data: \(data.holdings.count) holdings")
            return .entry(data: data)
        } else {
            Logger.widget.info("No portfolio data available, showing empty state")
            return .empty()
        }
    }
}
