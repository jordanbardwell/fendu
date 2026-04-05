import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case credit
    case checking
    case savings
    case loan
    case bill
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .credit: return "Credit Card"
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .loan: return "Loan"
        case .bill: return "Recurring Bill"
        case .other: return "Other"
        }
    }
}

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var balance: Double = 0
    var typeRawValue: String = AccountType.credit.rawValue

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    var type: AccountType {
        get { AccountType(rawValue: typeRawValue) ?? .credit }
        set { typeRawValue = newValue.rawValue }
    }

    init(name: String, balance: Double = 0, type: AccountType) {
        self.id = UUID()
        self.name = name
        self.balance = balance
        self.typeRawValue = type.rawValue
    }
}
