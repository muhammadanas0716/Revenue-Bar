//
//  MRR_BarApp.swift
//  MRR Bar
//
//  Created by Muhammad Anas on 13/01/2026.
//

import SwiftUI

@main
struct MRR_BarApp: App {
    @StateObject private var revenueManager = RevenueManager()
    @State private var showSettings = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(revenueManager: revenueManager, showSettings: $showSettings)
        } label: {
            Image(systemName: "dog.fill")
                .help(revenueManager.isLoading ? "Loading..." : revenueManager.formattedTotalRevenue)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(revenueManager: revenueManager)
        }
    }
}
