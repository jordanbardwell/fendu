import ActivityKit
import SwiftUI
import WidgetKit

struct FenduLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FenduLiveActivityAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.state.remainingBalance.asCurrencyWhole())
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(context.state.remainingBalance >= 0 ? Color.brandGreen : Color.brandOrange)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(context.state.daysUntilNextPaycheck)d left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressRing(
                            spent: context.state.totalAllocated + context.state.totalBills,
                            total: context.state.paycheckAmount
                        )
                        .frame(width: 36, height: 36)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    SpentProgressBar(state: context.state)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Color.brandGreen)
            } compactTrailing: {
                Text(context.state.remainingBalance.asCurrencyWhole())
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(context.state.remainingBalance >= 0 ? Color.brandGreen : Color.brandOrange)
            } minimal: {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(Color.brandGreen)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<FenduLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.paycheckDate.formattedShortMonthDay() + " Paycheck")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(context.state.remainingBalance.asCurrencyWhole())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(context.state.remainingBalance >= 0 ? Color.brandGreen : Color.brandOrange)

                Text("remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(context.state.daysUntilNextPaycheck) days")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text("until payday")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ProgressRing(
                    spent: context.state.totalAllocated + context.state.totalBills,
                    total: context.state.paycheckAmount
                )
                .frame(width: 32, height: 32)
            }
        }
        .padding(16)
    }
}

// MARK: - Progress Ring

private struct ProgressRing: View {
    let spent: Double
    let total: Double

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(spent / total, 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress > 0.9 ? Color.brandOrange : Color.brandGreen,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Spent Progress Bar

private struct SpentProgressBar: View {
    let state: FenduLiveActivityAttributes.ContentState

    var body: some View {
        GeometryReader { geometry in
            let total = state.paycheckAmount
            let width = geometry.size.width

            if total > 0 {
                let billsFraction = min(state.totalBills / total, 1.0)
                let allocFraction = min(state.totalAllocated / total, 1.0)
                let billsW = billsFraction * width
                let allocW = allocFraction * width

                HStack(spacing: 1) {
                    if billsW > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.brandOrange)
                            .frame(width: billsW)
                    }
                    if allocW > 0 {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.4))
                            .frame(width: allocW)
                    }
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.brandGreen.opacity(0.5))
                }
                .frame(height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
        .frame(height: 4)
    }
}
