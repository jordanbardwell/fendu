import SwiftUI

struct BillRowView: View {
    let billName: String
    let amount: Double
    var originalAmount: Double? = nil
    let recurrence: BillRecurrence
    var isRecurringInstance: Bool = false
    var isSavings: Bool = false
    let paycheckInstances: [PaycheckInstance]
    let currentPaycheckId: String
    let onReassign: (String) -> Void
    var onMoveThisTime: ((String) -> Void)? = nil

    @State private var showReassign = false
    @State private var showMoveThisTime = false

    private var tint: Color {
        isSavings ? .blue : Color.brandOrange
    }

    private var hasOverride: Bool {
        guard let original = originalAmount else { return false }
        return abs(original - amount) > 0.001
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: isSavings ? "arrow.down.to.line" : "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(billName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                HStack(spacing: 4) {
                    Image(systemName: recurrence == .once ? "1.circle" : "arrow.clockwise")
                        .font(.system(size: 9))
                    Text(recurrence.shortLabel)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(tint.opacity(0.7))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if hasOverride {
                    Text("-\(originalAmount!.asCurrency())")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .strikethrough()
                        .foregroundStyle(.gray.opacity(0.5))
                }
                Text("-\(amount.asCurrency())")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(hasOverride ? Color.brandOrange : .primary)
                Text(isSavings ? "SAVINGS" : (hasOverride ? "ADJUSTED" : "BILL"))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint.opacity(0.7))
                    .tracking(1.5)
            }

            // Move button — different behavior for one-time vs recurring
            if recurrence != .once || isRecurringInstance {
                Button {
                    showMoveThisTime = true
                } label: {
                    Image(systemName: "arrow.uturn.right")
                        .font(.caption)
                        .foregroundStyle(Color.brandOrange.opacity(0.5))
                        .padding(8)
                }
            } else if recurrence == .once {
                Button {
                    showReassign = true
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.5))
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Move to Paycheck", isPresented: $showReassign, titleVisibility: .visible) {
            ForEach(paycheckInstances.filter { $0.id != currentPaycheckId }) { instance in
                Button(instance.date.formattedShortMonthDay()) {
                    onReassign(instance.id)
                }
            }
        } message: {
            Text("Permanently move this bill to another paycheck.")
        }
        .confirmationDialog("Move This Time Only", isPresented: $showMoveThisTime, titleVisibility: .visible) {
            ForEach(paycheckInstances.filter { $0.id != currentPaycheckId }) { instance in
                Button(instance.date.formattedShortMonthDay()) {
                    onMoveThisTime?(instance.id)
                }
            }
        } message: {
            Text("Skip this bill on the current paycheck and move it to another one just this time. The recurring schedule stays the same.")
        }
    }
}
