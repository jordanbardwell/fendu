import SwiftUI
import SwiftData
import UserNotifications

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Query private var configs: [PaycheckConfig]
    @Query private var accounts: [Account]
    @Query private var splits: [PaycheckSplit]

    private var config: PaycheckConfig? { configs.first }

    @State private var amount: String = ""
    @State private var frequency: PayFrequency = .biWeekly
    @State private var startDate: Date = Date()
    @State private var semiMonthlyDay1: Int = 1
    @State private var semiMonthlyDay2: Int = 15
    @State private var hasLoaded = false
    @State private var isSaving = false
    @State private var showSaved = false
    @State private var showDatePicker = false

    // Deposit account management
    @State private var splitModes: [String: SplitMode] = [:]
    @State private var splitFixedAmounts: [String: String] = [:]
    @State private var hasSplitsLoaded = false
    @State private var newDepositName = ""
    @State private var newDepositType: AccountType = .checking
    @State private var editingDepositAccount: Account? = nil
    @State private var showProPaywall = false
    @State private var showSplitPaywall = false

    // Notification preferences
    @State private var billReminders = NotificationPreferences.billRemindersEnabled
    @State private var overspendingAlerts = NotificationPreferences.overspendingAlertsEnabled
    @State private var paydayNotifications = NotificationPreferences.paydayNotificationsEnabled
    @State private var systemNotificationsEnabled = true
    @State private var notificationsNeverAsked = false

    private var depositAccounts: [Account] {
        accounts.filter { $0.type == .checking || $0.type == .savings }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    proSectionCard
                    notificationSettingsCard
                    paycheckSettingsCard
                    depositAccountsCard
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Profile")
        }
        .onAppear {
            guard !hasLoaded, let config else { return }
            amount = String(format: "%.0f", config.amount)
            frequency = config.frequency
            startDate = config.startDate
            semiMonthlyDay1 = config.semiMonthlyDay1
            semiMonthlyDay2 = config.semiMonthlyDay2
            hasLoaded = true
        }
        .onAppear {
            guard !hasSplitsLoaded else { return }
            for split in splits {
                if split.isRemainder {
                    splitModes[split.accountId] = .remainder
                } else {
                    splitModes[split.accountId] = .fixed
                    splitFixedAmounts[split.accountId] = String(format: "%.0f", split.amount)
                }
            }
            hasSplitsLoaded = true
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            systemNotificationsEnabled = settings.authorizationStatus == .authorized
            notificationsNeverAsked = settings.authorizationStatus == .notDetermined
        }
    }

    // MARK: - Pro Section Card

    private var proSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if subscriptionManager.isPro {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandGreen.opacity(0.25), Color.brandGreen.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.brandGreen)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Fendu Pro")
                                .font(.title3)
                                .fontWeight(.bold)
                            ProBadgeView()
                        }
                        Text(subscriptionManager.currentPlanName.map { "\($0) · Active" } ?? "Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Manage Subscription")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandGreen.opacity(0.3), Color.brandGreen.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.brandGreen)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Fendu Pro")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Unlock the full experience")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                // Feature highlights
                VStack(alignment: .leading, spacing: 10) {
                    proFeatureRow(icon: "creditcard.fill", color: .blue, text: "Unlimited accounts")
                    proFeatureRow(icon: "arrow.clockwise", color: Color.brandOrange, text: "Unlimited recurring bills")
                    proFeatureRow(icon: "chart.pie.fill", color: .purple, text: "Deposit splits")
                    proFeatureRow(icon: "arrow.down.left", color: Color.brandGreen, text: "Income tracking")
                }
                .padding(.vertical, 4)

                // CTA
                Button {
                    showProPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Restore
                Button {
                    Task { await subscriptionManager.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            subscriptionManager.isPro
                                ? Color.brandGreen.opacity(0.2)
                                : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .sheet(isPresented: $showProPaywall) {
            ProPaywallView()
        }
    }

    private func proFeatureRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Notification Settings Card

    private var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.brandGreen)
                }
                Text("Notifications")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            if notificationsNeverAsked {
                Button {
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound, .badge]
                    ) { granted, _ in
                        DispatchQueue.main.async {
                            systemNotificationsEnabled = granted
                            notificationsNeverAsked = false
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.white)
                        Text("Enable Notifications")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else if !systemNotificationsEnabled {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.brandOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications are disabled")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Enable in Settings to receive alerts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandGreen)
                }
                .padding(12)
                .background(Color.brandOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 0) {
                notificationToggle(
                    icon: "doc.text.fill",
                    color: Color.brandOrange,
                    title: "Bill Reminders",
                    subtitle: "1 day before each paycheck",
                    isOn: $billReminders
                )
                Divider().padding(.leading, 48)
                notificationToggle(
                    icon: "exclamationmark.circle.fill",
                    color: .red,
                    title: "Overspending Alerts",
                    subtitle: "When 90% of paycheck is used",
                    isOn: $overspendingAlerts
                )
                Divider().padding(.leading, 48)
                notificationToggle(
                    icon: "banknote.fill",
                    color: Color.brandGreen,
                    title: "Payday Notifications",
                    subtitle: "When a new pay period starts",
                    isOn: $paydayNotifications
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .onChange(of: billReminders) { _, new in
            NotificationPreferences.billRemindersEnabled = new
            if !new { NotificationScheduler.cancelAll() }
        }
        .onChange(of: overspendingAlerts) { _, new in
            NotificationPreferences.overspendingAlertsEnabled = new
            if !new { NotificationScheduler.cancelAll() }
        }
        .onChange(of: paydayNotifications) { _, new in
            NotificationPreferences.paydayNotificationsEnabled = new
            if !new { NotificationScheduler.cancelAll() }
        }
    }

    private func notificationToggle(
        icon: String, color: Color, title: String,
        subtitle: String, isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
        }
        .tint(Color.brandGreen)
        .padding(.vertical, 10)
        .disabled(!systemNotificationsEnabled)
    }

    // MARK: - Paycheck Settings Card

    private var paycheckSettingsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.brandGreen)
                }
                Text("Paycheck Settings")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            // Amount
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
                    TextField("0", text: $amount)
                        .font(.title3)
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
                                        : .secondary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    frequency != freq
                                        ? RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                                        : nil
                                )
                        }
                    }
                }
            }

            if frequency == .semiMonthly {
                // Semi-monthly day pickers
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
                // Start Date
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEXT PAY DATE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray.opacity(0.7))
                        .tracking(1.5)

                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                        )
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

            // Save Button
            Button {
                isSaving = true
                savePaycheckChanges()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isSaving = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSaved = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showSaved = false }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Save Changes")
                    }
                }
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.brandGreen)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.brandGreen.opacity(0.2), radius: 8, y: 4)
            }
            .disabled(isSaving)

            if showSaved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brandGreen)
                    Text("Settings saved!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brandGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brandGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Deposit Accounts Card

    private func computeAssignedToOthers(excluding accountId: String) -> Double {
        depositAccounts
            .filter { $0.id.uuidString != accountId && splitModes[$0.id.uuidString] == .fixed }
            .reduce(0.0) { $0 + (Double(splitFixedAmounts[$1.id.uuidString] ?? "") ?? 0) }
    }

    private func splitSummary(for account: Account) -> String {
        let idStr = account.id.uuidString
        let mode = splitModes[idStr] ?? .fixed
        let paycheckAmt = Double(amount) ?? 0
        if mode == .remainder {
            let value = max(paycheckAmt - computeAssignedToOthers(excluding: idStr), 0)
            return "Remainder: \(value.asCurrency())"
        }
        let fixed = Double(splitFixedAmounts[idStr] ?? "") ?? 0
        return "\(fixed.asCurrency()) Fixed"
    }

    private var depositAccountsCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.brandGreen.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.brandGreen)
                }
                Text("Deposit Accounts")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("Where does your paycheck go? Add your checking & savings accounts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Add new deposit account
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Account name", text: $newDepositName)
                        .fontWeight(.medium)
                        .padding(14)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                        )

                    Picker("", selection: $newDepositType) {
                        Text("Checking").tag(AccountType.checking)
                        Text("Savings").tag(AccountType.savings)
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
                    )
                }

                Button {
                    addDepositAccount()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                        Text("Add Deposit Account")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(newDepositName.isEmpty ? Color.gray.opacity(0.3) : Color.brandGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(newDepositName.isEmpty)
            }

            // Existing deposit accounts — tappable rows
            if depositAccounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 24))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("No deposit accounts yet")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 8) {
                    ForEach(depositAccounts) { account in
                        Button {
                            if !subscriptionManager.canSplitDeposits(depositCount: depositAccounts.count) {
                                showSplitPaywall = true
                            } else {
                                editingDepositAccount = account
                            }
                        } label: {
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
                                        .foregroundStyle(.primary)
                                    Text(account.type.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                if depositAccounts.count > 1 {
                                    Text(splitSummary(for: account))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.gray.opacity(0.5))
                            }
                            .padding(14)
                            .background(Color(.systemGray6).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .sheet(isPresented: $showSplitPaywall) {
            ProFeaturePaywallView(trigger: .depositSplits)
        }
        .sheet(item: $editingDepositAccount) { account in
            let idStr = account.id.uuidString
            let paycheckAmt = Double(amount) ?? 0
            DepositAccountEditSheet(
                account: account,
                paycheckAmount: paycheckAmt,
                assignedToOthers: computeAssignedToOthers(excluding: idStr),
                splitMode: Binding(
                    get: { splitModes[idStr] ?? .fixed },
                    set: { newMode in
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
                ),
                onDelete: {
                    deleteDepositAccount(account)
                },
                onSave: {
                    saveSplitChanges()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers

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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 1)
            )
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

    private func savePaycheckChanges() {
        guard let config else { return }
        config.amount = Double(amount) ?? config.amount
        if frequency != config.frequency {
            config.frequency = frequency
        }
        if !Calendar.current.isDate(startDate, inSameDayAs: config.startDate) {
            config.startDate = startDate
        }
        config.semiMonthlyDay1 = semiMonthlyDay1
        config.semiMonthlyDay2 = semiMonthlyDay2
        WidgetReloader.reloadAll()
    }

    private func addDepositAccount() {
        guard !newDepositName.isEmpty else { return }
        let account = Account(name: newDepositName, type: newDepositType)
        modelContext.insert(account)
        newDepositName = ""
        WidgetReloader.reloadAll()
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

        saveSplitChanges()
    }

    private func saveSplitChanges() {
        let paycheckAmt = Double(amount) ?? 0

        // Delete existing splits
        for split in splits {
            modelContext.delete(split)
        }

        // Create new splits
        for (index, account) in depositAccounts.enumerated() {
            let idStr = account.id.uuidString
            let mode = splitModes[idStr] ?? .fixed
            let isRemainder = mode == .remainder
            let splitAmount: Double
            if isRemainder {
                let fixedTotal = computeAssignedToOthers(excluding: idStr)
                splitAmount = paycheckAmt - fixedTotal
            } else {
                splitAmount = Double(splitFixedAmounts[idStr] ?? "") ?? 0
            }

            let split = PaycheckSplit(
                accountId: idStr,
                amount: splitAmount,
                isRemainder: isRemainder,
                orderIndex: index
            )
            modelContext.insert(split)
        }
        try? modelContext.save()
        WidgetReloader.reloadAll()
    }
}
