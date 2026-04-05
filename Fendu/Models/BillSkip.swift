import Foundation
import SwiftData

@Model
final class BillSkip {
    var id: UUID = UUID()
    var billAssignmentId: String = ""
    var paycheckId: String = ""

    init(billAssignmentId: String, paycheckId: String) {
        self.id = UUID()
        self.billAssignmentId = billAssignmentId
        self.paycheckId = paycheckId
    }
}
