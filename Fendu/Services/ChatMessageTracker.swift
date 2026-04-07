import Foundation

enum ChatMessageTracker {

    static let freeMessageLimit = 10

    private static let countKey = "fendu.chat.messageCount"
    private static let monthKey = "fendu.chat.monthYear"

    static func canSendMessage(isPro: Bool) -> Bool {
        if isPro { return true }
        resetIfNewMonth()
        return currentCount < freeMessageLimit
    }

    static func recordMessage() {
        resetIfNewMonth()
        UserDefaults.standard.set(currentCount + 1, forKey: countKey)
    }

    static var currentCount: Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    static var remainingMessages: Int {
        max(freeMessageLimit - currentCount, 0)
    }

    private static func resetIfNewMonth() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let current = formatter.string(from: Date())
        let stored = UserDefaults.standard.string(forKey: monthKey) ?? ""
        if current != stored {
            UserDefaults.standard.set(0, forKey: countKey)
            UserDefaults.standard.set(current, forKey: monthKey)
        }
    }
}
