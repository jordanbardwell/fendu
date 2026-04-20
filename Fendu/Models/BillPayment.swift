import Foundation
import SwiftData

@Model
final class BillPayment {
    var id: UUID = UUID()
    var billAssignmentId: String = ""
    var paycheckId: String = ""
    var paidDate: Date = Date()

    init(billAssignmentId: String, paycheckId: String, paidDate: Date = Date()) {
        self.id = UUID()
        self.billAssignmentId = billAssignmentId
        self.paycheckId = paycheckId
        self.paidDate = paidDate
    }
}
