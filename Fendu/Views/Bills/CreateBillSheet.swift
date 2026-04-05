import SwiftUI
import SwiftData

struct CreateBillSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let paycheckInstances: [PaycheckInstance]
    var fundingAccounts: [Account] = []

    @State private var name = ""
    @State private var amount = ""
    @State private var recurrence: BillRecurrence = .everyPaycheck
    @State private var category: BillCategory = .other
    @State private var selectedPaycheckId: String
    @State private var selectedFundingAccount: Account?

    private var showFundingPicker: Bool {
        fundingAccounts.count > 1
    }

    init(paycheckInstances: [PaycheckInstance], initialPaycheckId: String, fundingAccounts: [Account] = []) {
        self.paycheckInstances = paycheckInstances
        self.fundingAccounts = fundingAccounts
        _selectedPaycheckId = State(initialValue: initialPaycheckId)
    }

    private var canSave: Bool {
        !name.isEmpty && (Double(amount) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Bill name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BILL NAME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        TextField(category == .savings ? "e.g. Vacation Fund, Emergency Fund" : "e.g. Mortgage, Phone Bill", text: $name)
                            .fontWeight(.bold)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack {
                            Text("$")
                                .fontWeight(.bold)
                                .foregroundStyle(.gray.opacity(0.5))
                            TextField("0.00", text: $amount)
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

                    // Frequency
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FREQUENCY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack(spacing: 8) {
                            ForEach(BillRecurrence.allCases) { option in
                                Button {
                                    recurrence = option
                                } label: {
                                    Text(option.displayName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            recurrence == option
                                                ? Color.brandGreen
                                                : Color(.systemGray6)
                                        )
                                        .foregroundStyle(
                                            recurrence == option
                                                ? .white
                                                : .secondary
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            recurrence == option
                                                ? nil
                                                : RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(BillCategory.allCases) { cat in
                                Button {
                                    category = cat
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.iconName)
                                            .font(.caption)
                                        Text(cat.displayName)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        category == cat
                                            ? Color.brandOrange
                                            : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        category == cat
                                            ? .white
                                            : .secondary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        category == cat
                                            ? nil
                                            : RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }

                    // Funding account
                    if showFundingPicker {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAID FROM")
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

                    // Starting paycheck
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STARTING PAYCHECK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(paycheckInstances) { instance in
                                    Button {
                                        selectedPaycheckId = instance.id
                                    } label: {
                                        Text(instance.date.formattedShortMonthDay())
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedPaycheckId == instance.id
                                                    ? Color.brandGreen
                                                    : Color(.systemGray6)
                                            )
                                            .foregroundStyle(
                                                selectedPaycheckId == instance.id
                                                    ? .white
                                                    : .secondary
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                selectedPaycheckId == instance.id
                                                    ? nil
                                                    : Capsule()
                                                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                    }

                    // Create button
                    Button {
                        createBill()
                    } label: {
                        Text(category == .savings ? "Create Savings Goal" : "Create Bill")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(canSave ? Color.brandGreen : Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.brandGreen.opacity(canSave ? 0.2 : 0), radius: 8, y: 4)
                    }
                    .disabled(!canSave)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(category == .savings ? "New Savings Goal" : "New Bill")
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
            if showFundingPicker {
                selectedFundingAccount = fundingAccounts.first
            }
        }
    }

    private func createBill() {
        guard canSave else { return }
        let billAmount = Double(amount) ?? 0
        let fundingId = selectedFundingAccount?.id.uuidString ?? fundingAccounts.first?.id.uuidString ?? ""

        let bill = Account(name: name, balance: billAmount, type: .bill)
        modelContext.insert(bill)

        let assignment = BillAssignment(
            paycheckId: selectedPaycheckId,
            billAccountId: bill.id.uuidString,
            amount: billAmount,
            recurrence: recurrence,
            category: category,
            fundingAccountId: fundingId
        )
        modelContext.insert(assignment)
        dismiss()
    }
}
