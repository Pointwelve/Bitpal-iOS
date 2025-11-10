//
//  Spacing.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import Foundation

/// Design system spacing constants per Liquid Glass design language
/// Constitution Principle II: Maintain consistent 12pt spacing between cards
enum Spacing {
    /// Minimum spacing between UI elements (4pt)
    static let tiny: CGFloat = 4

    /// Small spacing for related elements (8pt)
    static let small: CGFloat = 8

    /// Standard spacing between cards and elements (12pt) - Constitution required
    static let standard: CGFloat = 12

    /// Medium spacing for section separators (16pt)
    static let medium: CGFloat = 16

    /// Large spacing for major section breaks (24pt)
    static let large: CGFloat = 24

    /// Extra large spacing for screen padding (32pt)
    static let xlarge: CGFloat = 32

    /// Corner radius for cards (16pt) per Liquid Glass design
    static let cornerRadius: CGFloat = 16

    /// Minimum tap target size (44pt) per iOS HIG
    static let minimumTapTarget: CGFloat = 44
}
