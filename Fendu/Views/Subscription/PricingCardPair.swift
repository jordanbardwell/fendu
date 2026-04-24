import SwiftUI

enum PlanChoice {
    case yearly, monthly
}

struct PricingCardPair: View {
    @Binding var selectedPlan: PlanChoice
    let monthlyPrice: String
    let yearlyPrice: String
    let yearlyMonthly: String
    let savingsLabel: String

    var body: some View {
        HStack(spacing: 10) {
            // Monthly card
            pricingCard(
                label: "MONTHLY",
                price: monthlyPrice,
                subtitle: "per month",
                isSelected: selectedPlan == .monthly,
                showBadge: false
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPlan = .monthly
                }
            }

            // Yearly card
            pricingCard(
                label: "YEARLY",
                price: yearlyPrice,
                subtitle: "\(yearlyMonthly) · billed yearly",
                isSelected: selectedPlan == .yearly,
                showBadge: true
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedPlan = .yearly
                }
            }
        }
    }

    private func pricingCard(
        label: String,
        price: String,
        subtitle: String,
        isSelected: Bool,
        showBadge: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(isSelected ? Color.brandGreen : .gray)

                Text(price)
                    .font(.system(size: 28, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                isSelected
                    ? Color.brandGreen.opacity(0.08)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.brandGreen : Color(.systemGray4),
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
            .overlay(alignment: .topTrailing) {
                if showBadge {
                    Text(savingsLabel)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Color(.systemBackground))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brandGreen)
                        .clipShape(Capsule())
                        .offset(x: -8, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
