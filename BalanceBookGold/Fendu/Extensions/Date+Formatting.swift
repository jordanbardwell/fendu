import Foundation

extension Date {
    func formattedMonthDayYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }

    func formattedShortMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}
