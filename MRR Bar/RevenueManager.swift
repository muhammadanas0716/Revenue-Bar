//
//  RevenueManager.swift
//  MRR Bar
//
//  Created by Muhammad Anas on 13/01/2026.
//

import Foundation
import SwiftUI
import Combine

class RevenueManager: ObservableObject {
    @Published var stripeRevenue: Double = 0
    @Published var polarRevenue: Double = 0
    @Published var stripeOrderCount: Int = 0
    @Published var polarOrderCount: Int = 0
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var error: String?

    @AppStorage("polarOrgId") var polarOrgId: String = ""
    @AppStorage("refreshInterval") var refreshInterval: Int = 300 // 5 minutes

    // Secure storage via Keychain
    var stripeAPIKey: String {
        get { KeychainHelper.get(key: "stripeAPIKey") ?? "" }
        set {
            KeychainHelper.save(key: "stripeAPIKey", value: newValue)
            objectWillChange.send()
        }
    }

    var polarAccessToken: String {
        get { KeychainHelper.get(key: "polarAccessToken") ?? "" }
        set {
            KeychainHelper.save(key: "polarAccessToken", value: newValue)
            objectWillChange.send()
        }
    }

    private var refreshTimer: Timer?

    var totalRevenue: Double {
        stripeRevenue + polarRevenue
    }

    var totalOrders: Int {
        stripeOrderCount + polarOrderCount
    }

    var formattedTotalRevenue: String {
        formatCurrency(totalRevenue)
    }

    var hasAPIKeys: Bool {
        !stripeAPIKey.isEmpty || !polarAccessToken.isEmpty
    }

    init() {
        Task { @MainActor in
            await fetchAllRevenue()
            startAutoRefresh()
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshInterval), repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchAllRevenue()
            }
        }
    }

    @MainActor
    func fetchAllRevenue() async {
        guard hasAPIKeys else { return }

        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchStripeData() }
            group.addTask { await self.fetchPolarData() }
        }

        lastUpdated = Date()
        isLoading = false
    }

    @MainActor
    private func fetchStripeData() async {
        guard !stripeAPIKey.isEmpty else { return }

        do {
            let stats = try await StripeAPI.fetchStats(apiKey: stripeAPIKey)
            stripeRevenue = stats.revenue
            stripeOrderCount = stats.orderCount
        } catch {
            self.error = "Stripe: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func fetchPolarData() async {
        guard !polarAccessToken.isEmpty else { return }

        do {
            let stats = try await PolarAPI.fetchStats(accessToken: polarAccessToken, orgId: polarOrgId)
            polarRevenue = stats.revenue
            polarOrderCount = stats.orderCount
        } catch {
            self.error = "Polar: \(error.localizedDescription)"
        }
    }
}

struct RevenueStats {
    let revenue: Double
    let orderCount: Int
}

// MARK: - Stripe API
enum StripeAPI {
    static func fetchStats(apiKey: String) async throws -> RevenueStats {
        var request = URLRequest(url: URL(string: "https://api.stripe.com/v1/charges?limit=100")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""

        if httpResponse.statusCode == 401 {
            throw APIError.apiError("Stripe: Invalid API key")
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.apiError("Stripe (\(httpResponse.statusCode)): \(responseBody.prefix(200))")
        }

        let charges = try JSONDecoder().decode(StripeChargesList.self, from: data)

        let successfulCharges = charges.data.filter { $0.status == "succeeded" && !$0.refunded }
        let total = successfulCharges.reduce(0) { $0 + Double($1.amount) / 100.0 }

        return RevenueStats(revenue: total, orderCount: successfulCharges.count)
    }
}

struct StripeChargesList: Codable {
    let data: [StripeCharge]
}

struct StripeCharge: Codable {
    let amount: Int
    let status: String
    let refunded: Bool
}

// MARK: - Polar API
enum PolarAPI {
    static func fetchStats(accessToken: String, orgId: String) async throws -> RevenueStats {
        var urlString = "https://api.polar.sh/v1/orders/?limit=100"
        if !orgId.isEmpty {
            urlString += "&organization_id=\(orgId)"
        }

        let cleanToken = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)

        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(cleanToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw APIError.apiError("Polar: Unauthorized - check your access token")
        }

        guard httpResponse.statusCode == 200 else {
            throw APIError.apiError("Polar (\(httpResponse.statusCode)): \(responseBody.prefix(200))")
        }

        let orders = try JSONDecoder().decode(PolarOrdersList.self, from: data)

        let total = orders.items.reduce(0) { $0 + $1.amount }
        return RevenueStats(revenue: Double(total) / 100.0, orderCount: orders.items.count)
    }
}

struct PolarOrdersList: Codable {
    let items: [PolarOrder]
}

struct PolarOrder: Codable {
    let amount: Int
}

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case networkError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid API response"
        case .unauthorized: return "Invalid API key"
        case .networkError: return "Network error"
        case .apiError(let msg): return msg
        }
    }
}
