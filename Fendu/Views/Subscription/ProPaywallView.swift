import SwiftUI
import StoreKit

struct ProPaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    var onContinueFree: (() -> Void)?

    @State private var selectedPlan: PlanChoice = .yearly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    enum PlanChoice { case yearly, monthly }

    private var trialEndDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }

    private var reminderDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? subscriptionManager.yearlyProduct : subscriptionManager.monthlyProduct
    }

    private var pricingSummary: String {
        switch selectedPlan {
        case .yearly:
            return "7 days free, then \(subscriptionManager.yearlyProduct?.displayPrice ?? "$29.99")/yr"
        case .monthly:
            return "7 days free, then \(subscriptionManager.monthlyProduct?.displayPrice ?? "$3.99")/mo"
        }
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            // Gradient glow at top
            VStack(spacing: 0) {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.brandGreen.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(height: 300)
                    .offset(y: -80)

                Spacer()
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)

                    // App icon with Pro badge
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray4), Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("F")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            )

                        Text("Pro")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.brandOrange)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }

                    // Title
                    VStack(spacing: 8) {
                        Text("Get the most out of Fendu")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Unlock all features tailored to your finances")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    // Plan toggle
                    HStack(spacing: 0) {
                        planToggleButton("Yearly", plan: .yearly)
                        planToggleButton("Monthly", plan: .monthly)
                    }
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                    .padding(.horizontal, 80)

                    // Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        timelineItem(
                            icon: "sparkles",
                            iconColor: Color.brandGreen,
                            title: "Today",
                            description: "Unlock unlimited accounts, bills, splits, and income tracking.",
                            isLast: false
                        )

                        timelineItem(
                            icon: "bell.fill",
                            iconColor: Color.brandOrange,
                            title: "Day 5",
                            description: "Receive a reminder from us about your trial ending.",
                            isLast: false
                        )

                        timelineItem(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "Day 7",
                            description: "Trial ends on \(trialEndDate). Continue Pro subscription or use Fendu for free at no cost.",
                            isLast: true
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 8)

                    // Pricing summary
                    Text(pricingSummary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandGreen)

                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // CTA button
                    Button {
                        Task { await handlePurchase() }
                    } label: {
                        Text(isPurchasing ? "Processing..." : "Start for $0.00")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.brandGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 24)

                    // Continue free
                    Button {
                        if let onContinueFree {
                            onContinueFree()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Or continue with Free plan")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    // Restore
                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Text("Restore purchase")
                            .font(.caption)
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding(.bottom, 16)

                    // Terms
                    HStack(spacing: 16) {
                        Text("Terms of Use")
                        Text("Privacy Policy")
                    }
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.4))
                    .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if subscriptionManager.products.isEmpty {
                await subscriptionManager.loadProducts()
            }
        }
    }

    // MARK: - Subviews

    private func planToggleButton(_ label: String, plan: PlanChoice) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPlan = plan
            }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: selectedPlan == plan ? .semibold : .regular))
                .foregroundStyle(selectedPlan == plan ? .white : .gray)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(selectedPlan == plan ? Color(.systemGray3) : .clear)
                .clipShape(Capsule())
        }
    }

    private func timelineItem(icon: String, iconColor: Color, title: String, description: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line + icon
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(minHeight: 40)
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 16)
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
