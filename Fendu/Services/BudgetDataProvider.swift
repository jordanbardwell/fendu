import Foundation

/// Bridges @Query data from SwiftUI views to Foundation Models tools.
/// Built in the view layer where @Query is available, then passed to tools.
struct BudgetDataProvider {
    let config: PaycheckConfig
    let accounts: [Account]
    let allTransactions: [Transaction]
    let allBillAssignments: [BillAssignment]
    let allBillSkips: [BillSkip]
    let allBillOverrides: [BillAmountOverride]
    let paycheckStatuses: [PaycheckStatus]
    let splits: [PaycheckSplit]
    let allBillPayments: [BillPayment]
    let allPaycheckOverrides: [PaycheckAmountOverride]

    // MARK: - Derived Helpers

    private var instances: [PaycheckInstance] {
        PaycheckGenerator.generateInstances(from: config)
    }

    private var currentPaycheckId: String? {
        PaycheckGenerator.currentPaycheckId(from: instances)
    }

    private var currentInstance: PaycheckInstance? {
        guard let id = currentPaycheckId else { return nil }
        return instances.first { $0.id == id }
    }

    // MARK: - Tool Output Methods

    func currentPaycheckSummary() -> String {
        guard let snapshot = BudgetCalculator.currentSnapshot(
            config: config,
            allTransactions: allTransactions,
            allBillAssignments: allBillAssignments,
            allBillSkips: allBillSkips,
            allBillOverrides: allBillOverrides,
            paycheckStatuses: paycheckStatuses
        ) else {
            return "No active paycheck found."
        }

        let dateStr = snapshot.paycheckDate.formattedShortMonthDay()
        let nextStr = snapshot.nextPaycheckDate?.formattedShortMonthDay() ?? "N/A"

        return """
        Current paycheck: \(dateStr)
        Amount: \(snapshot.paycheckAmount.asCurrency())
        Remaining: \(snapshot.remainingBalance.asCurrency())
        Spent (allocations): \(snapshot.totalAllocated.asCurrency())
        Bills: \(snapshot.totalBills.asCurrency())
        Days until next paycheck: \(snapshot.daysUntilNextPaycheck)
        Next paycheck: \(nextStr)
        Status: \(snapshot.isDone ? "Marked done" : "Active")
        """
    }

    func recentTransactions(limit: Int = 10) -> String {
        guard let id = currentPaycheckId else { return "No active paycheck." }

        let transactions = allTransactions
            .filter { $0.paycheckId == id }
            .sorted { $0.date > $1.date }
            .prefix(limit)

        if transactions.isEmpty { return "No transactions this paycheck." }

        let lines = transactions.map { tx in
            let name = tx.displayName
            let acct = tx.account?.name ?? "Unknown"
            let date = tx.date.formattedShortMonthDay()
            if tx.isIncome {
                return "- \(name): +\(abs(tx.amount).asCurrency()) (income) to \(acct) on \(date)"
            } else {
                return "- \(name): \(tx.amount.asCurrency()) from \(acct) on \(date)"
            }
        }

        return "Transactions for current paycheck:\n" + lines.joined(separator: "\n")
    }

    func accountsSummary() -> String {
        if accounts.isEmpty { return "No accounts set up." }

        let lines = accounts.map { account in
            "- \(account.name) (\(account.type.rawValue)): \(account.balance.asCurrency())"
        }

        return "Accounts:\n" + lines.joined(separator: "\n")
    }

    func billSchedule() -> String {
        guard let id = currentPaycheckId else { return "No active paycheck." }

        let currentBills = BudgetCalculator.filteredBillAssignments(
            paycheckId: id,
            frequency: config.frequency,
            allAssignments: allBillAssignments,
            allSkips: allBillSkips,
            semiMonthlyDay1: config.semiMonthlyDay1,
            semiMonthlyDay2: config.semiMonthlyDay2
        )

        var currentTotal = 0.0
        var result = "Bills for current paycheck (\(currentBills.count) total):\n"
        if currentBills.isEmpty {
            result += "  None\n"
        } else {
            for bill in currentBills {
                let name = accounts.first { $0.id.uuidString == bill.billAccountId }?.name ?? "Unknown"
                let amount = BudgetCalculator.effectiveAmount(for: bill, paycheckId: id, overrides: allBillOverrides)
                let category = bill.category.displayName
                let paid = allBillPayments.contains { $0.billAssignmentId == bill.id.uuidString && $0.paycheckId == id }
                currentTotal += amount
                result += "- \(name): \(amount.asCurrency()) [\(category)] (\(bill.recurrence.shortLabel))\(paid ? " [PAID]" : "")\n"
            }
            result += "Current paycheck bills total: \(currentTotal.asCurrency())\n"
        }

        // Next paycheck bills
        let sortedFuture = instances.filter { $0.date > (currentInstance?.date ?? Date()) }.sorted { $0.date < $1.date }
        if let next = sortedFuture.first {
            let nextBills = BudgetCalculator.filteredBillAssignments(
                paycheckId: next.id,
                frequency: config.frequency,
                allAssignments: allBillAssignments,
                allSkips: allBillSkips,
                semiMonthlyDay1: config.semiMonthlyDay1,
                semiMonthlyDay2: config.semiMonthlyDay2
            )

            var nextTotal = 0.0
            result += "\nBills for next paycheck \(next.date.formattedShortMonthDay()) (\(nextBills.count) total):\n"
            if nextBills.isEmpty {
                result += "  None\n"
            } else {
                for bill in nextBills {
                    let name = accounts.first { $0.id.uuidString == bill.billAccountId }?.name ?? "Unknown"
                    let amount = BudgetCalculator.effectiveAmount(for: bill, paycheckId: next.id, overrides: allBillOverrides)
                    let category = bill.category.displayName
                    nextTotal += amount
                    result += "- \(name): \(amount.asCurrency()) [\(category)] (\(bill.recurrence.shortLabel))\n"
                }
                result += "Next paycheck bills total: \(nextTotal.asCurrency())\n"
            }
        }

        return result
    }

    func paycheckHistory(count: Int = 3) -> String {
        let allInstances = instances.sorted { $0.date > $1.date }
        guard let currentId = currentPaycheckId,
              let currentIdx = allInstances.firstIndex(where: { $0.id == currentId })
        else { return "No paycheck history available." }

        let historySlice = Array(allInstances[currentIdx...].prefix(count))

        let lines = historySlice.enumerated().map { (offset, instance) in
            let label = offset == 0 ? "Current paycheck" : "Previous paycheck \(offset)"
            let txs = allTransactions.filter { $0.paycheckId == instance.id }
            let allocated = txs.reduce(0.0) { $0 + $1.amount }

            let bills = BudgetCalculator.filteredBillAssignments(
                paycheckId: instance.id,
                frequency: config.frequency,
                allAssignments: allBillAssignments,
                allSkips: allBillSkips,
                semiMonthlyDay1: config.semiMonthlyDay1,
                semiMonthlyDay2: config.semiMonthlyDay2
            )
            let billTotal = bills.reduce(0.0) {
                $0 + BudgetCalculator.effectiveAmount(for: $1, paycheckId: instance.id, overrides: allBillOverrides)
            }

            let effectiveAmt = BudgetCalculator.effectivePaycheckAmount(for: instance, overrides: allPaycheckOverrides)
            let remaining = effectiveAmt - allocated - billTotal
            let isDone = paycheckStatuses.first { $0.paycheckId == instance.id }?.isDone ?? false

            return "\(label) (\(instance.date.formattedShortMonthDay())): \(effectiveAmt.asCurrency()) paycheck, \(allocated.asCurrency()) spent, \(billTotal.asCurrency()) bills, \(remaining.asCurrency()) remaining\(isDone ? " (done)" : "")"
        }

        return lines.joined(separator: "\n")
    }
}
