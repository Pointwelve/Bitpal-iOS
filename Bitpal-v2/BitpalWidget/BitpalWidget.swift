//
//  BitpalWidget.swift
//  BitpalWidget
//
//  Created by James Lai on 27/11/25.
//

import WidgetKit
import SwiftUI

/// Main widget configuration.
/// Supports small, medium, and large widget families.
/// Per FR-001, FR-002, FR-003: Three widget sizes with different content levels.
struct BitpalWidget: Widget {
    let kind: String = "BitpalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortfolioTimelineProvider()) { entry in
            BitpalWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Portfolio")
        .description("View your crypto portfolio at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Entry view that routes to the appropriate widget size view.
struct BitpalWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: PortfolioEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small Widget", as: .systemSmall) {
    BitpalWidget()
} timeline: {
    PortfolioEntry.placeholder()
    PortfolioEntry.snapshot()
    PortfolioEntry.empty()
}

#Preview("Medium Widget", as: .systemMedium) {
    BitpalWidget()
} timeline: {
    PortfolioEntry.placeholder()
    PortfolioEntry.snapshot()
    PortfolioEntry.empty()
}

#Preview("Large Widget", as: .systemLarge) {
    BitpalWidget()
} timeline: {
    PortfolioEntry.placeholder()
    PortfolioEntry.snapshot()
    PortfolioEntry.empty()
}
