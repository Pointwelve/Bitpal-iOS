//
//  BitpalApp.swift
//  Bitpal
//
//  Created by James Lai on 8/11/25.
//

import SwiftUI
import SwiftData

@main
struct BitpalApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WatchlistItem.self
        ])
    }
}
