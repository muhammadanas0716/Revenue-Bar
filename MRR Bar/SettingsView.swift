//
//  SettingsView.swift
//  MRR Bar
//
//  Created by Muhammad Anas on 13/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var revenueManager: RevenueManager
    @State private var stripeKey: String = ""
    @State private var polarAccessToken: String = ""
    @State private var polarOrgId: String = ""

    var body: some View {
        Form {
            Section {
                SecureField("Secret Key (sk_...)", text: $stripeKey)
                    .textFieldStyle(.roundedBorder)
                Text("Dashboard → Developers → API keys")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Stripe", systemImage: "creditcard.fill")
            }

            Section {
                SecureField("Access Token (polar_oat_...)", text: $polarAccessToken)
                    .textFieldStyle(.roundedBorder)
                TextField("Organization ID (optional)", text: $polarOrgId)
                    .textFieldStyle(.roundedBorder)
                Text("Settings → Developers → Access Tokens")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Label("Polar.sh", systemImage: "heart.fill")
            }

            Section {
                Picker("Refresh Interval", selection: $revenueManager.refreshInterval) {
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                    Text("15 minutes").tag(900)
                    Text("30 minutes").tag(1800)
                    Text("1 hour").tag(3600)
                }
            } header: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Section {
                Button("Save & Refresh") {
                    revenueManager.stripeAPIKey = stripeKey
                    revenueManager.polarAccessToken = polarAccessToken
                    revenueManager.polarOrgId = polarOrgId
                    revenueManager.startAutoRefresh()
                    Task {
                        await revenueManager.fetchAllRevenue()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 400)
        .onAppear {
            stripeKey = revenueManager.stripeAPIKey
            polarAccessToken = revenueManager.polarAccessToken
            polarOrgId = revenueManager.polarOrgId
        }
    }
}
