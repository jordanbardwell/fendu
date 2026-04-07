import SwiftUI
import SwiftData

struct BillsView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var allBillAssignments: [BillAssignment]
    @Query private var configs: [PaycheckConfig]
    @Query private var splits: [PaycheckSplit]

    @State private var showCreateBill = false
    @State private var editingAssignment: BillAssignment?
    @State private var showPaywall = false

    private var config: PaycheckConfig? { configs.first }

    private var fundingAccounts: [Account] {
        let splitAccountIds = Set(splits.map { $0.accountId })
        return accounts.filter { splitAccountIds.contains($0.id.uuidString) }
            .sorted { a, b in
                let aIdx = splits.first { $0.accountId == a.id.uuidString }?.orderIndex ?? 0
                let bIdx = splits.first { $0.accountId == b.id.uuidString }?.orderIndex ?? 0
                return aIdx < bIdx
            }
    }

    private var paycheckInstances: [PaycheckInstance] {
        guard let config else { return [] }
        return PaycheckGenerator.generateInstances(from: config)
    }

    private var billAccounts: [Account] {
        accounts.filter { $0.type == .bill }
    }

    /// Categories that have at least one bill, in enum order
    private var activeCategories: [BillCategory] {
        let cats = Set(allBillAssignments.map { $0.category })
        return BillCategory.allCases.filter { cats.contains($0) }
    }

    private func assignments(for category: BillCategory) -> [BillAssignment] {
        allBillAssignments.filter { $0.category == category }
    }

    private func categoryTotal(for category: BillCategory) -> Double {
        assignments(for: category).reduce(0) { $0 + $1.amount }
    }

    private func accountName(for assignment: BillAssignment) -> String {
        accounts.first { $0.id.uuidString == assignment.billAccountId }?.name ?? "Unknown Bill"
    }

    private func account(for assignment: BillAssignment) -> Account? {
        accounts.first { $0.id.uuidString == assignment.billAccountId }
    }

    private func anchorPaycheckLabel(for assignment: BillAssignment) -> String {
        guard let date = assignment.anchorDate else { return "Unknown" }
        return date.formattedShortMonthDay()
    }

    var body: some View {
        NavigationStack {
            List {
                if allBillAssignments.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray.opacity(0.3))
                            Text("No Recurring Items Yet")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("Add bills or savings goals to plan which paycheck covers them.")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    ForEach(activeCategories) { category in
                        Section {
                            ForEach(assignments(for: category)) { assignment in
                                Button {
                                    editingAssignment = assignment
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.brandOrange.opacity(0.12))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: category.iconName)
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.brandOrange)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(accountName(for: assignment))
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.primary)
                                            HStack(spacing: 4) {
                                                Image(systemName: assignment.recurrence == .once ? "1.circle" : "arrow.clockwise")
                                                    .font(.system(size: 9))
                                                Text(assignment.recurrence.shortLabel)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                Text("·")
                                                    .font(.caption)
                                                Text("from \(anchorPaycheckLabel(for: assignment))")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .foregroundStyle(Color.brandOrange.opacity(0.7))
                                        }

                                        Spacer()

                                        Text(assignment.amount.asCurrency())
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.gray.opacity(0.4))
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteBillAssignment(assignment)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.iconName)
                                    .font(.caption)
                                Text(category.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text(categoryTotal(for: category).asCurrency())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.gray)
                            }
                            .foregroundStyle(.primary)
                            .textCase(nil)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if subscriptionManager.canCreateBill(currentCount: allBillAssignments.count) {
                            showCreateBill = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brandGreen)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                ProFeaturePaywallView(trigger: .bills)
            }
            .sheet(isPresented: $showCreateBill) {
                CreateBillSheet(
                    paycheckInstances: paycheckInstances,
                    initialPaycheckId: appState.selectedPaycheckId ?? paycheckInstances.first?.id ?? "",
                    fundingAccounts: fundingAccounts
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
            .sheet(item: $editingAssignment) { assignment in
                EditBillSheet(
                    assignment: assignment,
                    account: account(for: assignment),
                    paycheckInstances: paycheckInstances,
                    currentPaycheckId: assignment.paycheckId,
                    onMoveThisTime: moveBillThisTime,
                    fundingAccounts: fundingAccounts
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
            }
        }
    }

    private func deleteBillAssignment(_ assignment: BillAssignment) {
        if let account = account(for: assignment) {
            modelContext.delete(account)
        }
        modelContext.delete(assignment)
        WidgetReloader.reloadAll()
    }

    private func moveBillThisTime(_ assignment: BillAssignment, from currentId: String, to targetId: String) {
        let skip = BillSkip(
            billAssignmentId: assignment.id.uuidString,
            paycheckId: currentId
        )
        modelContext.insert(skip)

        let oneTime = BillAssignment(
            paycheckId: targetId,
            billAccountId: assignment.billAccountId,
            amount: assignment.amount,
            recurrence: .once,
            category: assignment.category,
            fundingAccountId: assignment.fundingAccountId
        )
        modelContext.insert(oneTime)
        WidgetReloader.reloadAll()
    }
}
