import Foundation
import SwiftData

@Model
final class PaycheckStatus {
    var paycheckId: String = ""
    var isDone: Bool = false

    init(paycheckId: String, isDone: Bool = false) {
        self.paycheckId = paycheckId
        self.isDone = isDone
    }
}
