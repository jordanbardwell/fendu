import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var paycheckId: String = ""
    var account: Account?
    var amount: Double = 0
    var date: Date = Date()
    var note: String = ""
    var fundingAccountId: String = ""
    var paymentMethod: String = ""

    init(paycheckId: String, account: Account? = nil, amount: Double, date: Date, note: String = "", fundingAccountId: String = "", paymentMethod: String = "") {
        self.id = UUID()
        self.paycheckId = paycheckId
        self.account = account
        self.amount = amount
        self.date = date
        self.note = note
        self.fundingAccountId = fundingAccountId
        self.paymentMethod = paymentMethod
    }

    /// Whether this transaction represents income (stored as negative amount)
    var isIncome: Bool {
        amount < 0
    }

    /// Whether this transaction uses a payment method instead of a target account
    var isPaymentMethod: Bool {
        !paymentMethod.isEmpty
    }

    /// Whether this transaction is a transfer to a deposit account
    var isTransfer: Bool {
        account?.type == .checking || account?.type == .savings
    }

    /// Display name: deposit account for income, payment method for payments, account name otherwise
    var displayName: String {
        if isIncome {
            return account?.name ?? paymentMethod
        }
        if isPaymentMethod {
            return paymentMethod
        }
        return account?.name ?? "Unknown Account"
    }
}
