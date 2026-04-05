import Foundation
import SwiftData

@Model
final class BillAmountOverride {
    var id: UUID = UUID()
    var billAssignmentId: String = ""
    var paycheckId: String = ""
    var overrideAmount: Double = 0

    init(billAssignmentId: String, paycheckId: String, overrideAmount: Double) {
        self.id = UUID()
        self.billAssignmentId = billAssignmentId
        self.paycheckId = paycheckId
        self.overrideAmount = overrideAmount
    }
}
