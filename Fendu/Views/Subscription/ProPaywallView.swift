import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    var onContinueFree: (() -> Void)?

    @State private var selectedPlan: PlanChoice = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? subscriptionManager.yearlyProduct : subscriptionManager.monthlyProduct
    }

    private struct FeatureRow: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
    }

    private let features: [FeatureRow] = [
        FeatureRow(title: "Unlimited bills & accounts", subtitle: "Model your life as it actually is."),
        FeatureRow(title: "Paycheck splits across accounts", subtitle: "Fixed + Remainder, running balance, the works."),
        FeatureRow(title: "Income tracking", subtitle: "Side gigs, Venmo, refunds — all counted."),
        FeatureRow(title: "iCloud sync across devices", subtitle: "Your data, your iCloud, not our servers."),
    ]

    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Top bar
                    HStack {
                        Text("/ fendu pro")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(Color.brandGreen)

                        Spacer()

                        Button {
                            if let onContinueFree {
                                onContinueFree()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.gray)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 28)

                    // Headline with green highlight
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Plan every")
                            .font(.system(size: 44, weight: .black))
                            .tracking(-1.5)
                        Text("paycheck.")
                            .font(.system(size: 44, weight: .black))
                            .tracking(-1.5)
                        Text("Every bill.")
                            .font(.system(size: 44, weight: .black))
                            .tracking(-1.5)
                        HStack(spacing: 0) {
                            Text("Every ")
                                .font(.system(size: 44, weight: .black))
                                .tracking(-1.5)
                            Text("account.")
                                .font(.system(size: 44, weight: .black))
                                .tracking(-1.5)
                                .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 10/255))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 2)
                                .background(Color.brandGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.bottom, 32)

                    // Feature rows
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features) { feature in
                            HStack(alignment: .top, spacing: 14) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.brandGreen)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 10/255))
                                    )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(feature.title)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text(feature.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundStyle(.gray)
                                        .lineSpacing(2)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)

                    // Pricing cards
                    PricingCardPair(
                        selectedPlan: $selectedPlan,
                        monthlyPrice: subscriptionManager.monthlyProduct?.displayPrice ?? "$3.99",
                        yearlyPrice: subscriptionManager.yearlyProduct?.displayPrice ?? "$29.99",
                        yearlyMonthly: "$2.50/mo",
                        savingsLabel: "SAVE 37%"
                    )
                    .padding(.bottom, 16)

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                    }

                    // CTA
                    Button {
                        Task { await handlePurchase() }
                    } label: {
                        Text(isPurchasing ? "Processing..." : "Start 7-day free trial")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color(red: 10/255, green: 10/255, blue: 10/255))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 999))
                    }
                    .disabled(isPurchasing)
                    .padding(.bottom, 12)

                    // Footer
                    HStack(spacing: 4) {
                        Text("Cancel anytime")
                            .foregroundStyle(.gray)

                        Text("·")
                            .foregroundStyle(.gray)

                        Button {
                            Task { await subscriptionManager.restorePurchases() }
                        } label: {
                            Text("Restore purchase")
                                .foregroundStyle(.gray)
                                .underline()
                        }
                    }
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = selectedProduct else {
            errorMessage = "Products not loaded. Make sure StoreKit Configuration is set in your scheme (Edit Scheme → Run → Options)."
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
            if let onContinueFree {
                onContinueFree()
            } else {
                dismiss()
            }
        }
    }
}
