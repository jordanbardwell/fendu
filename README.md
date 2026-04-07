# Fendu

A Robinhood-inspired personal finance app for allocating paychecks across financial accounts and planning recurring bills. Originally built as a React web app, now a native iOS app using SwiftUI.

## Goal

Provide a clean, simple way to plan where each paycheck goes — splitting it across checking accounts, savings accounts, credit cards, loans, and recurring bills — so you always know exactly how much is left and where your money went. Bills can be assigned to specific paychecks and moved between them for better cash flow planning.

## Features

- **Paycheck Management** — Configure paycheck amount, frequency (weekly, bi-weekly, monthly), and start date
- **Deposit Account Splits** — Split each paycheck across multiple checking/savings accounts with Fixed or Remainder assignment, with a running total that counts down as you allocate (Pro)
- **Allocation Tracking** — Assign portions of each paycheck to specific accounts with notes; allocations grouped by funding account when splits are active
- **Income Tracking** — Record extra income (Venmo, cash, refunds) via an Expense/Income toggle; income displayed with green icon and "+$" formatting (Pro)
- **Recurring Bills** — Create bills (mortgage, car insurance, phone, etc.) and assign them to paychecks with recurrence: every paycheck, every other paycheck, or one-time (2 free, unlimited with Pro)
- **Bill Planning** — Move bills between paychecks to balance cash flow; one-time move option for recurring bills without changing the schedule
- **Active Progress Bars** — Two-tone breakdown bar showing allocated vs. spent per deposit account; paycheck pills fill proportionally as money is assigned
- **Done State** — Mark paychecks as complete to lock allocations and bills
- **Native Swipe Actions** — Swipe to delete transactions or unassign bills
- **Smart Notifications** — Bill reminders (1 day before payday), overspending alerts (fires once when 90%+ is used, re-triggers if you drop below and cross again), and payday notifications (new pay period). All local, no server needed. See [notifications.md](docs/notifications.md) for details
- **Home Screen Widget** — Small and medium widgets showing remaining paycheck balance and breakdown bar (bills, spent, remaining)
- **Live Activity** — Lock Screen and Dynamic Island showing remaining balance during active paycheck period
- **Guided Onboarding** — 7-step wizard: Welcome → Paycheck → Deposit Accounts → Other Accounts → Bills → Notifications → Pro Paywall
- **Credit Card Catalog** — Select from a catalog of major issuers (Chase, Amex, Capital One, etc.) and their specific card products
- **Account CRUD** — Create, edit, and delete accounts; deleting cascades to remove transactions
- **Persistent Storage** — All data saved locally on-device via SwiftData
- **iCloud Sync** — Automatic sync across iPhone/iPad via CloudKit (no third-party servers)
- **Freemium Subscription** — Free tier with usage limits, Pro unlocks everything ($3.99/mo or $29.99/yr with 7-day trial). See [subscriptions.md](docs/subscriptions.md) for details

## Tech Stack

### iOS App (Current)
- **SwiftUI** — Declarative UI framework (iOS 17+)
- **SwiftData** — Persistence with `@Model` and `@Query`
- **CloudKit** — iCloud sync via `ModelConfiguration(cloudKitDatabase: .automatic)`
- **StoreKit 2** — In-app subscriptions (freemium model, no server-side receipt validation)
- **WidgetKit** — Home Screen widgets (small + medium) with timeline provider
- **ActivityKit** — Live Activities for Lock Screen and Dynamic Island
- **UserNotifications** — Local notifications for bill reminders, overspending, and payday alerts
- **App Groups** — Shared container between app and widget extension
- **SF Symbols** — Native icon system
- **Xcode 15+** — Build tool

### Original Web App
- React 19, TypeScript, Vite, Tailwind CSS, Motion (Framer Motion)
- Source preserved in `src/App.tsx` for reference

## Project Structure

```
Fendu/
├── Fendu.swift                           # App entry point, ModelContainer setup, SubscriptionManager init
├── Fendu.entitlements                    # iCloud + CloudKit + push notification entitlements
├── Assets.xcassets/                      # Colors (#00c805 green, #ff5000 orange), AppIcon
├── Models/
│   ├── Account.swift                     # @Model: name, balance, type (credit/checking/savings/loan/bill)
│   ├── Transaction.swift                 # @Model: paycheckId, account, amount, date, note, isIncome
│   ├── PaycheckConfig.swift              # @Model: amount, frequency, startDate (singleton)
│   ├── PaycheckInstance.swift            # Computed struct (not persisted)
│   ├── PaycheckStatus.swift              # @Model: paycheckId, isDone
│   ├── PaycheckSplit.swift               # @Model: accountId, amount, isRemainder, orderIndex
│   ├── BillAssignment.swift              # @Model: paycheckId, billAccountId, amount, recurrence
│   ├── BillSkip.swift                    # @Model: one-time skip record for recurring bills
│   └── CreditCardCatalog.swift           # Issuer + card product catalog (Amex, Chase, etc.)
├── Services/
│   ├── PaycheckGenerator.swift           # Generates paycheck dates from config
│   ├── SubscriptionManager.swift         # StoreKit 2 subscription state + free/Pro gates
│   ├── SharedContainer.swift             # App Group shared ModelContainer factory
│   ├── StoreMigrator.swift               # One-time data migration to App Group container
│   ├── BudgetCalculator.swift            # Extracted paycheck math (shared with widget)
│   ├── WidgetReloader.swift              # Triggers widget timeline refresh on data changes
│   ├── LiveActivityManager.swift         # ActivityKit lifecycle (start/update/end)
│   ├── FenduLiveActivityAttributes.swift # Live Activity data model
│   ├── NotificationScheduler.swift       # Local notification scheduling engine
│   └── NotificationPreferences.swift     # UserDefaults-backed notification toggles
├── ViewModels/
│   └── AppState.swift                    # @Observable: modal states, selected paycheck
├── Views/
│   ├── MainTabView.swift                 # Tab bar: Dashboard, Bills, Profile
│   ├── Dashboard/
│   │   ├── DashboardView.swift           # Main screen, data wiring, sheet presentation
│   │   ├── PortfolioHeaderView.swift     # Remaining balance, two-tone breakdown bar
│   │   ├── PaycheckSelectorView.swift    # Horizontal paycheck pills with progress fill
│   │   ├── AllocationsListView.swift     # Transaction list grouped by funding account
│   │   ├── TransactionRowView.swift      # Single allocation/income row
│   │   ├── BillsSectionView.swift        # Bills assigned to current paycheck
│   │   ├── BillRowView.swift             # Single bill row with recurrence badge
│   │   ├── AssignBillSheet.swift         # Assign existing or create new bills
│   │   └── EditBillSheet.swift           # Edit bill details, move this time, delete
│   ├── Bills/
│   │   ├── BillsView.swift              # Dedicated bills management tab
│   │   └── CreateBillSheet.swift         # Create new bill with category + recurrence
│   ├── Accounts/
│   │   ├── AccountsGridView.swift        # 2-column grid of account cards
│   │   ├── AccountCardView.swift         # Single card with edit/delete
│   │   └── AccountFormSheet.swift        # Add/edit with credit card issuer picker
│   ├── Transactions/
│   │   └── AddTransactionSheet.swift     # Expense/Income toggle, payment method picker
│   ├── Settings/
│   │   └── PaycheckSettingsSheet.swift   # Amount, frequency, date config
│   ├── Profile/
│   │   ├── ProfileView.swift             # Paycheck settings, notification toggles, deposit accounts
│   │   └── DepositAccountEditSheet.swift # Per-account split assignment sheet
│   ├── Onboarding/
│   │   └── OnboardingView.swift          # 7-step wizard with per-account sub-steps
│   ├── Subscription/
│   │   ├── ProPaywallView.swift          # Full paywall (onboarding + Profile)
│   │   ├── ProFeaturePaywallView.swift   # Contextual paywall (feature gates)
│   │   └── ProBadgeView.swift            # "PRO" capsule badge
│   └── Shared/
│       └── SplitAssignmentView.swift     # Reusable Fixed/Remainder assignment view
└── Extensions/
    ├── Color+Brand.swift                 # .brandGreen, .brandOrange
    ├── Date+Formatting.swift             # Date display helpers
    └── Double+Currency.swift             # Currency formatting

FenduWidget/
├── FenduWidgetBundle.swift               # @main widget bundle (widget + live activity)
├── FenduWidget.swift                     # Widget configuration (small + medium)
├── FenduTimelineProvider.swift           # Data fetching + timeline generation
├── FenduWidgetViews.swift                # Small/medium widget UI, breakdown bar
└── FenduLiveActivityView.swift           # Lock Screen + Dynamic Island views
```

## Requirements

- **Xcode 15.4+**
- **iOS 17.0+** (required for `@Observable` and SwiftData)
- **Apple Developer Account** (required for iCloud/CloudKit sync and running on physical devices)

## Getting Started

1. Open `Fendu.xcodeproj` in Xcode
2. Set your **Development Team** in Signing & Capabilities
3. Verify the **iCloud** capability is enabled with container `iCloud.com.jordanbardwell.Fendu`
4. Verify **App Groups** capability with `group.com.jordanbardwell.Fendu` on both the app and widget extension targets
5. Select an iPhone simulator or connected device
6. Build and run (Cmd+R)

See [iCloud-Setup.md](iCloud-Setup.md) for detailed CloudKit configuration and troubleshooting.

## How Bills Work

1. **Create a bill** — Tap "+ Assign Bill" on any paycheck, then "Create New Bill" with a name and amount
2. **Set recurrence** — Choose "Every Paycheck", "Every Other Paycheck", or "One Time"
3. **Bills auto-appear** — Recurring bills show up on the correct paychecks based on the frequency and starting paycheck
4. **Move this time only** — Tap a recurring bill → "Move This Time Only" to shift it to another paycheck without changing the schedule
5. **Edit anytime** — Tap a bill to change name, amount, frequency, or starting paycheck
6. **Swipe to unassign** — Swipe left on a bill to remove it from the paycheck

Bills are deducted from the remaining balance alongside allocations. The portfolio header shows a breakdown of bills vs. spent amounts.

## Design Decisions

- **SwiftData over CoreData** — Modern, less boilerplate, native `@Query` integration with SwiftUI
- **CloudKit over third-party backends** — All data stays on-device and in Apple's iCloud; no Azure, AWS, or Firebase dependency
- **PaycheckInstance is computed, not persisted** — Generated from config at runtime to avoid sync issues when the user changes frequency/dates
- **Date-based recurrence math** — Bill recurrence uses date arithmetic (not array indices) so it works correctly as the paycheck window shifts over time
- **BillSkip for one-time overrides** — Separate model for skip records keeps the recurring BillAssignment clean while supporting exceptions
- **Negative amounts for income** — Income transactions store as negative amounts so all existing calculations (remaining balance, progress bars) work without formula changes
- **Per-account assignment screens** — Split setup uses focused one-screen-per-account flow instead of cluttered inline forms, reusable via `SplitAssignmentView` in both onboarding and profile
- **List with Sections** — Dashboard uses a flat `List` with `Section`s (not ScrollView) to support native swipe actions
- **Single AppState** — Matches the original React architecture; simple enough that per-screen ViewModels would be over-engineering
- **App Group shared container** — Widget extension runs in a separate process; shared ModelContainer via App Group lets both read the same SwiftData store
- **BudgetCalculator extraction** — Paycheck math extracted from DashboardView so widget, live activity, and notification scheduling all use the same logic
- **Local notifications over push** — No server needed; `UNUserNotificationCenter` with calendar/time-interval triggers. Max 3 pending at any time (well within iOS's 64 cap)
- **Widget + Live Activity are free** — Not gated behind Pro; they drive engagement and retention

## Development History

See [HISTORY.md](HISTORY.md) for a detailed log of all features, bug fixes, and design decisions made during development.
