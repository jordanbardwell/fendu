import Foundation

struct PaycheckGenerator {
    static func generateInstances(from config: PaycheckConfig) -> [PaycheckInstance] {
        if config.frequency == .semiMonthly {
            return generateSemiMonthly(from: config)
        }
        return generateInterval(from: config)
    }

    /// Interval-based generation (weekly, bi-weekly, monthly)
    private static func generateInterval(from config: PaycheckConfig) -> [PaycheckInstance] {
        var instances: [PaycheckInstance] = []
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: config.startDate)
        guard let offset = config.frequency.calendarOffset else { return [] }

        for i in -5...1 {
            guard let date = calendar.date(
                byAdding: offset.component,
                value: offset.value * i,
                to: start
            ) else { continue }

            instances.append(PaycheckInstance(
                id: "paycheck-\(Int(date.timeIntervalSince1970))",
                date: date,
                baseAmount: config.amount
            ))
        }

        return instances.sorted { $0.date > $1.date }
    }

    /// Semi-monthly generation: two fixed days per month
    private static func generateSemiMonthly(from config: PaycheckConfig) -> [PaycheckInstance] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let day1 = min(config.semiMonthlyDay1, config.semiMonthlyDay2)
        let day2 = max(config.semiMonthlyDay1, config.semiMonthlyDay2)

        var instances: [PaycheckInstance] = []

        // Generate dates across a range of months (3 months back, 1 forward = ~8-10 paychecks)
        for monthOffset in -3...1 {
            guard let monthDate = calendar.date(byAdding: .month, value: monthOffset, to: today) else { continue }
            let year = calendar.component(.year, from: monthDate)
            let month = calendar.component(.month, from: monthDate)
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 28

            for day in [day1, day2] {
                let clampedDay = min(day, daysInMonth)
                guard let date = calendar.date(from: DateComponents(year: year, month: month, day: clampedDay)) else { continue }
                let startOfDate = calendar.startOfDay(for: date)
                instances.append(PaycheckInstance(
                    id: "paycheck-\(Int(startOfDate.timeIntervalSince1970))",
                    date: startOfDate,
                    baseAmount: config.amount
                ))
            }
        }

        // Deduplicate (in case day1 == day2 or clamping produces duplicates) and sort
        var seen = Set<String>()
        instances = instances.filter { seen.insert($0.id).inserted }
        return instances.sorted { $0.date > $1.date }
    }

    static func currentPaycheckId(from instances: [PaycheckInstance]) -> String? {
        let today = Calendar.current.startOfDay(for: Date())
        let current = instances.first { $0.date <= today }
        return current?.id ?? instances.first?.id
    }
}
