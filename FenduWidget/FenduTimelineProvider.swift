import WidgetKit
import SwiftData
import Foundation

struct FenduEntry: TimelineEntry {
    let date: Date
    let snapshot: BudgetSnapshot?

    static var placeholder: FenduEntry {
        FenduEntry(
            date: Date(),
            snapshot: BudgetSnapshot(
                paycheckDate: Date(),
                paycheckAmount: 2500,
                remainingBalance: 1234,
                totalAllocated: 866,
                totalBills: 400,
                nextPaycheckDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                daysUntilNextPaycheck: 7,
                isDone: false
            )
        )
    }
}

struct FenduTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> FenduEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FenduEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        let entry = buildEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FenduEntry>) -> Void) {
        let entry = buildEntry()

        // Refresh at midnight or when the next paycheck starts, whichever is sooner
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let refreshDate: Date
        if let nextPayday = entry.snapshot?.nextPaycheckDate, nextPayday < midnight {
            refreshDate = nextPayday
        } else {
            refreshDate = midnight
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Private

    private func buildEntry() -> FenduEntry {
        guard let container = try? SharedContainer.makeModelContainer() else {
            return FenduEntry(date: Date(), snapshot: nil)
        }

        let context = ModelContext(container)

        guard let config = fetchFirst(PaycheckConfig.self, in: context) else {
            return FenduEntry(date: Date(), snapshot: nil)
        }

        let transactions = fetchAll(Transaction.self, in: context)
        let billAssignments = fetchAll(BillAssignment.self, in: context)
        let billSkips = fetchAll(BillSkip.self, in: context)
        let billOverrides = fetchAll(BillAmountOverride.self, in: context)
        let statuses = fetchAll(PaycheckStatus.self, in: context)

        let snapshot = BudgetCalculator.currentSnapshot(
            config: config,
            allTransactions: transactions,
            allBillAssignments: billAssignments,
            allBillSkips: billSkips,
            allBillOverrides: billOverrides,
            paycheckStatuses: statuses
        )

        return FenduEntry(date: Date(), snapshot: snapshot)
    }

    private func fetchFirst<T: PersistentModel>(_ type: T.Type, in context: ModelContext) -> T? {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor))?.first
    }

    private func fetchAll<T: PersistentModel>(_ type: T.Type, in context: ModelContext) -> [T] {
        let descriptor = FetchDescriptor<T>()
        return (try? context.fetch(descriptor)) ?? []
    }
}
