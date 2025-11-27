//
//  WidgetDataProvider.swift
//  Bitpal
//
//  Created by Claude Code via /speckit.implement on 2025-11-27.
//  Feature: 004-portfolio-widgets
//

import Foundation
import WidgetKit
import OSLog

/// Orchestrates widget data persistence from main app.
/// Called by PortfolioViewModel after portfolio updates.
/// Per Constitution Principle III: Singleton service pattern.
@MainActor
final class WidgetDataProvider {
    // MARK: - Singleton

    static let shared = WidgetDataProvider()

    // MARK: - Dependencies

    private let storage = AppGroupStorage.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Updates widget data with current portfolio state.
    /// Should be called after portfolio load/refresh and transaction changes.
    /// - Parameters:
    ///   - summary: Current portfolio summary
    ///   - holdings: Current holdings list
    func updateWidgetData(
        summary: PortfolioSummary,
        holdings: [Holding]
    ) {
        let widgetData = prepareWidgetData(summary: summary, holdings: holdings)

        do {
            try storage.writePortfolioData(widgetData)
            Logger.widget.info("Widget data updated: total=\(widgetData.totalValue), holdings=\(widgetData.holdings.count)")
        } catch {
            Logger.widget.error("Failed to update widget data: \(error.localizedDescription)")
        }
    }

    /// Triggers a reload of all widget timelines.
    /// Should be called after data changes that affect widget display.
    func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
        Logger.widget.info("Widget timelines reload triggered")
    }

    /// Combines data update and timeline reload.
    /// Convenience method for common use case.
    /// - Parameters:
    ///   - summary: Current portfolio summary
    ///   - holdings: Current holdings list
    func updateAndReloadWidgets(
        summary: PortfolioSummary,
        holdings: [Holding]
    ) {
        updateWidgetData(summary: summary, holdings: holdings)
        reloadWidgetTimelines()
    }

    /// Clears widget data and reloads timelines.
    /// Called when user clears all portfolio data.
    func clearWidgetData() {
        do {
            try storage.clearPortfolioData()
            reloadWidgetTimelines()
            Logger.widget.info("Widget data cleared and timelines reloaded")
        } catch {
            Logger.widget.error("Failed to clear widget data: \(error.localizedDescription)")
        }
    }
}
