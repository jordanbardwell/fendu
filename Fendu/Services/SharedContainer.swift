import Foundation
import SwiftData

enum SharedContainer {
    static let appGroupID = "group.com.jordanbardwell.Fendu"

    /// Legacy App Group store path — kept only for migration.
    static var legacyAppGroupStoreURL: URL {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
            .appendingPathComponent("BalanceBookGold.store")
    }

    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Account.self,
            Transaction.self,
            PaycheckConfig.self,
            PaycheckStatus.self,
            BillAssignment.self,
            BillSkip.self,
            BillAmountOverride.self,
            PaycheckSplit.self
        ])
        let config = ModelConfiguration(
            "BalanceBookGold",
            schema: schema,
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: config)
    }
}
