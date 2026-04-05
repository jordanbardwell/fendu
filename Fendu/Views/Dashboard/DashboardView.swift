import SwiftUI
import SwiftData

enum AccountFormTarget: Identifiable {
    case new
    case edit(Account)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let account): return account.id.uuidString
        }
    }

    var account: Account? {
        switch self {
        case .new: return nil
        case .edit(let account): return account
        }
    }
}

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var allTransactions: [Transaction]
    @Query private var configs: [PaycheckConfig]
    @Query private var paycheckStatuses: [PaycheckStatus]
    @Query private var allBillAssignments: [BillAssignment]
    @Query private var allBillSkips: [BillSkip]
    @Query private var allBillOverrides: [BillAmountOverride]
    @Query private var splits: [PaycheckSplit]

    private var config: PaycheckConfig? { configs.first }

    private var paycheckInstances: [PaycheckInstance] {
        guard let config else { return [] }
        return PaycheckGenerator.generateInstances(from: config)
    }

    private var currentPaycheck: PaycheckInstance? {
        paycheckInstances.first { $0.id == appState.selectedPaycheckId }
    }

    private var currentTransactions: [Transaction] {
        guard let id = appState.selectedPaycheckId else { return [] }
        return allTransactions.filter { $0.paycheckId == id }
    }

    private var totalAllocated: Double {
        currentTransactions.reduce(0) { $0 + $1.amount }
    }

    private var currentBillAssignments: [BillAssignment] {
        guard let id = appState.selectedPaycheckId,
              let freq = config?.frequency else { return [] }
        let skippedIds = Set(
            allBillSkips
                .filter { $0.paycheckId == id }
                .map { $0.billAssignmentId }
        )
        return allBillAssignments.filter {
            $0.appliesTo(paycheckId: id, frequency: freq) && !skippedIds.contains($0.id.uuidString)
        }
    }

    private func effectiveAmount(for assignment: BillAssignment, paycheckId: String) -> Double {
        allBillOverrides.first(where: {
            $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == paycheckId
        })?.overrideAmount ?? assignment.amount
    }

    private var totalBills: Double {
        guard let id = appState.selectedPaycheckId else { return 0 }
        return currentBillAssignments.reduce(0) { $0 + effectiveAmount(for: $1, paycheckId: id) }
    }

    private var billAccounts: [Account] {
        accounts.filter { $0.type == .bill }
    }

    private var nonBillAccounts: [Account] {
        accounts.filter { $0.type != .bill && $0.type != .checking && $0.type != .savings }
    }

    private var hasSplits: Bool { splits.count > 1 }

    private var fundingAccounts: [Account] {
        let splitAccountIds = Set(splits.map { $0.accountId })
        return accounts.filter { splitAccountIds.contains($0.id.uuidString) }
            .sorted { a, b in
                let aIdx = splits.first { $0.accountId == a.id.uuidString }?.orderIndex ?? 0
                let bIdx = splits.first { $0.accountId == b.id.uuidString }?.orderIndex ?? 0
                return aIdx < bIdx
            }
    }

    private func splitAmount(for accountId: String) -> Double {
        guard let split = splits.first(where: { $0.accountId == accountId }) else { return 0 }
        if split.isRemainder {
            let fixedTotal = splits.filter { !$0.isRemainder }.reduce(0) { $0 + $1.amount }
            return (currentPaycheck?.baseAmount ?? 0) - fixedTotal
        }
        return split.amount
    }

    private var splitBreakdown: [SplitBreakdownItem] {
        guard hasSplits, let paycheckId = appState.selectedPaycheckId else { return [] }
        let fundingIds = Set(fundingAccounts.map { $0.id.uuidString })

        // Bills/transactions not assigned to any funding account
        let unassignedBillTotal = currentBillAssignments
            .filter { $0.fundingAccountId.isEmpty || !fundingIds.contains($0.fundingAccountId) }
            .reduce(0) { $0 + effectiveAmount(for: $1, paycheckId: paycheckId) }
        let unassignedTxTotal = currentTransactions
            .filter { $0.fundingAccountId.isEmpty || !fundingIds.contains($0.fundingAccountId) }
            .reduce(0) { $0 + $1.amount }

        return fundingAccounts.enumerated().compactMap { index, account in
            let idStr = account.id.uuidString
            let splitAmt = splitAmount(for: idStr)
            // Hide accounts that receive no paycheck money
            guard splitAmt > 0 else { return nil }
            let txSpent = currentTransactions
                .filter { $0.fundingAccountId == idStr }
                .reduce(0) { $0 + $1.amount }
            let billSpent = currentBillAssignments
                .filter { $0.fundingAccountId == idStr }
                .reduce(0) { $0 + effectiveAmount(for: $1, paycheckId: paycheckId) }
            // Attribute unassigned costs to the first funding account
            let extraSpent = index == 0 ? (unassignedBillTotal + unassignedTxTotal) : 0
            return SplitBreakdownItem(
                id: idStr,
                accountName: account.name,
                splitAmount: splitAmt,
                spent: txSpent + billSpent + extraSpent
            )
        }
    }

    private func billItems(for assignments: [BillAssignment], paycheckId: String) -> [FundingBillItem] {
        assignments.map { assignment in
            let name = accounts.first { $0.id.uuidString == assignment.billAccountId }?.name ?? "Unknown Bill"
            return FundingBillItem(
                id: assignment.id.uuidString,
                billName: name,
                amount: effectiveAmount(for: assignment, paycheckId: paycheckId),
                recurrence: assignment.recurrence,
                isSavings: assignment.isSavings
            )
        }
    }

    private var fundingSections: [FundingSectionData] {
        guard hasSplits, let paycheckId = appState.selectedPaycheckId else { return [] }
        let fundingIds = Set(fundingAccounts.map { $0.id.uuidString })

        var sections = fundingAccounts.map { account in
            let idStr = account.id.uuidString
            let splitAmt = splitAmount(for: idStr)
            let txs = currentTransactions.filter { $0.fundingAccountId == idStr }
            let accountBills = currentBillAssignments.filter { $0.fundingAccountId == idStr }
            let billSpent = accountBills.reduce(0) { $0 + effectiveAmount(for: $1, paycheckId: paycheckId) }
            let txSpent = txs.reduce(0) { $0 + $1.amount }
            return FundingSectionData(
                id: idStr,
                accountName: account.name,
                remaining: splitAmt - txSpent - billSpent,
                transactions: txs,
                bills: billItems(for: accountBills, paycheckId: paycheckId)
            )
        }

        // Unassigned transactions and bills (empty or unknown fundingAccountId)
        let unassignedTxs = currentTransactions.filter { tx in
            tx.fundingAccountId.isEmpty || !fundingIds.contains(tx.fundingAccountId)
        }
        let unassignedBills = currentBillAssignments.filter { bill in
            bill.fundingAccountId.isEmpty || !fundingIds.contains(bill.fundingAccountId)
        }
        if !unassignedTxs.isEmpty || !unassignedBills.isEmpty {
            let unassignedBillTotal = unassignedBills.reduce(0) { $0 + effectiveAmount(for: $1, paycheckId: paycheckId) }
            let unassignedTxTotal = unassignedTxs.reduce(0) { $0 + $1.amount }
            sections.append(FundingSectionData(
                id: "unassigned",
                accountName: "Unassigned",
                remaining: -(unassignedTxTotal + unassignedBillTotal),
                transactions: unassignedTxs,
                bills: billItems(for: unassignedBills, paycheckId: paycheckId)
            ))
        }
        return sections
    }

    private var remainingBalance: Double {
        (currentPaycheck?.baseAmount ?? 0) - totalAllocated - totalBills
    }

    private var currentPaycheckIsDone: Bool {
        guard let id = appState.selectedPaycheckId else { return false }
        return paycheckStatuses.first { $0.paycheckId == id }?.isDone ?? false
    }

    private var pillData: [PaycheckPillData] {
        let freq = config?.frequency ?? .biWeekly
        return paycheckInstances.map { instance in
            let allocated = allTransactions
                .filter { $0.paycheckId == instance.id }
                .reduce(0.0) { $0 + $1.amount }
            let skippedIds = Set(
                allBillSkips
                    .filter { $0.paycheckId == instance.id }
                    .map { $0.billAssignmentId }
            )
            let bills = allBillAssignments
                .filter { $0.appliesTo(paycheckId: instance.id, frequency: freq) && !skippedIds.contains($0.id.uuidString) }
                .reduce(0.0) { $0 + effectiveAmount(for: $1, paycheckId: instance.id) }
            let total = allocated + bills
            let progress = instance.baseAmount > 0
                ? min(max(total / instance.baseAmount, 0), 1.0)
                : 0
            let isDone = paycheckStatuses
                .first { $0.paycheckId == instance.id }?.isDone ?? false

            return PaycheckPillData(
                id: instance.id,
                date: instance.date,
                progress: progress,
                isDone: isDone
            )
        }
    }

    @State private var accountFormTarget: AccountFormTarget?
    @State private var editingTransaction: Transaction?
    @State private var editingBillAssignment: BillAssignment?

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            List {
                // Portfolio Header
                Section {
                    PortfolioHeaderView(
                        remainingBalance: remainingBalance,
                        paycheckAmount: config?.amount ?? 0,
                        paycheckDate: currentPaycheck?.date,
                        isDone: currentPaycheckIsDone,
                        totalAllocated: totalAllocated,
                        totalBills: totalBills,
                        splitBreakdown: splitBreakdown
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                }

                // Paycheck Selector
                Section {
                    PaycheckSelectorView(
                        pills: pillData,
                        selectedId: appState.selectedPaycheckId,
                        onSelect: { appState.selectedPaycheckId = $0 }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }

                // Allocations
                AllocationsListView(
                    transactions: currentTransactions,
                    accounts: accounts,
                    isDone: currentPaycheckIsDone,
                    onDelete: deleteTransaction,
                    onAdd: { appState.showAddTransaction = true },
                    onToggleDone: {
                        if let id = appState.selectedPaycheckId {
                            toggleDone(id)
                        }
                    },
                    onEdit: { editingTransaction = $0 },
                    onEditBill: { billId in
                        editingBillAssignment = currentBillAssignments.first { $0.id.uuidString == billId }
                    },
                    fundingSections: fundingSections
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                // Bills
                BillsSectionView(
                    billAssignments: currentBillAssignments,
                    accounts: billAccounts,
                    paycheckInstances: paycheckInstances,
                    currentPaycheckId: appState.selectedPaycheckId ?? "",
                    isDone: currentPaycheckIsDone,
                    onUnassign: unassignBill,
                    onAssign: { appState.selectedTab = 1 },
                    onReassign: reassignBill,
                    onMoveThisTime: moveBillThisTime,
                    onOverrideAmount: createBillOverride,
                    fundingAccounts: fundingAccounts,
                    billOverrides: allBillOverrides
                )
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                // Accounts
                Section {
                    ForEach(nonBillAccounts) { account in
                        AccountRowView(
                            account: account,
                            onEdit: { accountFormTarget = .edit(account) },
                            onDelete: { deleteAccount(account) }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { deleteAccount(account) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                        }
                        .listRowSeparator(.hidden)
                    }
                } header: {
                    HStack {
                        Text("Your Accounts")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            accountFormTarget = .new
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption)
                                Text("Add Account")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(Color.brandGreen)
                        }
                    }
                    .textCase(nil)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.brandGreen)
                        Text("Fendu")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .sheet(isPresented: $appState.showAddTransaction) {
                AddTransactionSheet(
                    accounts: accounts,
                    paycheckId: appState.selectedPaycheckId ?? "",
                    fundingAccounts: fundingAccounts
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
            .sheet(item: $accountFormTarget) { target in
                AccountFormSheet(editingAccount: target.account)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingTransaction) { transaction in
                EditTransactionSheet(
                    transaction: transaction,
                    accounts: accounts,
                    fundingAccounts: fundingAccounts
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
            .sheet(item: $editingBillAssignment) { assignment in
                EditBillSheet(
                    assignment: assignment,
                    account: accounts.first { $0.id.uuidString == assignment.billAccountId },
                    paycheckInstances: paycheckInstances,
                    currentPaycheckId: appState.selectedPaycheckId ?? "",
                    onMoveThisTime: moveBillThisTime,
                    onOverrideAmount: createBillOverride,
                    fundingAccounts: fundingAccounts,
                    currentOverrideAmount: allBillOverrides.first(where: {
                        $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == (appState.selectedPaycheckId ?? "")
                    })?.overrideAmount
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
        }
        .onAppear {
            appState.selectInitialPaycheck(instances: paycheckInstances)
        }
        .onChange(of: paycheckInstances) { _, newInstances in
            appState.selectInitialPaycheck(instances: newInstances)
        }
    }

    private func toggleDone(_ paycheckId: String) {
        if let existing = paycheckStatuses.first(where: { $0.paycheckId == paycheckId }) {
            existing.isDone.toggle()
        } else {
            let status = PaycheckStatus(paycheckId: paycheckId, isDone: true)
            modelContext.insert(status)
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
    }

    private func deleteAccount(_ account: Account) {
        modelContext.delete(account)
    }

    private func unassignBill(_ assignment: BillAssignment) {
        let orphanedOverrides = allBillOverrides.filter { $0.billAssignmentId == assignment.id.uuidString }
        for override in orphanedOverrides {
            modelContext.delete(override)
        }
        modelContext.delete(assignment)
    }

    private func createBillOverride(_ assignment: BillAssignment, paycheckId: String, amount: Double) {
        if let existing = allBillOverrides.first(where: {
            $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == paycheckId
        }) {
            modelContext.delete(existing)
        }
        let override = BillAmountOverride(
            billAssignmentId: assignment.id.uuidString,
            paycheckId: paycheckId,
            overrideAmount: amount
        )
        modelContext.insert(override)
    }

    private func reassignBill(_ assignment: BillAssignment, to newPaycheckId: String) {
        assignment.paycheckId = newPaycheckId
    }

    private func moveBillThisTime(_ assignment: BillAssignment, from currentId: String, to targetId: String) {
        let skip = BillSkip(
            billAssignmentId: assignment.id.uuidString,
            paycheckId: currentId
        )
        modelContext.insert(skip)

        let oneTime = BillAssignment(
            paycheckId: targetId,
            billAccountId: assignment.billAccountId,
            amount: assignment.amount,
            recurrence: .once,
            fundingAccountId: assignment.fundingAccountId
        )
        modelContext.insert(oneTime)
    }
}
