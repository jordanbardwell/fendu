import SwiftUI
import SwiftData

private let paymentMethods = [
    ("Cash", "banknote"),
    ("Venmo", "v.circle.fill"),
    ("Zelle", "bolt.fill"),
    ("PayPal", "p.circle.fill"),
    ("Apple Pay", "apple.logo"),
    ("CashApp", "dollarsign.square.fill"),
]

struct AddTransactionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let accounts: [Account]
    let paycheckId: String
    var fundingAccounts: [Account] = []

    private var selectableAccounts: [Account] {
        accounts.filter { $0.type != .bill && $0.type != .checking && $0.type != .savings }
    }

    private var depositAccounts: [Account] {
        accounts.filter { $0.type == .checking || $0.type == .savings }
    }

    private var showFundingPicker: Bool {
        fundingAccounts.count > 1
    }

    private var isTransferSelected: Bool {
        guard let account = selectedAccount else { return false }
        return account.type == .checking || account.type == .savings
    }

    @State private var isIncomeMode = false
    @State private var amount = ""
    @State private var selectedAccount: Account?
    @State private var selectedFundingAccount: Account?
    @State private var selectedPaymentMethod: String?
    @State private var note = ""
    @State private var date = Date()

    private var isPaymentMethodSelected: Bool {
        selectedPaymentMethod != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Expense / Income toggle
                    if !depositAccounts.isEmpty {
                        Picker("Transaction Type", selection: $isIncomeMode) {
                            Text("Expense").tag(false)
                            Text("Income").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack {
                            Text("$")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray.opacity(0.5))
                            TextField("0.00", text: $amount)
                                .font(.title2)
                                .fontWeight(.bold)
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                        )
                    }

                    if isIncomeMode {
                        incomeFields
                    } else {
                        expenseFields
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        TextField(isIncomeMode ? "e.g. Birthday money, Sold laptop" : "What is this for?", text: $note)
                            .fontWeight(.medium)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )
                    }

                    Button {
                        addTransaction()
                    } label: {
                        Text(buttonLabel)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!isValid)
                    .opacity(isValid ? 1 : 0.5)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(isIncomeMode ? "Add Income" : "Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .onAppear {
            selectedAccount = selectableAccounts.first
            if showFundingPicker {
                selectedFundingAccount = fundingAccounts.first
            }
        }
        .onChange(of: isIncomeMode) { _, income in
            selectedAccount = income ? depositAccounts.first : selectableAccounts.first
            selectedPaymentMethod = nil
            selectedFundingAccount = showFundingPicker ? fundingAccounts.first : nil
        }
    }

    // MARK: - Expense Fields (existing behavior)

    private var expenseFields: some View {
        Group {
            // Funding account (from account)
            if showFundingPicker {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FROM ACCOUNT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    Picker("Funding Account", selection: $selectedFundingAccount) {
                        ForEach(fundingAccounts) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                    )
                }
            }

            // Target: account or payment method
            VStack(alignment: .leading, spacing: 8) {
                Text("TO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.7))
                    .tracking(1.5)

                // Payment method quick picks
                paymentMethodPicker

                if isPaymentMethodSelected {
                    paymentMethodConfirmation
                } else {
                    Picker("Account", selection: $selectedAccount) {
                        Text("Select an account").tag(nil as Account?)
                        if !selectableAccounts.isEmpty {
                            Section("Accounts") {
                                ForEach(selectableAccounts) { account in
                                    Text(account.name).tag(account as Account?)
                                }
                            }
                        }
                        if !depositAccounts.isEmpty {
                            Section("Transfer to") {
                                ForEach(depositAccounts) { account in
                                    Text(account.name).tag(account as Account?)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Income Fields

    private var incomeFields: some View {
        Group {
            // FROM — payment method source
            VStack(alignment: .leading, spacing: 8) {
                Text("FROM")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray.opacity(0.7))
                    .tracking(1.5)

                paymentMethodPicker

                if isPaymentMethodSelected {
                    paymentMethodConfirmation
                }
            }

            // INTO — deposit account destination
            if depositAccounts.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INTO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    Picker("Deposit Account", selection: $selectedAccount) {
                        ForEach(depositAccounts) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    // MARK: - Shared Components

    private var paymentMethodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(paymentMethods, id: \.0) { method, icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if selectedPaymentMethod == method {
                                selectedPaymentMethod = nil
                            } else {
                                selectedPaymentMethod = method
                                // In expense mode, selecting a payment method clears the account
                                if !isIncomeMode {
                                    selectedAccount = nil
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 10))
                            Text(method)
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedPaymentMethod == method
                                ? Color.brandGreen.opacity(0.12)
                                : Color(.systemGray6)
                        )
                        .foregroundStyle(
                            selectedPaymentMethod == method
                                ? Color.brandGreen
                                : .secondary
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    selectedPaymentMethod == method
                                        ? Color.brandGreen
                                        : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            selectedPaymentMethod == method
                                ? nil
                                : Capsule()
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var paymentMethodConfirmation: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.brandGreen)
            Text(selectedPaymentMethod ?? "")
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Helpers

    private var buttonLabel: String {
        if isIncomeMode { return "Confirm Income" }
        if isTransferSelected { return "Confirm Transfer" }
        return "Confirm Allocation"
    }

    private var isValid: Bool {
        guard let value = Double(amount), value > 0 else { return false }
        if isIncomeMode {
            return isPaymentMethodSelected && selectedAccount != nil
        }
        return selectedAccount != nil || isPaymentMethodSelected
    }

    private func addTransaction() {
        guard let value = Double(amount), value > 0 else { return }

        if isIncomeMode {
            guard let destination = selectedAccount, isPaymentMethodSelected else { return }
            let transaction = Transaction(
                paycheckId: paycheckId,
                account: destination,
                amount: -value,
                date: date,
                note: note,
                fundingAccountId: destination.id.uuidString,
                paymentMethod: selectedPaymentMethod ?? ""
            )
            modelContext.insert(transaction)
        } else {
            guard selectedAccount != nil || isPaymentMethodSelected else { return }
            let fundingId = selectedFundingAccount?.id.uuidString ?? fundingAccounts.first?.id.uuidString ?? ""
            let transaction = Transaction(
                paycheckId: paycheckId,
                account: isPaymentMethodSelected ? nil : selectedAccount,
                amount: value,
                date: date,
                note: note,
                fundingAccountId: fundingId,
                paymentMethod: selectedPaymentMethod ?? ""
            )
            modelContext.insert(transaction)
        }
        dismiss()
    }
}
