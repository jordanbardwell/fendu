import Foundation
import SwiftData

@Model
final class TransactionPayment {
    var id: UUID = UUID()
    var transactionId: String = ""
    var paycheckId: String = ""
    var paidDate: Date = Date()

    init(transactionId: String, paycheckId: String, paidDate: Date = Date()) {
        self.id = UUID()
        self.transactionId = transactionId
        self.paycheckId = paycheckId
        self.paidDate = paidDate
    }
}
