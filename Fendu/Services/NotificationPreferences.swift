import Foundation

enum NotificationPreferences {
    private static let defaults = UserDefaults.standard

    static var billRemindersEnabled: Bool {
        get { defaults.object(forKey: "notif.billReminders") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "notif.billReminders") }
    }

    static var overspendingAlertsEnabled: Bool {
        get { defaults.object(forKey: "notif.overspending") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "notif.overspending") }
    }

    static var paydayNotificationsEnabled: Bool {
        get { defaults.object(forKey: "notif.payday") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "notif.payday") }
    }
}
