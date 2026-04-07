import ActivityKit
import Foundation

struct FenduLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let remainingBalance: Double
        let totalAllocated: Double
        let totalBills: Double
        let paycheckAmount: Double
        let daysUntilNextPaycheck: Int
    }

    let paycheckDate: Date
    let nextPaycheckDate: Date
}
