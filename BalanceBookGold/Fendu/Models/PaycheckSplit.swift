import Foundation
import SwiftData

@Model
final class PaycheckSplit {
    var id: UUID = UUID()
    var accountId: String = ""
    var amount: Double = 0
    var isRemainder: Bool = false
    var orderIndex: Int = 0

    init(accountId: String, amount: Double, isRemainder: Bool = false, orderIndex: Int = 0) {
        self.id = UUID()
        self.accountId = accountId
        self.amount = amount
        self.isRemainder = isRemainder
        self.orderIndex = orderIndex
    }
}
