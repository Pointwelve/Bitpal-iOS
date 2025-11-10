//
//  Typography.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Design system typography constants per Liquid Glass design language
/// All text uses SF Pro (system font) with Dynamic Type support
enum Typography {
    // MARK: - Font Weights

    static let regular = Font.Weight.regular
    static let medium = Font.Weight.medium
    static let semibold = Font.Weight.semibold
    static let bold = Font.Weight.bold

    // MARK: - Text Styles (Dynamic Type enabled)

    /// Large title for section headers (.largeTitle)
    static let largeTitle = Font.largeTitle

    /// Title for primary headings (.title)
    static let title = Font.title

    /// Title 2 for secondary headings (.title2)
    static let title2 = Font.title2

    /// Title 3 for tertiary headings (.title3)
    static let title3 = Font.title3

    /// Headline for emphasized body text (.headline)
    static let headline = Font.headline

    /// Body text for standard content (.body)
    static let body = Font.body

    /// Callout for slightly smaller body text (.callout)
    static let callout = Font.callout

    /// Subheadline for secondary information (.subheadline)
    static let subheadline = Font.subheadline

    /// Footnote for tertiary information (.footnote)
    static let footnote = Font.footnote

    /// Caption for smallest text (.caption)
    static let caption = Font.caption

    /// Caption 2 for the smallest text (.caption2)
    static let caption2 = Font.caption2

    // MARK: - Monospaced Variants (for prices and numbers)

    /// Monospaced headline for price display
    static let priceDisplay = Font.headline.monospacedDigit()

    /// Monospaced body for numeric values
    static let numericBody = Font.body.monospacedDigit()

    /// Monospaced caption for small numeric values
    static let numericCaption = Font.caption.monospacedDigit()
}
