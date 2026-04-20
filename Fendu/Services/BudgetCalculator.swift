import Foundation

struct BudgetSnapshot {
    let paycheckDate: Date
    let paycheckAmount: Double
    let remainingBalance: Double
    let totalAllocated: Double
    let totalBills: Double
    let nextPaycheckDate: Date?
    let daysUntilNextPaycheck: Int
    let isDone: Bool
}

struct BudgetCalculator {

    // MARK: - Snapshot (used by Widget + Live Activity)

    static func currentSnapshot(
        config: PaycheckConfig,
        allTransactions: [Transaction],
        allBillAssignments: [BillAssignment],
        allBillSkips: [BillSkip],
        allBillOverrides: [BillAmountOverride],
        paycheckStatuses: [PaycheckStatus],
        allPaycheckOverrides: [PaycheckAmountOverride] = []
    ) -> BudgetSnapshot? {
        let instances = PaycheckGenerator.generateInstances(from: config)
        guard let currentId = PaycheckGenerator.currentPaycheckId(from: instances),
              let current = instances.first(where: { $0.id == currentId })
        else { return nil }

        let transactions = allTransactions.filter { $0.paycheckId == currentId }
        let totalAllocated = transactions.reduce(0) { $0 + $1.amount }

        let bills = filteredBillAssignments(
            paycheckId: currentId,
            frequency: config.frequency,
            allAssignments: allBillAssignments,
            allSkips: allBillSkips,
            semiMonthlyDay1: config.semiMonthlyDay1,
            semiMonthlyDay2: config.semiMonthlyDay2
        )
        let totalBills = bills.reduce(0) {
            $0 + effectiveAmount(for: $1, paycheckId: currentId, overrides: allBillOverrides)
        }

        let paycheckAmount = effectivePaycheckAmount(for: current, overrides: allPaycheckOverrides)
        let remaining = paycheckAmount - totalAllocated - totalBills
        let isDone = paycheckStatuses.first(where: { $0.paycheckId == currentId })?.isDone ?? false

        // Find next paycheck
        let sortedFuture = instances
            .filter { $0.date > current.date }
            .sorted { $0.date < $1.date }
        let nextPaycheck = sortedFuture.first

        let daysUntilNext: Int
        if let nextDate = nextPaycheck?.date {
            daysUntilNext = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
        } else {
            daysUntilNext = 0
        }

        return BudgetSnapshot(
            paycheckDate: current.date,
            paycheckAmount: paycheckAmount,
            remainingBalance: remaining,
            totalAllocated: totalAllocated,
            totalBills: totalBills,
            nextPaycheckDate: nextPaycheck?.date,
            daysUntilNextPaycheck: max(0, daysUntilNext),
            isDone: isDone
        )
    }

    static func effectivePaycheckAmount(
        for instance: PaycheckInstance,
        overrides: [PaycheckAmountOverride]
    ) -> Double {
        overrides.first(where: { $0.paycheckId == instance.id })?.overrideAmount
            ?? instance.baseAmount
    }

    // MARK: - Shared Helpers (used by DashboardView too)

    static func filteredBillAssignments(
        paycheckId: String,
        frequency: PayFrequency,
        allAssignments: [BillAssignment],
        allSkips: [BillSkip],
        semiMonthlyDay1: Int = 1,
        semiMonthlyDay2: Int = 15
    ) -> [BillAssignment] {
        let skippedIds = Set(
            allSkips
                .filter { $0.paycheckId == paycheckId }
                .map { $0.billAssignmentId }
        )
        return allAssignments.filter {
            $0.appliesTo(paycheckId: paycheckId, frequency: frequency, semiMonthlyDay1: semiMonthlyDay1, semiMonthlyDay2: semiMonthlyDay2)
                && !skippedIds.contains($0.id.uuidString)
        }
    }

    static func effectiveAmount(
        for assignment: BillAssignment,
        paycheckId: String,
        overrides: [BillAmountOverride]
    ) -> Double {
        overrides.first(where: {
            $0.billAssignmentId == assignment.id.uuidString && $0.paycheckId == paycheckId
        })?.overrideAmount ?? assignment.amount
    }
}
