//
//  ShareSheetView.swift
//  Bitpal
//
//  Created by Claude Code on 2025-11-28.
//

import SwiftUI
import UIKit

/// Identifiable wrapper for export file URL
struct ExportFileItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL

    static func == (lhs: ExportFileItem, rhs: ExportFileItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Helper to present UIActivityViewController directly from root view controller
/// This avoids the black background issue when using SwiftUI sheets
enum ShareSheetPresenter {
    @MainActor
    static func present(url: URL, completion: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            completion()
            return
        }

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            completion()
        }

        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX,
                                       y: rootVC.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // Find the topmost presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        topVC.present(activityVC, animated: true)
    }
}
