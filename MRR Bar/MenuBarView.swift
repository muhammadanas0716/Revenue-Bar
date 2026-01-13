//
//  MenuBarView.swift
//  MRR Bar
//
//  Created by Muhammad Anas on 13/01/2026.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var revenueManager: RevenueManager
    @Binding var showSettings: Bool
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("MRR Bar")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                if revenueManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            if !revenueManager.hasAPIKeys {
                // No API keys configured
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No API keys configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Open Settings") {
                        openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Total Revenue
                VStack(spacing: 4) {
                    Text("Total Revenue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(revenueManager.formattedTotalRevenue)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }

                // Stats Grid
                HStack(spacing: 20) {
                    StatBox(title: "Orders", value: "\(revenueManager.totalOrders)")
                    if revenueManager.totalOrders > 0 {
                        StatBox(title: "Avg Order", value: revenueManager.formatCurrency(revenueManager.totalRevenue / Double(revenueManager.totalOrders)))
                    }
                }

                Divider()

                // Breakdown by source
                VStack(spacing: 8) {
                    if !revenueManager.stripeAPIKey.isEmpty {
                        RevenueRow(
                            icon: "creditcard.fill",
                            name: "Stripe",
                            amount: revenueManager.stripeRevenue,
                            orders: revenueManager.stripeOrderCount,
                            formatCurrency: revenueManager.formatCurrency
                        )
                    }

                    if !revenueManager.polarAccessToken.isEmpty {
                        RevenueRow(
                            icon: "heart.fill",
                            name: "Polar.sh",
                            amount: revenueManager.polarRevenue,
                            orders: revenueManager.polarOrderCount,
                            formatCurrency: revenueManager.formatCurrency
                        )
                    }
                }

                // Error message
                if let error = revenueManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // Last updated
                if let lastUpdated = revenueManager.lastUpdated {
                    Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Actions
            HStack {
                Button {
                    Task {
                        await revenueManager.fetchAllRevenue()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(revenueManager.isLoading)

                Spacer()

                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
    }
}

struct RevenueRow: View {
    let icon: String
    let name: String
    let amount: Double
    let orders: Int
    let formatCurrency: (Double) -> String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .foregroundColor(.primary)
                Text("\(orders) orders")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatCurrency(amount))
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
