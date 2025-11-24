//
//  Colors.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Design system color constants per Liquid Glass design language
/// Per Constitution Principle II: Use system colors for automatic dark mode support
extension Color {
    // MARK: - Semantic Colors

    /// Green color for positive price changes (profit)
    static let profitGreen = Color.green

    /// Red color for negative price changes (loss)
    static let lossRed = Color.red

    /// Primary text color (adapts to dark mode)
    static let textPrimary = Color.primary

    /// Secondary text color (adapts to dark mode)
    static let textSecondary = Color.secondary

    /// Tertiary text color for de-emphasized content
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    /// Background color for main app content
    static let backgroundPrimary = Color(uiColor: .systemBackground)

    /// Secondary background color for grouped content
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)

    /// Tertiary background color for nested grouped content
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)

    // MARK: - Accent Colors

    /// System accent color (tint)
    static let accent = Color.accentColor

    /// Separator color for dividers
    static let separator = Color(uiColor: .separator)

    /// Placeholder text color
    static let placeholder = Color(uiColor: .placeholderText)
}
