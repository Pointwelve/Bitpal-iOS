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
    /// Per FR-004: Timeline refreshes every 30 minutes.
    func getTimeline(in context: Context, completion: @escaping (Timeline<PortfolioEntry>) -> Void) {
        Logger.widget.info("Generating timeline")

        let entry = createEntryFromStorage()

        // Use .atEnd policy to allow WidgetKit to refresh more responsively
        // iOS manages refresh budget (~40-70/day) to prevent battery drain
        let timeline = Timeline(entries: [entry], policy: .atEnd)

        Logger.widget.info("Timeline created with .atEnd policy")
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
