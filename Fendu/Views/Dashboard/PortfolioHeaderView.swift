import SwiftUI

struct SplitBreakdownItem: Identifiable {
    let id: String
    let accountName: String
    let splitAmount: Double
    let spent: Double
    var remaining: Double { splitAmount - spent }
}

private let splitColors: [Color] = [.brandGreen, .blue, .purple, .teal, .orange, .pink]

struct PortfolioHeaderView: View {
    let remainingBalance: Double
    let paycheckAmount: Double
    let paycheckDate: Date?
    var isDone: Bool = false
    var totalAllocated: Double = 0
    var totalBills: Double = 0
    var splitBreakdown: [SplitBreakdownItem] = []
    var isOverridden: Bool = false
    var onEditAmount: (() -> Void)? = nil

    private var percentage: Double {
        guard paycheckAmount > 0 else { return 0 }
        return abs((remainingBalance / paycheckAmount) * 100)
    }

    private var showBreakdown: Bool {
        splitBreakdown.count > 1
    }

    private var amountLabel: some View {
        Text("From \(paycheckAmount.asCurrencyWhole())")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(isOverridden ? Color.brandGreen : .gray.opacity(0.7))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("Paycheck: \(paycheckDate?.formattedMonthDayYear() ?? "Loading...")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)

                if let onEditAmount {
                    Button {
                        onEditAmount()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "pencil")
                                .font(.system(size: 9, weight: .bold))
                            Text(isOverridden ? "Custom" : "Edit")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            isOverridden
                                ? Color.brandGreen.opacity(0.15)
                                : Color(.systemGray5)
                        )
                        .foregroundStyle(isOverridden ? Color.brandGreen : .gray)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                if isDone {
                    Text("Done")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.brandGreen.opacity(0.15))
                        .foregroundStyle(Color.brandGreen)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 4)

            Text(remainingBalance.asCurrency())
                .font(.system(size: 52, weight: .bold))
                .tracking(-2)
                .opacity(isDone ? 0.4 : 1)
                .padding(.bottom, 4)

            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: remainingBalance >= 0 ? "arrow.up.right" : "arrow.down.left")
                        .font(.caption)
                    Text(String(format: "%.2f%%", percentage))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .foregroundStyle(remainingBalance >= 0 ? Color.brandGreen : Color.brandOrange)

                if totalBills > 0 {
                    Group {
                        if let onEditAmount {
                            Button {
                                onEditAmount()
                            } label: {
                                amountLabel
                            }
                            .buttonStyle(.plain)
                        } else {
                            amountLabel
                        }
                    }

                    Text("· Bills: \(totalBills.asCurrencyWhole()) · Spent: \(totalAllocated.asCurrencyWhole())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray.opacity(0.7))
                } else {
                    if let onEditAmount {
                        Button {
                            onEditAmount()
                        } label: {
                            Text("Remaining from \(paycheckAmount.asCurrencyWhole())")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.gray.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text("Remaining from \(paycheckAmount.asCurrencyWhole())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                }
            }
            .opacity(isDone ? 0.4 : 1)

            // Breakdown bar
            if showBreakdown {
                VStack(spacing: 8) {
                    // Stacked bar
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(Array(splitBreakdown.enumerated()), id: \.element.id) { index, item in
                                let color = splitColors[index % splitColors.count]
                                let fraction = paycheckAmount > 0 ? item.splitAmount / paycheckAmount : 0
                                let segmentWidth = max(geo.size.width * fraction - 2, 4)
                                let spentFraction = item.splitAmount > 0 ? min(item.spent / item.splitAmount, 1.0) : 0

                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color.opacity(0.7))
                                        .frame(width: segmentWidth * spentFraction)
                                        .animation(.easeInOut(duration: 0.4), value: item.spent)
                                }
                                .frame(width: segmentWidth)
                            }
                        }
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.top, 8)

                    // Per-account labels
                    let useVertical = splitBreakdown.count > 2
                    let labels = ForEach(Array(splitBreakdown.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(splitColors[index % splitColors.count])
                                .frame(width: 6, height: 6)
                            Text(item.accountName)
                                .font(.system(size: 10))
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                            Text("\(item.remaining.asCurrencyWhole()) left")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                    }
                    if useVertical {
                        VStack(alignment: .leading, spacing: 4) { labels }
                    } else {
                        HStack(spacing: 12) { labels }
                    }
                }
                .opacity(isDone ? 0.4 : 1)
            }
        }
    }
}
