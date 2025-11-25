//
//  LoadingView.swift
//  Bitpal
//
//  Created by Bitpal Development on 8/11/25.
//

import SwiftUI

/// Loading indicator view for pull-to-refresh and loading states
struct LoadingView: View {
    // MARK: - Properties

    var message: String = "Loading..."

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.medium) {
            ProgressView()
                .progressViewStyle(.circular)

            Text(message)
                .font(Typography.callout)
                .foregroundColor(.textSecondary)
        }
        .padding(Spacing.large)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.xlarge) {
        LoadingView()

        LoadingView(message: "Refreshing prices...")

        LoadingView(message: "Updating...")
    }
}
