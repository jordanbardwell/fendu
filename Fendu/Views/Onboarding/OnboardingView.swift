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
    @FocusState private var amountFieldFocused: Bool

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

    private var progress: CGFloat {
        CGFloat(step + 8) / 13.0
    }

    private var formattedAmountDisplay: some View {
        let raw = paycheckAmount
        let value = Double(raw) ?? 0

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            if raw.isEmpty {
                Text("$0")
                    .font(.system(size: 48, weight: .black))
                    .tracking(-1.5)
                    .foregroundStyle(.gray.opacity(0.3))
            } else {
                let intPart = Int(value)
                let formatted = NumberFormatter.localizedString(from: NSNumber(value: intPart), number: .decimal)
                Text("$\(formatted)")
                    .font(.system(size: 48, weight: .black))
                    .tracking(-1.5)
                    .foregroundStyle(.primary)

                // Show .00 cents in gray
                let cents = value - Double(intPart)
                if cents > 0 {
                    Text(String(format: ".%02d", Int(round(cents * 100))))
                        .font(.system(size: 48, weight: .black))
                        .tracking(-1.5)
                        .foregroundStyle(.gray.opacity(0.35))
                } else {
                    Text(".00")
                        .font(.system(size: 48, weight: .black))
                        .tracking(-1.5)
                        .foregroundStyle(.gray.opacity(0.35))
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar (matches questionnaire style, continues from 8/13)
            if step < 6 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                        Capsule()
                            .fill(Color.brandGreen)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }

            switch step {
            case 0:
                paycheckStep
            case 1:
                depositAccountsStep
            case 2:
                accountsStep
            case 3:
                billsStep
            case 4:
                notificationStep
            case 5:
                previewStep
            case 6:
                proPaywallStep
            default:
                EmptyView()
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }

    // MARK: - Paycheck

    private var paycheckStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 01 · Paycheck")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Text("What do you take home?")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                Text("After tax, after 401(k). The amount that actually lands in your account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AMOUNT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        VStack(alignment: .leading, spacing: 0) {
                            formattedAmountDisplay
                                .padding(.bottom, 4)

                            TextField("0", text: $paycheckAmount)
                                .focused($amountFieldFocused)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 1))
                                .foregroundStyle(.clear)
                                .tint(.clear)
                                .frame(height: 1)
                                .opacity(0.01)
                        }
                        .padding(20)
                        .background(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    !paycheckAmount.isEmpty && (Double(paycheckAmount) ?? 0) > 0
                                        ? Color.brandGreen
                                        : Color(.systemGray4),
                                    lineWidth: !paycheckAmount.isEmpty && (Double(paycheckAmount) ?? 0) > 0 ? 1.5 : 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            amountFieldFocused = true
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FREQUENCY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.gray.opacity(0.7))
                            .tracking(1.5)

                        HStack(spacing: 6) {
                                ForEach(PayFrequency.allCases) { freq in
                                    Button {
                                        amountFieldFocused = false
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            frequency = freq
                                        }
                                    } label: {
                                        Text(freq.displayName)
                                            .font(.system(size: 13, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
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
                                            .clipShape(Capsule())
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
                                amountFieldFocused = false
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
                .padding(20)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.immediately)

            Spacer(minLength: 0)

            Button {
                savePaycheckConfig()
                withAnimation { step = 1 }
            } label: {
                Text("Continue")
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
                Text("Step 02 · Split it")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Text("Where does it actually go?")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                Text("Tell Fendu which accounts the paycheck lands in. You can split one deposit across many.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                TextField("Account name", text: $newDepositName)
                    .fontWeight(.medium)
                    .padding(14)
                    .background(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
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
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            .padding(.horizontal, 24)
            .sheet(isPresented: $showDepositLimitPaywall) {
                ProPaywallView()
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(depositAccounts) { account in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brandGreen)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(Color(.systemBackground))
                                )

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
                        .padding(14)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.brandGreen, lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 24)
                    }

                    // Dashed add card
                    HStack(spacing: 8) {
                        Text("+")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.gray)
                        Text("Add another account")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            .foregroundStyle(Color(.systemGray4))
                    )
                    .padding(.horizontal, 24)
                }
            }
            .scrollDismissesKeyboard(.immediately)

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
                    if depositAccounts.count == 1 {
                        // Single account — auto-remainder, skip assignment
                        let idStr = depositAccounts[0].id.uuidString
                        splitModes[idStr] = .remainder
                        saveSplits()
                        withAnimation { step = 2 }
                    } else if !subscriptionManager.canSplitDeposits(depositCount: depositAccounts.count) {
                        // Not Pro — auto-remainder first account, skip splits
                        let idStr = depositAccounts[0].id.uuidString
                        splitModes[idStr] = .remainder
                        saveSplits()
                        withAnimation { step = 2 }
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

    private func computeAssignedToOthers(excluding accountId: String) -> Double {
        depositAccounts
            .filter { $0.id.uuidString != accountId && (splitModes[$0.id.uuidString] ?? .fixed) == .fixed }
            .reduce(0.0) { $0 + (Double(splitFixedAmounts[$1.id.uuidString] ?? "") ?? 0) }
    }

    // MARK: - Accounts

    private var accountsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 03 · Accounts")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Text("Any other accounts?")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                Text("Credit cards, loans — track them alongside your paycheck.")
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
                ProPaywallView()
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

    // MARK: - Bills

    private var billsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 04 · Bills")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Text("Add what's coming out.")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                Text("The big recurring ones. You can add more later — two free, unlimited with Pro.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(allBillAssignments) { assignment in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brandOrange.opacity(0.12))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: assignment.category.iconName)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.brandOrange)
                                )

                            VStack(alignment: .leading, spacing: 1) {
                                Text(billAccountName(for: assignment))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(assignment.recurrence.shortLabel)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            Text(assignment.amount.asCurrency())
                                .font(.subheadline)
                                .fontWeight(.bold)

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    deleteBill(assignment)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray.opacity(0.4))
                            }
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                    }

                    // Dashed add bill card
                    Button {
                        let billCount = allBillAssignments.count
                        if subscriptionManager.canCreateBill(currentCount: billCount) {
                            showCreateBill = true
                        } else {
                            showBillsPaywall = true
                        }
                    } label: {
                        Text("+ Add bill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                    .foregroundStyle(Color(.systemGray4))
                            )
                    }

                    // Inline limit nudge
                    if allBillAssignments.count >= 2 && !subscriptionManager.isPro {
                        Button {
                            showBillsPaywall = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("💡")
                                Text("2 of 2 free bills used — upgrade for unlimited.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
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
                ProPaywallView()
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

    // MARK: - Notifications (Step 5)

    private var enabledAlertCount: Int {
        [NotificationPreferences.paydayNotificationsEnabled,
         NotificationPreferences.billRemindersEnabled,
         NotificationPreferences.overspendingAlertsEnabled]
            .filter { $0 }.count
    }

    private var notificationStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step 05 · Notify")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)
                Text("A nudge, not a nag.")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.5)
                Text("Three local notifications, max. Nothing leaves your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 10) {
                notificationToggleRow(
                    emoji: "💸",
                    title: "Payday arrived",
                    subtitle: "Ping when a new paycheck opens",
                    isOn: Binding(
                        get: { NotificationPreferences.paydayNotificationsEnabled },
                        set: { NotificationPreferences.paydayNotificationsEnabled = $0 }
                    )
                )
                notificationToggleRow(
                    emoji: "📌",
                    title: "Bills coming up",
                    subtitle: "1 day before due date",
                    isOn: Binding(
                        get: { NotificationPreferences.billRemindersEnabled },
                        set: { NotificationPreferences.billRemindersEnabled = $0 }
                    )
                )
                notificationToggleRow(
                    emoji: "⚠️",
                    title: "Over 90% used",
                    subtitle: "Fires once per paycheck",
                    isOn: Binding(
                        get: { NotificationPreferences.overspendingAlertsEnabled },
                        set: { NotificationPreferences.overspendingAlertsEnabled = $0 }
                    )
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                requestNotificationPermission()
            } label: {
                Text("Turn on \(enabledAlertCount) alert\(enabledAlertCount == 1 ? "" : "s")")
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
                withAnimation { step = 5 }
            } label: {
                Text("or skip for now")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 40)
        }
    }

    private func notificationToggleRow(emoji: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 24))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.brandGreen)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in
            DispatchQueue.main.async {
                withAnimation { step = 5 }
            }
        }
    }

    // MARK: - Preview (Step 6)

    private var previewStep: some View {
        OnboardingPreviewView {
            withAnimation { step = 6 }
        }
    }

    // MARK: - Pro Paywall (Step 7)

    private var proPaywallStep: some View {
        ProPaywallView(onContinueFree: {
            onComplete()
        })
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
