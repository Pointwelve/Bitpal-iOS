//
//  PortfolioEntry.swift
//  BitpalWidget
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import WidgetKit

/// Timeline entry for widget display.
/// Conforms to TimelineEntry protocol.
/// Contains portfolio data for a specific time point.
struct PortfolioEntry: TimelineEntry {
    /// When this entry should be displayed
    let date: Date

    /// Portfolio data to display (nil for placeholder)
    let data: WidgetPortfolioData?

    /// Whether this is a placeholder entry (no data available)
    var isPlaceholder: Bool {
        data == nil
    }

    // MARK: - Factory Methods

    /// Create placeholder entry for widget gallery
    static func placeholder() -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: .sample)
    }

    /// Create snapshot entry for widget gallery preview
    static func snapshot() -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: .sample)
    }

    /// Create entry with real portfolio data
    static func entry(data: WidgetPortfolioData) -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: data)
    }

    /// Create empty state entry (no holdings)
    static func empty() -> PortfolioEntry {
        PortfolioEntry(date: Date(), data: .empty)
    }
}
