import Foundation
import SwiftData

enum PayFrequency: String, Codable, CaseIterable, Identifiable {
    case weekly
    case biWeekly = "bi-weekly"
    case semiMonthly = "semi-monthly"
    case monthly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .biWeekly: return "Bi-Weekly"
        case .semiMonthly: return "Semi-Monthly"
        case .monthly: return "Monthly"
        }
    }

    /// Calendar offset for interval-based frequencies. Not used by semiMonthly.
    var calendarOffset: (component: Calendar.Component, value: Int)? {
        switch self {
        case .weekly: return (.day, 7)
        case .biWeekly: return (.day, 14)
        case .semiMonthly: return nil
        case .monthly: return (.month, 1)
        }
    }
}

@Model
final class PaycheckConfig {
    var id: UUID = UUID()
    var amount: Double = 2500
    var frequencyRawValue: String = PayFrequency.biWeekly.rawValue
    var startDate: Date = Date()
    var semiMonthlyDay1: Int = 1
    var semiMonthlyDay2: Int = 15

    var frequency: PayFrequency {
        get { PayFrequency(rawValue: frequencyRawValue) ?? .biWeekly }
        set { frequencyRawValue = newValue.rawValue }
    }

    init(amount: Double = 2500, frequency: PayFrequency = .biWeekly, startDate: Date = Date(), semiMonthlyDay1: Int = 1, semiMonthlyDay2: Int = 15) {
        self.id = UUID()
        self.amount = amount
        self.frequencyRawValue = frequency.rawValue
        self.startDate = startDate
        self.semiMonthlyDay1 = semiMonthlyDay1
        self.semiMonthlyDay2 = semiMonthlyDay2
    }
}
