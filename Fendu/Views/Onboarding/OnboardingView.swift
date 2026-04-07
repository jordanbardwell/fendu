import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var accounts: [Account]
    @Query private var configs: [PaycheckConfig]
    @Query private var allBillAssignments: [BillAssignment]
    @Query private var splits: [PaycheckSplit]

    let onComplete: () -> Void

    @State private var step = 0
    @State private var showAccountForm = false
    @State private var showCreateBill = false
    @State private var showAccountLimitPaywall = false
    @State private var showBillsPaywall = false
    @State private var showDepositLimitPaywall = false

    // Paycheck setup
    @State private var paycheckAmount = ""
    @State private var frequency: PayFrequency = .biWeekly
    @State private var startDate = Date()
    @State private var showDatePicker = false
    @State private var semiMonthlyDay1 = 1
    @State private var semiMonthlyDay2 = 15

    // Deposit account setup
    @State private var newDepositName = ""
    @State private var newDepositType: AccountType = .checking

    // Split setup
    @State private var depositSubStep: Int = 0
    @State private var splitModes: [String: SplitMode] = [:]
    @State private var splitFixedAmounts: [String: String] = [:]
    @State private var isGoingForward = true

    private var depositAccounts: [Account] {
        accounts.filter { $0.type == .checking || $0.type == .savings }
    }

    private var nonDepositNonBillAccounts: [Account] {
        accounts.filter { $0.type != .bill && $0.type != .checking && $0.type != .savings }
    }

    private var fundingAccounts: [Account] {
        let splitAccountIds = Set(splits.map { $0.accountId })
        return accounts.filter { splitAccountIds.contains($0.id.uuidString) }
            .sorted { a, b in
                let aIdx = splits.first { $0.accountId == a.id.uuidString }?.orderIndex ?? 0
                let bIdx = splits.first { $0.accountId == b.id.uuidString }?.orderIndex ?? 0
                return aIdx < bIdx
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            if step < 6 {
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? Color.brandGreen : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 32)
            }

            switch step {
            case 0:
                welcomeStep
            case 1:
                paycheckStep
            case 2:
                depositAccountsStep
            case 3:
                accountsStep
            case 4:
                billsStep
            case 5:
                notificationStep
            case 6:
                proPaywallStep
            default:
                EmptyView()
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brandGreen)
            }

            Text("Welcome to\nFendu")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Track your paychecks, allocate funds,\nand manage your bills — all in one place.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                withAnimation { step = 1 }
            } label: {
                Text("Get Started")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Paycheck

    private var paycheckStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set Up Your Paycheck")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("We'll use this to generate your pay periods.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BASE AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack {
                            Text("$")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.gray.opacity(0.5))
                            TextField("0", text: $paycheckAmount)
                                .font(.title3)
                                .fontWeight(.bold)
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FREQUENCY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(PayFrequency.allCases) { freq in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        frequency = freq
                                    }
                                } label: {
                                    Text(freq.displayName)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            frequency == freq
                                                ? Color.brandGreen
                                                : Color(.systemGray6)
                                        )
                                        .foregroundStyle(
                                            frequency == freq
                                                ? .white
                                                : .gray
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    if frequency == .semiMonthly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAY DAYS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray.opacity(0.7))
                                .tracking(1.5)

                            HStack(spacing: 12) {
                                dayPicker(label: "First", selection: $semiMonthlyDay1)
                                dayPicker(label: "Second", selection: $semiMonthlyDay2)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEXT PAY DATE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.gray.opacity(0.7))
                                .tracking(1.5)

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    showDatePicker.toggle()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(Color.brandGreen)
                                    Text(startDate.formatted(date: .long, time: .omitted))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            if showDatePicker {
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .labelsHidden()
                                    .tint(Color.brandGreen)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 0 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    savePaycheckConfig()
                    withAnimation { step = 2 }
                } label: {
                    Text("Next")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Deposit Accounts

    private var depositAccountsStep: some View {
        VStack(spacing: 0) {
            Group {
                if depositSubStep == 0 {
                    depositAddStep
                } else if depositSubStep <= depositAccounts.count {
                    depositAssignStep
                } else {
                    depositSummaryStep
                }
            }
            .transition(.push(from: isGoingForward ? .trailing : .leading))
            .animation(.easeInOut(duration: 0.25), value: depositSubStep)
        }
    }

    // Sub-step 0: Add accounts
    private var depositAddStep: some View {
        let paycheckAmt = Double(paycheckAmount) ?? 0

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Deposit Accounts")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Where does your \(paycheckAmt.asCurrency()) paycheck go? Add your checking & savings accounts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                TextField("Account name", text: $newDepositName)
                    .fontWeight(.medium)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    Picker("", selection: $newDepositType) {
                        Text("Checking").tag(AccountType.checking)
                        Text("Savings").tag(AccountType.savings)
                    }
                    .pickerStyle(.segmented)

                    Button {
                        addDepositAccount()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.subheadline)
                            Text("Add")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(newDepositName.isEmpty ? Color.gray.opacity(0.3) : Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(newDepositName.isEmpty)
                }
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 0) {
                    if depositAccounts.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "building.columns")
                                .font(.system(size: 32))
                                .foregroundStyle(.gray.opacity(0.4))
                            Text("No deposit accounts yet")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ForEach(depositAccounts) { account in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: account.type == .checking ? "dollarsign.arrow.circlepath" : "banknote")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(account.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(account.type.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        deleteDepositAccount(account)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray.opacity(0.4))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)

                            if account.id != depositAccounts.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 1 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    if depositAccounts.count == 1 {
                        // Single account — auto-remainder, skip assignment
                        let idStr = depositAccounts[0].id.uuidString
                        splitModes[idStr] = .remainder
                        saveSplits()
                        withAnimation { step = 3 }
                    } else if !subscriptionManager.canSplitDeposits(depositCount: depositAccounts.count) {
                        // Not Pro — auto-remainder first account, skip splits
                        let idStr = depositAccounts[0].id.uuidString
                        splitModes[idStr] = .remainder
                        saveSplits()
                        withAnimation { step = 3 }
                    } else {
                        isGoingForward = true
                        withAnimation { depositSubStep = 1 }
                    }
                } label: {
                    Text("Continue")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(depositAccounts.isEmpty ? Color.gray.opacity(0.3) : Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(depositAccounts.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // Sub-steps 1...N: Per-account assignment
    private var depositAssignStep: some View {
        let index = depositSubStep - 1
        let account = depositAccounts[index]
        let idStr = account.id.uuidString
        let paycheckAmt = Double(paycheckAmount) ?? 0
        let assignedToOthers = computeAssignedToOthers(excluding: idStr)
        let noOtherRemainder = !splitModes.contains { $0.key != idStr && $0.value == .remainder }
        let isLastUnassigned = index == depositAccounts.count - 1 && noOtherRemainder

        let canContinue: Bool = {
            let mode = splitModes[idStr] ?? .fixed
            if mode == .remainder { return true }
            return (Double(splitFixedAmounts[idStr] ?? "") ?? 0) > 0
        }()

        return VStack(spacing: 20) {
            // Sub-step indicator
            HStack(spacing: 4) {
                Text("Account \(index + 1) of \(depositAccounts.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)

            SplitAssignmentView(
                account: account,
                paycheckAmount: paycheckAmt,
                assignedToOthers: assignedToOthers,
                splitMode: Binding(
                    get: { splitModes[idStr] ?? .fixed },
                    set: { newMode in
                        // Only one account can be remainder
                        if newMode == .remainder {
                            for key in splitModes.keys where key != idStr {
                                if splitModes[key] == .remainder {
                                    splitModes[key] = .fixed
                                }
                            }
                        }
                        splitModes[idStr] = newMode
                    }
                ),
                fixedAmount: Binding(
                    get: { splitFixedAmounts[idStr] ?? "" },
                    set: { splitFixedAmounts[idStr] = $0 }
                )
            )
            .padding(.horizontal, 24)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    isGoingForward = false
                    withAnimation { depositSubStep -= 1 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    // Auto-suggest remainder for last account if none set
                    if isLastUnassigned && splitModes[idStr] == nil {
                        splitModes[idStr] = .remainder
                    }
                    isGoingForward = true
                    withAnimation { depositSubStep += 1 }
                } label: {
                    Text("Continue")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canContinue ? Color.brandGreen : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canContinue)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Auto-suggest remainder for last account
            if isLastUnassigned && splitModes[idStr] == nil {
                splitModes[idStr] = .remainder
            }
        }
    }

    // Summary sub-step
    private var depositSummaryStep: some View {
        let paycheckAmt = Double(paycheckAmount) ?? 0
        let totalAssigned = depositAccounts.reduce(0.0) { total, account in
            let idStr = account.id.uuidString
            let mode = splitModes[idStr] ?? .fixed
            if mode == .remainder {
                return total + max(paycheckAmt - computeAssignedToOthers(excluding: idStr), 0)
            }
            return total + (Double(splitFixedAmounts[idStr] ?? "") ?? 0)
        }

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Split")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Here's how your \(paycheckAmt.asCurrency()) paycheck will be divided.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(depositAccounts) { account in
                        let idStr = account.id.uuidString
                        let mode = splitModes[idStr] ?? .fixed
                        let amount: Double = {
                            if mode == .remainder {
                                return max(paycheckAmt - computeAssignedToOthers(excluding: idStr), 0)
                            }
                            return Double(splitFixedAmounts[idStr] ?? "") ?? 0
                        }()

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 40, height: 40)
                                Image(systemName: account.type == .checking ? "dollarsign.arrow.circlepath" : "banknote")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.gray)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.name)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Text(mode == .remainder ? "Remainder" : "Fixed")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            Text(amount.asCurrency())
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                        .padding(16)
                        .background(Color(.systemGray6).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Total bar
                    HStack {
                        Text("Total")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(totalAssigned.asCurrency()) / \(paycheckAmt.asCurrency())")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                abs(totalAssigned - paycheckAmt) < 0.01
                                    ? Color.brandGreen
                                    : Color.brandOrange
                            )
                    }
                    .padding(16)
                    .background(
                        abs(totalAssigned - paycheckAmt) < 0.01
                            ? Color.brandGreen.opacity(0.08)
                            : Color.brandOrange.opacity(0.08)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    isGoingForward = false
                    withAnimation { depositSubStep = depositAccounts.count }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    saveSplits()
                    withAnimation { step = 3 }
                } label: {
                    Text("Next")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func computeAssignedToOthers(excluding accountId: String) -> Double {
        depositAccounts
            .filter { $0.id.uuidString != accountId && splitModes[$0.id.uuidString] == .fixed }
            .reduce(0.0) { $0 + (Double(splitFixedAmounts[$1.id.uuidString] ?? "") ?? 0) }
    }

    // MARK: - Accounts

    private var accountsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Your Accounts")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Credit cards and any other accounts you want to track.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Button {
                let accountCount = accounts.filter({ $0.type == .credit || $0.type == .other }).count
                if subscriptionManager.canCreateAccount(currentCount: accountCount) {
                    showAccountForm = true
                } else {
                    showAccountLimitPaywall = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add Account")
                        .fontWeight(.bold)
                }
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .sheet(isPresented: $showAccountForm) {
                AccountFormSheet(editingAccount: nil)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showAccountLimitPaywall) {
                ProFeaturePaywallView(trigger: .accountLimit)
            }
            .sheet(isPresented: $showDepositLimitPaywall) {
                ProFeaturePaywallView(trigger: .depositLimit)
            }

            if !nonDepositNonBillAccounts.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(nonDepositNonBillAccounts) { account in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: iconFor(account.type))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(account.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(account.type.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        modelContext.delete(account)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray.opacity(0.4))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)

                            if account.id != nonDepositNonBillAccounts.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("No accounts yet")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 2 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    withAnimation { step = 4 }
                } label: {
                    Text("Next")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Bills

    private var billsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Your Bills")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Rent, subscriptions, loans — add recurring bills to track.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            Button {
                let billCount = allBillAssignments.count
                if subscriptionManager.canCreateBill(currentCount: billCount) {
                    showCreateBill = true
                } else {
                    showBillsPaywall = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add Bill")
                        .fontWeight(.bold)
                }
                .font(.body)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .sheet(isPresented: $showCreateBill) {
                CreateBillSheet(
                    paycheckInstances: paycheckInstances,
                    initialPaycheckId: paycheckInstances.first?.id ?? "",
                    fundingAccounts: fundingAccounts
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBillsPaywall) {
                ProFeaturePaywallView(trigger: .bills)
            }

            if !allBillAssignments.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(allBillAssignments) { assignment in
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandOrange.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: assignment.category.iconName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.brandOrange)
                                }

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(billAccountName(for: assignment))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("\(assignment.amount.asCurrency()) · \(assignment.recurrence.shortLabel)")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        deleteBill(assignment)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray.opacity(0.4))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)

                            if assignment.id != allBillAssignments.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text")
                        .font(.system(size: 32))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("No bills yet")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button {
                    withAnimation { step = 3 }
                } label: {
                    Text("Back")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    withAnimation { step = 5 }
                } label: {
                    Text("Next")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Notifications (Step 5)

    private var notificationStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.brandGreen.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.brandGreen)
            }

            Text("Stay on Track")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Get notified about upcoming bills,\noverspending, and new pay periods.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                requestNotificationPermission()
            } label: {
                Text("Enable Notifications")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Button {
                withAnimation { step = 6 }
            } label: {
                Text("Maybe Later")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.bottom, 40)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in
            DispatchQueue.main.async {
                withAnimation { step = 6 }
            }
        }
    }

    // MARK: - Pro Paywall (Step 6)

    private var proPaywallStep: some View {
        ProPaywallView(onContinueFree: {
            onComplete()
        })
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private var paycheckInstances: [PaycheckInstance] {
        guard let config = configs.first else { return [] }
        return PaycheckGenerator.generateInstances(from: config)
    }

    private func billAccountName(for assignment: BillAssignment) -> String {
        accounts.first { $0.id.uuidString == assignment.billAccountId }?.name ?? "Unknown Bill"
    }

    private func deleteBill(_ assignment: BillAssignment) {
        if let account = accounts.first(where: { $0.id.uuidString == assignment.billAccountId }) {
            modelContext.delete(account)
        }
        modelContext.delete(assignment)
    }

    private func iconFor(_ type: AccountType) -> String {
        switch type {
        case .credit: return "creditcard"
        case .checking: return "dollarsign.arrow.circlepath"
        case .savings: return "banknote"
        case .loan: return "building.columns"
        case .bill: return "doc.text"
        case .other: return "square.grid.2x2"
        }
    }

    private func dayPicker(label: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.gray)
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Color.brandGreen)
                Picker("", selection: selection) {
                    ForEach(1...31, id: \.self) { day in
                        Text(daySuffix(day)).tag(day)
                    }
                }
                .labelsHidden()
                .tint(.primary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "\(day)st"
        case 2, 22: return "\(day)nd"
        case 3, 23: return "\(day)rd"
        default: return "\(day)th"
        }
    }

    private func savePaycheckConfig() {
        let amount = Double(paycheckAmount) ?? 2500

        if let existing = configs.first {
            existing.amount = amount
            existing.frequency = frequency
            existing.startDate = startDate
            existing.semiMonthlyDay1 = semiMonthlyDay1
            existing.semiMonthlyDay2 = semiMonthlyDay2
        } else {
            let config = PaycheckConfig(amount: amount, frequency: frequency, startDate: startDate, semiMonthlyDay1: semiMonthlyDay1, semiMonthlyDay2: semiMonthlyDay2)
            modelContext.insert(config)
        }
        try? modelContext.save()
    }

    private func addDepositAccount() {
        guard !newDepositName.isEmpty else { return }
        let checkingCount = depositAccounts.filter { $0.type == .checking }.count
        let savingsCount = depositAccounts.filter { $0.type == .savings }.count
        if newDepositType == .checking && !subscriptionManager.canCreateChecking(currentCount: checkingCount) {
            showDepositLimitPaywall = true
            return
        }
        if newDepositType == .savings && !subscriptionManager.canCreateSavings(currentCount: savingsCount) {
            showDepositLimitPaywall = true
            return
        }
        let account = Account(name: newDepositName, type: newDepositType)
        modelContext.insert(account)
        newDepositName = ""
    }

    private func deleteDepositAccount(_ account: Account) {
        let idStr = account.id.uuidString
        for split in splits where split.accountId == idStr {
            modelContext.delete(split)
        }
        splitModes.removeValue(forKey: idStr)
        splitFixedAmounts.removeValue(forKey: idStr)
        modelContext.delete(account)

        // If only 1 deposit account remains, auto-set it to remainder
        let remaining = depositAccounts.filter { $0.id != account.id }
        if remaining.count == 1 {
            splitModes[remaining[0].id.uuidString] = .remainder
        }
    }

    private func saveSplits() {
        // Remove existing splits
        for split in splits {
            modelContext.delete(split)
        }

        let paycheckAmt = Double(paycheckAmount) ?? 0

        for (index, account) in depositAccounts.enumerated() {
            let idStr = account.id.uuidString
            let mode = splitModes[idStr] ?? .fixed
            let isRemainder = mode == .remainder
            let amount: Double
            if isRemainder {
                let fixedTotal = computeAssignedToOthers(excluding: idStr)
                amount = paycheckAmt - fixedTotal
            } else {
                amount = Double(splitFixedAmounts[idStr] ?? "") ?? 0
            }

            let split = PaycheckSplit(
                accountId: idStr,
                amount: amount,
                isRemainder: isRemainder,
                orderIndex: index
            )
            modelContext.insert(split)
        }
        try? modelContext.save()
    }
}
