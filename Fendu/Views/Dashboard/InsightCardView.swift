#if canImport(FoundationModels)
import SwiftUI
import FoundationModels

@available(iOS 26, *)
struct InsightCardView: View {
    let insight: BudgetInsight?
    let isLoading: Bool
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            if isLoading {
                shimmerPlaceholder
            } else if let insight {
                insightCard(insight)
            }
        }
    }

    private func insightCard(_ insight: BudgetInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(sentimentColor(insight.sentiment).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(sentimentColor(insight.sentiment))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Insight")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.gray)
                Text(insight.text)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    dismissed = true
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.gray)
                    .frame(width: 24, height: 24)
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private var shimmerPlaceholder: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 160, height: 14)
            }

            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func sentimentColor(_ sentiment: InsightSentiment) -> Color {
        switch sentiment {
        case .positive: return Color.brandGreen
        case .warning: return Color.brandOrange
        case .neutral: return .gray
        }
    }
}

#endif
