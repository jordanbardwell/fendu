#if canImport(FoundationModels)
import Foundation
import FoundationModels

// MARK: - Get Current Paycheck

@available(iOS 26, *)
struct GetCurrentPaycheckTool: Tool {
    let name = "getCurrentPaycheck"
    let description = "Get the current paycheck summary including amount, remaining balance, spending, and bills"

    let dataProvider: BudgetDataProvider

    @Generable
    struct Arguments { }

    func call(arguments: Arguments) async throws -> String {
        dataProvider.currentPaycheckSummary()
    }
}

// MARK: - Get Transactions

@available(iOS 26, *)
struct GetTransactionsTool: Tool {
    let name = "getTransactions"
    let description = "Get recent spending transactions (allocations) for the current paycheck — this is where money was actually spent"

    let dataProvider: BudgetDataProvider

    @Generable
    struct Arguments { }

    func call(arguments: Arguments) async throws -> String {
        dataProvider.recentTransactions()
    }
}

// MARK: - Get Accounts

@available(iOS 26, *)
struct GetAccountsTool: Tool {
    let name = "getAccounts"
    let description = "Get all accounts with their types and balances"

    let dataProvider: BudgetDataProvider

    @Generable
    struct Arguments { }

    func call(arguments: Arguments) async throws -> String {
        dataProvider.accountsSummary()
    }
}

// MARK: - Get Bill Schedule

@available(iOS 26, *)
struct GetBillScheduleTool: Tool {
    let name = "getBillSchedule"
    let description = "Get recurring bills assigned to the current and next paycheck — these are fixed scheduled payments, not discretionary spending"

    let dataProvider: BudgetDataProvider

    @Generable
    struct Arguments { }

    func call(arguments: Arguments) async throws -> String {
        dataProvider.billSchedule()
    }
}

// MARK: - Get Paycheck History

@available(iOS 26, *)
struct GetPaycheckHistoryTool: Tool {
    let name = "getPaycheckHistory"
    let description = "Compare the current paycheck period against previous paychecks — use paycheck dates, not today's date"

    let dataProvider: BudgetDataProvider

    @Generable
    struct Arguments {
        @Guide(description: "Number of paychecks to look back", .range(1...4))
        var count: Int
    }

    func call(arguments: Arguments) async throws -> String {
        dataProvider.paycheckHistory(count: arguments.count)
    }
}

#endif
