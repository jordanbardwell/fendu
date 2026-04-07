import Foundation
import UserNotifications

enum NotificationScheduler {

    // MARK: - Constants

    static let overspendingThreshold = 0.90

    private static let billReminderId = "fendu.billReminder"
    private static let overspendingId = "fendu.overspending"
    private static let paydayId = "fendu.payday"

    // MARK: - Public

    static func rescheduleAll(
        snapshot: BudgetSnapshot,
        billDetails: [(name: String, amount: Double)]
    ) {
        let center = UNUserNotificationCenter.current()

        // Remove all Fendu notifications before rescheduling
        center.removePendingNotificationRequests(withIdentifiers: [
            billReminderId, overspendingId, paydayId
        ])

        // Only schedule if user has granted permission
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            scheduleBillReminder(snapshot: snapshot, billDetails: billDetails)
            scheduleOverspendingAlert(snapshot: snapshot)
            schedulePaydayNotification(snapshot: snapshot)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            billReminderId, overspendingId, paydayId
        ])
    }

    // MARK: - Bill Reminder

    /// Schedules a consolidated bill reminder for 1 day before the next paycheck at 9:00 AM.
    private static func scheduleBillReminder(
        snapshot: BudgetSnapshot,
        billDetails: [(name: String, amount: Double)]
    ) {
        guard NotificationPreferences.billRemindersEnabled,
              !billDetails.isEmpty,
              let nextDate = snapshot.nextPaycheckDate else { return }

        // 1 day before next paycheck
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: nextDate),
              reminderDate > Date() else { return }

        let totalBillAmount = billDetails.reduce(0) { $0 + $1.amount }
        let billNames = billDetails.map { $0.name }.joined(separator: ", ")

        let content = UNMutableNotificationContent()
        content.title = "Bills Coming Up"
        content.body = "You have \(billDetails.count) bill\(billDetails.count == 1 ? "" : "s") totaling \(totalBillAmount.asCurrencyWhole()) on your next paycheck."
        content.subtitle = billNames
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: billReminderId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Overspending Alert

    /// Schedules an overspending alert when allocated + bills exceed 90% of the paycheck.
    private static func scheduleOverspendingAlert(snapshot: BudgetSnapshot) {
        guard NotificationPreferences.overspendingAlertsEnabled,
              snapshot.paycheckAmount > 0,
              snapshot.daysUntilNextPaycheck > 1,
              !snapshot.isDone else { return }

        let spent = snapshot.totalAllocated + snapshot.totalBills
        let usedPercent = spent / snapshot.paycheckAmount

        guard usedPercent >= overspendingThreshold else { return }

        let percentText = Int(usedPercent * 100)

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body = "You've used \(percentText)% of this paycheck with \(snapshot.daysUntilNextPaycheck) day\(snapshot.daysUntilNextPaycheck == 1 ? "" : "s") left."
        content.sound = .default

        // Schedule for 8 PM today (or immediately if past 8 PM)
        let now = Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = 20
        components.minute = 0

        let trigger: UNNotificationTrigger
        if let targetDate = Calendar.current.date(from: components), targetDate > now {
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        } else {
            // Past 8 PM — fire in 30 seconds (shows as banner in-app or on Lock Screen)
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        }
        let request = UNNotificationRequest(identifier: overspendingId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Payday Notification

    /// Schedules a notification for the next paycheck date at 8:00 AM.
    private static func schedulePaydayNotification(snapshot: BudgetSnapshot) {
        guard NotificationPreferences.paydayNotificationsEnabled,
              let nextDate = snapshot.nextPaycheckDate,
              nextDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Payday! 🎉"
        content.body = "New pay period started! You have \(snapshot.paycheckAmount.asCurrencyWhole()) to budget."
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: nextDate)
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: paydayId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
