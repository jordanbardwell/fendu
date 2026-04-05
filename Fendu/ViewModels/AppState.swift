import SwiftUI
import SwiftData

@Observable
final class AppState {
    var selectedTab: Int = 0
    var showAddTransaction = false
    var selectedPaycheckId: String? = nil

    func selectInitialPaycheck(instances: [PaycheckInstance]) {
        guard !instances.isEmpty else { return }
        let ids = Set(instances.map { $0.id })
        if selectedPaycheckId == nil || !ids.contains(selectedPaycheckId ?? "") {
            selectedPaycheckId = PaycheckGenerator.currentPaycheckId(from: instances)
        }
    }
}
