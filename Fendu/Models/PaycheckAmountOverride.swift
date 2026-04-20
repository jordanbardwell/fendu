import Foundation
import SwiftData

@Model
final class PaycheckAmountOverride {
    var id: UUID = UUID()
    var paycheckId: String = ""
    var overrideAmount: Double = 0

    init(paycheckId: String, overrideAmount: Double) {
        self.id = UUID()
        self.paycheckId = paycheckId
        self.overrideAmount = overrideAmount
    }
}
