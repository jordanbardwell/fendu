import Foundation
import SwiftData

enum BillCategory: String, Codable, CaseIterable, Identifiable {
    case housing = "housing"
    case utilities = "utilities"
    case insurance = "insurance"
    case subscriptions = "subscriptions"
    case transportation = "transportation"
    case phoneInternet = "phoneInternet"
    case loans = "loans"
    case savings = "savings"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .housing: return "Housing"
        case .utilities: return "Utilities"
        case .insurance: return "Insurance"
        case .subscriptions: return "Subscriptions"
        case .transportation: return "Transportation"
        case .phoneInternet: return "Phone & Internet"
        case .loans: return "Loans"
        case .savings: return "Savings"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .insurance: return "shield.fill"
        case .subscriptions: return "play.rectangle.fill"
        case .transportation: return "car.fill"
        case .phoneInternet: return "wifi"
        case .loans: return "building.columns"
        case .savings: return "arrow.down.to.line"
        case .other: return "doc.text.fill"
        }
    }
}

enum BillRecurrence: String, Codable, CaseIterable, Identifiable {
    case once = "once"
    case everyPaycheck = "every"
    case everyOther = "everyOther"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .once: return "One Time"
        case .everyPaycheck: return "Every Paycheck"
        case .everyOther: return "Every Other Paycheck"
        }
    }

    var shortLabel: String {
        switch self {
        case .once: return "One Time"
        case .everyPaycheck: return "Recurring"
        case .everyOther: return "Every Other"
        }
    }

    var interval: Int {
        switch self {
        case .once: return 0
        case .everyPaycheck: return 1
        case .everyOther: return 2
        }
    }
}

@Model
final class BillAssignment {
    var id: UUID = UUID()
    var paycheckId: String = ""
    var billAccountId: String = ""
    var amount: Double = 0
    var recurrenceRawValue: String = BillRecurrence.everyPaycheck.rawValue
    var categoryRawValue: String = BillCategory.other.rawValue
    var fundingAccountId: String = ""

    var recurrence: BillRecurrence {
        get { BillRecurrence(rawValue: recurrenceRawValue) ?? .everyPaycheck }
        set { recurrenceRawValue = newValue.rawValue }
    }

    var category: BillCategory {
        get { BillCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var isSavings: Bool {
        category == .savings
    }

    init(paycheckId: String, billAccountId: String, amount: Double, recurrence: BillRecurrence = .everyPaycheck, category: BillCategory = .other, fundingAccountId: String = "") {
        self.id = UUID()
        self.paycheckId = paycheckId
        self.billAccountId = billAccountId
        self.amount = amount
        self.recurrenceRawValue = recurrence.rawValue
        self.categoryRawValue = category.rawValue
        self.fundingAccountId = fundingAccountId
    }

    /// Extract the anchor date from the stored paycheckId
    var anchorDate: Date? {
        guard let timestamp = Double(paycheckId.replacingOccurrences(of: "paycheck-", with: "")) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Check if this bill applies to a given paycheck based on recurrence
    func appliesTo(paycheckId targetId: String, frequency: PayFrequency, semiMonthlyDay1: Int = 1, semiMonthlyDay2: Int = 15) -> Bool {
        // Direct match always applies
        if paycheckId == targetId { return true }

        // One-time bills only match their assigned paycheck
        guard recurrence != .once else { return false }

        guard let anchor = anchorDate,
              let targetTimestamp = Double(targetId.replacingOccurrences(of: "paycheck-", with: ""))
        else { return false }

        let targetDate = Date(timeIntervalSince1970: targetTimestamp)
        let calendar = Calendar.current
        let anchorDay = calendar.startOfDay(for: anchor)
        let targetDay = calendar.startOfDay(for: targetDate)

        let periods: Int
        switch frequency {
        case .weekly:
            let days = calendar.dateComponents([.day], from: anchorDay, to: targetDay).day ?? 0
            guard days % 7 == 0 else { return false }
            periods = days / 7
        case .biWeekly:
            let days = calendar.dateComponents([.day], from: anchorDay, to: targetDay).day ?? 0
            guard days % 14 == 0 else { return false }
            periods = days / 14
        case .semiMonthly:
            // Count semi-monthly periods: 2 per month, ordered by day-of-month
            let anchorYear = calendar.component(.year, from: anchorDay)
            let anchorMonth = calendar.component(.month, from: anchorDay)
            let anchorDayIdx = calendar.component(.day, from: anchorDay)
            let targetYear = calendar.component(.year, from: targetDay)
            let targetMonth = calendar.component(.month, from: targetDay)
            let targetDayIdx = calendar.component(.day, from: targetDay)
            // Determine which half (0 or 1) by proximity to the configured pay days
            let d1 = min(semiMonthlyDay1, semiMonthlyDay2)
            let d2 = max(semiMonthlyDay1, semiMonthlyDay2)
            let anchorHalf = abs(anchorDayIdx - d1) <= abs(anchorDayIdx - d2) ? 0 : 1
            let targetHalf = abs(targetDayIdx - d1) <= abs(targetDayIdx - d2) ? 0 : 1
            let monthDiff = (targetYear - anchorYear) * 12 + (targetMonth - anchorMonth)
            periods = monthDiff * 2 + (targetHalf - anchorHalf)
        case .monthly:
            periods = calendar.dateComponents([.month], from: anchorDay, to: targetDay).month ?? 0
        }

        return abs(periods) % recurrence.interval == 0
    }
}
