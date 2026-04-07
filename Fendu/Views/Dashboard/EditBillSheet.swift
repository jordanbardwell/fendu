import SwiftUI
import SwiftData

struct EditBillSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var assignment: BillAssignment
    let account: Account?
    let paycheckInstances: [PaycheckInstance]
    let currentPaycheckId: String
    var onMoveThisTime: ((BillAssignment, String, String) -> Void)? = nil
    var onOverrideAmount: ((BillAssignment, String, Double) -> Void)? = nil
    var fundingAccounts: [Account] = []
    var currentOverrideAmount: Double? = nil

    @State private var name: String
    @State private var amount: String
    @State private var recurrence: BillRecurrence
    @State private var category: BillCategory
    @State private var selectedPaycheckId: String
    @State private var selectedFundingAccount: Account?
    @State private var showDeleteConfirmation = false
    @State private var showMoveThisTime = false
    @State private var showAmountChangePrompt = false
    @State private var pendingNewAmount: Double = 0

    private var isRecurring: Bool {
        assignment.recurrence != .once
    }

    private var showFundingPicker: Bool {
        fundingAccounts.count > 1
    }

    init(assignment: BillAssignment, account: Account?, paycheckInstances: [PaycheckInstance], currentPaycheckId: String, onMoveThisTime: ((BillAssignment, String, String) -> Void)? = nil, onOverrideAmount: ((BillAssignment, String, Double) -> Void)? = nil, fundingAccounts: [Account] = [], currentOverrideAmount: Double? = nil) {
        self.assignment = assignment
        self.account = account
        self.paycheckInstances = paycheckInstances
        self.currentPaycheckId = currentPaycheckId
        self.onMoveThisTime = onMoveThisTime
        self.onOverrideAmount = onOverrideAmount
        self.fundingAccounts = fundingAccounts
        self.currentOverrideAmount = currentOverrideAmount
        _name = State(initialValue: account?.name ?? "")
        _amount = State(initialValue: String(format: "%.2f", currentOverrideAmount ?? assignment.amount))
        _recurrence = State(initialValue: assignment.recurrence)
        _category = State(initialValue: assignment.category)
        _selectedPaycheckId = State(initialValue: assignment.paycheckId)
        _selectedFundingAccount = State(initialValue: fundingAccounts.first { $0.id.uuidString == assignment.fundingAccountId })
    }

    private var canSave: Bool {
        !name.isEmpty && (Double(amount) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category == .savings ? "GOAL NAME" : "BILL NAME")
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

                    // Recurrence
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

                    // Move This Time — only for recurring bills
                    if isRecurring {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ONE-TIME MOVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray.opacity(0.7))
                                .tracking(1.5)

                            Button {
                                showMoveThisTime = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.uturn.right.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.brandOrange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Move This Time Only")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        Text("Skip this paycheck and move to another, just once. The recurring schedule stays the same.")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.gray.opacity(0.5))
                                }
                                .padding(16)
                                .background(Color.brandOrange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.brandOrange.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Save
                    Button {
                        save()
                    } label: {
                        Text("Save Changes")
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

                    // Delete bill entirely
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text(category == .savings ? "Delete Savings Goal" : "Delete Bill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red.opacity(0.8))
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle(category == .savings ? "Edit Savings Goal" : "Edit Bill")
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
            .confirmationDialog(
                "Delete \(account?.name ?? "this bill")?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Bill & Unassign", role: .destructive) {
                    deleteBill()
                }
            } message: {
                Text("This will remove the bill and its assignment from all paychecks.")
            }
            .confirmationDialog(
                "Move \(account?.name ?? "bill") This Time",
                isPresented: $showMoveThisTime,
                titleVisibility: .visible
            ) {
                ForEach(paycheckInstances.filter { $0.id != currentPaycheckId }) { instance in
                    Button(instance.date.formattedShortMonthDay()) {
                        onMoveThisTime?(assignment, currentPaycheckId, instance.id)
                        dismiss()
                    }
                }
            } message: {
                Text("Pick which paycheck to move this bill to, just for this time.")
            }
            .alert(
                "Change Amount",
                isPresented: $showAmountChangePrompt
            ) {
                Button("All Paychecks") {
                    assignment.amount = pendingNewAmount
                    account?.balance = pendingNewAmount
                    dismiss()
                }
                Button("Just This One") {
                    onOverrideAmount?(assignment, currentPaycheckId, pendingNewAmount)
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Apply this amount change to all paychecks, or just this one?")
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let newAmount = Double(amount) ?? assignment.amount

        // Update non-amount fields unconditionally
        account?.name = name
        assignment.recurrence = recurrence
        assignment.category = category
        assignment.paycheckId = selectedPaycheckId
        assignment.fundingAccountId = selectedFundingAccount?.id.uuidString ?? assignment.fundingAccountId

        // Check if amount changed
        let currentEffective = currentOverrideAmount ?? assignment.amount
        let amountChanged = abs(newAmount - currentEffective) > 0.001

        if amountChanged && assignment.recurrence != .once {
            // Recurring bill with amount change — prompt user
            pendingNewAmount = newAmount
            showAmountChangePrompt = true
        } else {
            // One-time bill or no amount change — save directly
            assignment.amount = newAmount
            account?.balance = newAmount
            WidgetReloader.reloadAll()
            dismiss()
        }
    }

    private func deleteBill() {
        if let account {
            modelContext.delete(account)
        }
        modelContext.delete(assignment)
        WidgetReloader.reloadAll()
        dismiss()
    }
}
