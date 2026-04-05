import SwiftUI
import SwiftData

struct AssignBillSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let billAccounts: [Account]
    let existingAssignments: [BillAssignment]
    let paycheckId: String
    var fundingAccounts: [Account] = []

    @State private var showCreateBill = false
    @State private var newBillName = ""
    @State private var newBillAmount = ""
    @State private var recurrence: BillRecurrence = .everyPaycheck
    @State private var category: BillCategory = .other
    @State private var selectedFundingAccount: Account?

    private var showFundingPicker: Bool {
        fundingAccounts.count > 1
    }

    private var unassignedBills: [Account] {
        let assignedIds = Set(existingAssignments.map { $0.billAccountId })
        return billAccounts.filter { !assignedIds.contains($0.id.uuidString) }
    }

    private var canCreateBill: Bool {
        !newBillName.isEmpty && (Double(newBillAmount) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            List {
                // Existing unassigned bills
                if !unassignedBills.isEmpty {
                    Section {
                        ForEach(unassignedBills) { bill in
                            Button {
                                assignBill(bill)
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.brandOrange.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "doc.text")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.brandOrange)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bill.name)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        Text(bill.balance.asCurrency())
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.brandGreen)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Tap a bill to assign it to this paycheck")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .textCase(nil)
                    }
                }

                // Recurrence picker
                Section {
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
                                        .padding(.vertical, 12)
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
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                } header: {
                    Text("Bills assigned above will use this frequency")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .textCase(nil)
                }

                // Category picker
                Section {
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
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                }

                // Funding account
                if showFundingPicker {
                    Section {
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
                        .listRowSeparator(.hidden)
                    }
                }

                // Create new bill section
                Section {
                    if showCreateBill {
                        VStack(spacing: 12) {
                            TextField("Bill name (e.g. Mortgage, Phone)", text: $newBillName)
                                .fontWeight(.medium)
                                .padding(14)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                )

                            HStack {
                                Text("$")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray.opacity(0.5))
                                TextField("Amount", text: $newBillAmount)
                                    .fontWeight(.bold)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                            )

                            Button {
                                createAndAssignBill()
                            } label: {
                                Text("Create & Assign")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(canCreateBill ? Color.brandGreen : Color.gray.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(!canCreateBill)
                        }
                        .listRowSeparator(.hidden)
                    } else {
                        Button {
                            withAnimation {
                                showCreateBill = true
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandGreen.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.brandGreen)
                                }

                                Text("Create New")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.brandGreen)

                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    if unassignedBills.isEmpty && !showCreateBill {
                        Text("No unassigned bills. Create one below.")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
            .onAppear {
                if showFundingPicker {
                    selectedFundingAccount = fundingAccounts.first
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Assign Recurring")
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
    }

    private func assignBill(_ bill: Account) {
        let fundingId = selectedFundingAccount?.id.uuidString ?? fundingAccounts.first?.id.uuidString ?? ""
        let assignment = BillAssignment(
            paycheckId: paycheckId,
            billAccountId: bill.id.uuidString,
            amount: bill.balance,
            recurrence: recurrence,
            category: category,
            fundingAccountId: fundingId
        )
        modelContext.insert(assignment)
        dismiss()
    }

    private func createAndAssignBill() {
        guard canCreateBill else { return }
        let amount = Double(newBillAmount) ?? 0
        let fundingId = selectedFundingAccount?.id.uuidString ?? fundingAccounts.first?.id.uuidString ?? ""

        let bill = Account(name: newBillName, balance: amount, type: .bill)
        modelContext.insert(bill)

        let assignment = BillAssignment(
            paycheckId: paycheckId,
            billAccountId: bill.id.uuidString,
            amount: amount,
            recurrence: recurrence,
            category: category,
            fundingAccountId: fundingId
        )
        modelContext.insert(assignment)
        dismiss()
    }
}
