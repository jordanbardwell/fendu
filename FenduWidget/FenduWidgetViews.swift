import WidgetKit
import SwiftUI

// MARK: - Entry View Router

struct FenduWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FenduEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: FenduEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.brandGreen)
                    Text(snapshot.paycheckDate.formattedShortMonthDay())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(snapshot.remainingBalance.asCurrencyWhole())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(snapshot.remainingBalance >= 0 ? Color.primary : Color.brandOrange)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .widgetURL(URL(string: "fendu://dashboard"))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.brandGreen)
                Text("Set up your paycheck")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: FenduEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            HStack(spacing: 16) {
                // Left side — balance
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.brandGreen)
                        Text(snapshot.paycheckDate.formattedShortMonthDay())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(snapshot.remainingBalance.asCurrencyWhole())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(snapshot.remainingBalance >= 0 ? Color.primary : Color.brandOrange)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("remaining of \(snapshot.paycheckAmount.asCurrencyWhole())")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Right side — breakdown
                VStack(alignment: .leading, spacing: 6) {
                    BreakdownBar(snapshot: snapshot)
                        .frame(height: 8)

                    BreakdownRow(color: Color.brandOrange, label: "Bills", amount: snapshot.totalBills)
                    BreakdownRow(color: Color.blue, label: "Spent", amount: snapshot.totalAllocated)
                    BreakdownRow(color: Color.brandGreen, label: "Left", amount: snapshot.remainingBalance)
                }
            }
            .widgetURL(URL(string: "fendu://dashboard"))
        } else {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.brandGreen)
                    Text("Set up your paycheck in Fendu to see your budget here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Breakdown Bar

struct BreakdownBar: View {
    let snapshot: BudgetSnapshot

    var body: some View {
        GeometryReader { geometry in
            let total = snapshot.paycheckAmount
            guard total > 0 else { return AnyView(EmptyView()) }

            let billsWidth = max(0, (snapshot.totalBills / total)) * geometry.size.width
            let allocatedWidth = max(0, (snapshot.totalAllocated / total)) * geometry.size.width
            let remainingWidth = max(0, geometry.size.width - billsWidth - allocatedWidth)

            return AnyView(
                HStack(spacing: 1) {
                    if billsWidth > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.brandOrange)
                            .frame(width: billsWidth)
                    }
                    if allocatedWidth > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue)
                            .frame(width: allocatedWidth)
                    }
                    if remainingWidth > 0 {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.brandGreen)
                            .frame(width: remainingWidth)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
            )
        }
    }
}

// MARK: - Breakdown Row

struct BreakdownRow: View {
    let color: Color
    let label: String
    let amount: Double

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(amount.asCurrencyWhole())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    FenduWidget()
} timeline: {
    FenduEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    FenduWidget()
} timeline: {
    FenduEntry.placeholder
}
