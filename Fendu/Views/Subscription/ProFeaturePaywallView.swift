import SwiftUI
import StoreKit

struct ProFeaturePaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    let trigger: Trigger

    @State private var selectedPlan: PlanChoice = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum Trigger: String {
        case accountLimit = "Unlimited Accounts"
        case depositLimit = "More Deposit Accounts"
        case bills = "Unlimited Bills"
        case depositSplits = "Deposit Splits"
        case incomeTracking = "Income Tracking"
        case aiChat = "AI Budget Assistant"

        var icon: String {
            switch self {
            case .accountLimit: return "creditcard.fill"
            case .depositLimit: return "building.columns.fill"
            case .bills: return "arrow.clockwise"
            case .depositSplits: return "chart.pie.fill"
            case .incomeTracking: return "arrow.down.left"
            case .aiChat: return "bubble.left.and.bubble.right.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .accountLimit: return .blue
            case .depositLimit: return .cyan
            case .bills: return Color.brandOrange
            case .depositSplits: return .purple
            case .incomeTracking: return Color.brandGreen
            case .aiChat: return .purple
            }
        }
    }

    private struct FeatureItem: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let description: String
    }

    private var features: [FeatureItem] {
        let all: [(Trigger, FeatureItem)] = [
            (.accountLimit, FeatureItem(icon: "creditcard.fill", color: .blue, title: "Unlimited Accounts", description: "Add as many accounts as you need")),
            (.depositLimit, FeatureItem(icon: "building.columns.fill", color: .cyan, title: "More Deposit Accounts", description: "Add multiple checking & savings accounts")),
            (.bills, FeatureItem(icon: "arrow.clockwise", color: Color.brandOrange, title: "Unlimited Bills", description: "Plan and track all your recurring expenses")),
            (.depositSplits, FeatureItem(icon: "chart.pie.fill", color: .purple, title: "Deposit Splits", description: "Split paychecks across multiple accounts")),
            (.incomeTracking, FeatureItem(icon: "arrow.down.left", color: Color.brandGreen, title: "Income Tracking", description: "Record extra income from any source")),
            (.aiChat, FeatureItem(icon: "bubble.left.and.bubble.right.fill", color: .purple, title: "AI Budget Assistant", description: "Chat with AI about your spending")),
        ]

        var sorted = all.sorted { lhs, _ in lhs.0 == trigger }
        return sorted.map { $0.1 }
    }

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? subscriptionManager.yearlyProduct : subscriptionManager.monthlyProduct
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with X and PRO badge
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.gray)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    ProBadgeView()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Large gradient title
                Text(trigger.rawValue)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [trigger.iconColor, trigger.iconColor.opacity(0.6), .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.bottom, 6)

                Text("Unlock all Pro features with Fendu Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.bottom, 24)

                // Feature list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features) { feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 18))
                                .foregroundStyle(feature.color)
                                .frame(width: 36, height: 36)
                                .background(feature.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 9))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text(feature.description)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Pricing cards
                PricingCardPair(
                    selectedPlan: $selectedPlan,
                    monthlyPrice: subscriptionManager.monthlyProduct?.displayPrice ?? "$3.99",
                    yearlyPrice: subscriptionManager.yearlyProduct?.displayPrice ?? "$29.99",
                    yearlyMonthly: "$2.50/mo",
                    savingsLabel: "SAVE 37%"
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                // CTA button
                Button {
                    Task { await handlePurchase() }
                } label: {
                    Text(isPurchasing ? "Processing..." : "Start 7-day free trial")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                }
                .disabled(isPurchasing)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // Bottom links
                HStack(spacing: 24) {
                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Text("Restore purchase")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Button {
                        // Redeem code
                    } label: {
                        Text("Redeem code")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
    }

    private func handlePurchase() async {
        guard let product = selectedProduct else {
            errorMessage = "Products not loaded. Set StoreKit Configuration in Edit Scheme → Run → Options."
            return
        }
        errorMessage = nil
        isPurchasing = true
        await subscriptionManager.purchase(product)
        isPurchasing = false

        switch subscriptionManager.purchaseState {
        case .failed(let msg):
            errorMessage = msg
        case .cancelled:
            errorMessage = nil
        default:
            break
        }

        if subscriptionManager.isPro {
            dismiss()
        }
    }
}
