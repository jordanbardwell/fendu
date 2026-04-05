import SwiftUI

struct FundingBillItem: Identifiable {
    let id: String
    let billName: String
    let amount: Double
    let recurrence: BillRecurrence
    var isSavings: Bool = false
}

struct FundingSectionData: Identifiable {
    let id: String
    let accountName: String
    let remaining: Double
    let transactions: [Transaction]
    var bills: [FundingBillItem] = []
}

struct AllocationsListView: View {
    let transactions: [Transaction]
    let accounts: [Account]
    var isDone: Bool = false
    let onDelete: (Transaction) -> Void
    let onAdd: () -> Void
    let onToggleDone: () -> Void
    var onEdit: ((Transaction) -> Void)? = nil
    var onEditBill: ((String) -> Void)? = nil
    var fundingSections: [FundingSectionData] = []

    private var showGrouped: Bool {
        !fundingSections.isEmpty
    }

    private func fundingAccountName(for tx: Transaction) -> String? {
        guard showGrouped, !tx.fundingAccountId.isEmpty else { return nil }
        return accounts.first { $0.id.uuidString == tx.fundingAccountId }?.name
    }

    var body: some View {
        Section {
            if showGrouped {
                groupedContent
            } else {
                flatContent
            }

            // Mark as Done / Reopen button
            Button {
                withAnimation {
                    onToggleDone()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isDone ? "arrow.uturn.backward.circle" : "checkmark.circle")
                        .font(.subheadline)
                    Text(isDone ? "Reopen Paycheck" : "Mark Paycheck as Done")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isDone ? .gray : Color.brandGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isDone
                        ? Color(.systemGray6)
                        : Color.brandGreen.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
        } header: {
            HStack {
                Text("Allocations")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()

                if isDone {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Paycheck Closed")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.gray.opacity(0.5))
                } else {
                    Button {
                        onAdd()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("Add Transaction")
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
    }

    // MARK: - Flat content (no splits)

    private var flatContent: some View {
        Group {
            if transactions.isEmpty {
                Text("No transactions associated with this paycheck.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(transactions) { tx in
                    Button {
                        if !isDone { onEdit?(tx) }
                    } label: {
                        TransactionRowView(
                            transaction: tx,
                            accountName: tx.displayName
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isDone {
                            Button(role: .destructive) {
                                withAnimation { onDelete(tx) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
    }

    // MARK: - Grouped content (with splits)

    private var groupedContent: some View {
        ForEach(fundingSections) { section in
            // Section sub-header
            HStack {
                Text(section.accountName)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(section.remaining.asCurrencyWhole()) left")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(section.remaining >= 0 ? Color.brandGreen : Color.brandOrange)
            }
            .padding(.vertical, 4)
            .listRowSeparator(.hidden)

            // Bills assigned to this funding account
            ForEach(section.bills) { bill in
                let tint: Color = bill.isSavings ? .blue : Color.brandOrange
                Button {
                    if !isDone { onEditBill?(bill.id) }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(tint.opacity(0.12))
                                .frame(width: 40, height: 40)
                            Image(systemName: bill.isSavings ? "arrow.down.to.line" : "doc.text.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(tint)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(bill.billName)
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text(bill.recurrence.shortLabel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(tint.opacity(0.7))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("-\(bill.amount.asCurrency())")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text(bill.isSavings ? "SAVINGS" : "BILL")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(tint.opacity(0.6))
                                .tracking(1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .listRowSeparator(.hidden)
            }

            // Transactions
            if section.transactions.isEmpty && section.bills.isEmpty {
                Text("No allocations yet")
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.5))
                    .padding(.vertical, 8)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(section.transactions) { tx in
                    Button {
                        if !isDone { onEdit?(tx) }
                    } label: {
                        TransactionRowView(
                            transaction: tx,
                            accountName: tx.displayName
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !isDone {
                            Button(role: .destructive) {
                                withAnimation { onDelete(tx) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
    }
}
