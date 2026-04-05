import SwiftUI

struct BillsSectionView: View {
    let billAssignments: [BillAssignment]
    let accounts: [Account]
    let paycheckInstances: [PaycheckInstance]
    let currentPaycheckId: String
    var isDone: Bool = false
    let onUnassign: (BillAssignment) -> Void
    let onAssign: () -> Void
    let onReassign: (BillAssignment, String) -> Void
    var onMoveThisTime: ((BillAssignment, String, String) -> Void)? = nil
    var onOverrideAmount: ((BillAssignment, String, Double) -> Void)? = nil
    var fundingAccounts: [Account] = []
    var billOverrides: [BillAmountOverride] = []

    @State private var editingAssignment: BillAssignment?

    private func accountName(for assignment: BillAssignment) -> String {
        accounts.first { $0.id.uuidString == assignment.billAccountId }?.name ?? "Unknown Bill"
    }

    private func account(for assignment: BillAssignment) -> Account? {
        accounts.first { $0.id.uuidString == assignment.billAccountId }
    }

    private func effectiveAmount(for assignment: BillAssignment) -> Double {
        billOverrides.first(where: {
            $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == currentPaycheckId
        })?.overrideAmount ?? assignment.amount
    }

    private func currentOverrideAmount(for assignment: BillAssignment) -> Double? {
        billOverrides.first(where: {
            $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == currentPaycheckId
        })?.overrideAmount
    }

    var body: some View {
        Section {
            if billAssignments.isEmpty {
                Text("No recurring items for this paycheck.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(billAssignments) { assignment in
                    Button {
                        if !isDone {
                            editingAssignment = assignment
                        }
                    } label: {
                        BillRowView(
                            billName: accountName(for: assignment),
                            amount: effectiveAmount(for: assignment),
                            originalAmount: assignment.amount,
                            recurrence: assignment.recurrence,
                            isRecurringInstance: assignment.recurrence != .once && assignment.paycheckId != currentPaycheckId,
                            isSavings: assignment.isSavings,
                            paycheckInstances: paycheckInstances,
                            currentPaycheckId: currentPaycheckId,
                            onReassign: { newPaycheckId in
                                onReassign(assignment, newPaycheckId)
                            },
                            onMoveThisTime: { targetId in
                                onMoveThisTime?(assignment, currentPaycheckId, targetId)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isDone {
                            Button(role: .destructive) {
                                withAnimation {
                                    onUnassign(assignment)
                                }
                            } label: {
                                Label("Unassign", systemImage: "minus.circle")
                            }
                            .tint(.red)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            HStack {
                Text("Recurring")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()

                if isDone {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                        Text("Locked")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.gray.opacity(0.5))
                } else {
                    Button {
                        onAssign()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("Add Recurring")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Color.brandGreen)
                    }
                }
            }
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        }
        .opacity(isDone ? 0.7 : 1)
        .sheet(item: $editingAssignment) { assignment in
            EditBillSheet(
                assignment: assignment,
                account: account(for: assignment),
                paycheckInstances: paycheckInstances,
                currentPaycheckId: currentPaycheckId,
                onMoveThisTime: onMoveThisTime,
                onOverrideAmount: onOverrideAmount,
                fundingAccounts: fundingAccounts,
                currentOverrideAmount: currentOverrideAmount(for: assignment)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(40)
        }
    }
}
