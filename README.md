# Fendu

A Robinhood-inspired personal finance app for allocating paychecks across financial accounts and planning recurring bills. Originally built as a React web app, now a native iOS app using SwiftUI.

## Goal

Provide a clean, simple way to plan where each paycheck goes — splitting it across checking accounts, savings accounts, credit cards, loans, and recurring bills — so you always know exactly how much is left and where your money went. Bills can be assigned to specific paychecks and moved between them for better cash flow planning.

## Features

- **Paycheck Management** — Configure paycheck amount, frequency (weekly, bi-weekly, monthly), and start date
- **Deposit Account Splits** — Split each paycheck across multiple checking/savings accounts with Fixed or Remainder assignment, with a running total that counts down as you allocate
- **Allocation Tracking** — Assign portions of each paycheck to specific accounts with notes; allocations grouped by funding account when splits are active
- **Income Tracking** — Record extra income (Venmo, cash, refunds) via an Expense/Income toggle; income displayed with green icon and "+$" formatting
- **Recurring Bills** — Create bills (mortgage, car insurance, phone, etc.) and assign them to paychecks with recurrence: every paycheck, every other paycheck, or one-time
- **Bill Planning** — Move bills between paychecks to balance cash flow; one-time move option for recurring bills without changing the schedule
- **Active Progress Bars** — Two-tone breakdown bar showing allocated vs. spent per deposit account; paycheck pills fill proportionally as money is assigned
- **Done State** — Mark paychecks as complete to lock allocations and bills
- **Native Swipe Actions** — Swipe to delete transactions or unassign bills
- **Guided Onboarding** — 5-step wizard: Welcome → Paycheck → Deposit Accounts (per-account assignment screens) → Other Accounts → Bills
- **Credit Card Catalog** — Select from a catalog of major issuers (Chase, Amex, Capital One, etc.) and their specific card products
- **Account CRUD** — Create, edit, and delete accounts; deleting cascades to remove transactions
- **Persistent Storage** — All data saved locally on-device via SwiftData
- **iCloud Sync** — Automatic sync across iPhone/iPad via CloudKit (no third-party servers)

## Tech Stack

### iOS App (Current)
- **SwiftUI** — Declarative UI framework (iOS 17+)
- **SwiftData** — Persistence with `@Model` and `@Query`
- **CloudKit** — iCloud sync via `ModelConfiguration(cloudKitDatabase: .automatic)`
- **SF Symbols** — Native icon system
- **Xcode 15+** — Build tool

### Original Web App
- React 19, TypeScript, Vite, Tailwind CSS, Motion (Framer Motion)
- Source preserved in `src/App.tsx` for reference

## Project Structure

```
BalanceBookGold/
├── BalanceBookGoldApp.swift              # App entry point, ModelContainer setup, first-launch seeding
├── BalanceBookGold.entitlements          # iCloud + CloudKit + push notification entitlements
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
│   └── PaycheckGenerator.swift           # Generates paycheck dates from config
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
│   │   ├── ProfileView.swift             # Paycheck settings + deposit account rows
│   │   └── DepositAccountEditSheet.swift # Per-account split assignment sheet
│   ├── Onboarding/
│   │   └── OnboardingView.swift          # 5-step wizard with per-account sub-steps
│   └── Shared/
│       └── SplitAssignmentView.swift     # Reusable Fixed/Remainder assignment view
└── Extensions/
    ├── Color+Brand.swift                 # .brandGreen, .brandOrange
    ├── Date+Formatting.swift             # Date display helpers
    └── Double+Currency.swift             # Currency formatting
```

## Requirements

- **Xcode 15.4+**
- **iOS 17.0+** (required for `@Observable` and SwiftData)
- **Apple Developer Account** (required for iCloud/CloudKit sync and running on physical devices)

## Getting Started

1. Open `BalanceBookGold/Fendu.xcodeproj` in Xcode
2. Set your **Development Team** in Signing & Capabilities
3. Verify the **iCloud** capability is enabled with container `iCloud.com.balancebook.gold`
4. Select an iPhone simulator or connected device
5. Build and run (Cmd+R)

See [iCloud-Setup.md](BalanceBookGold/iCloud-Setup.md) for detailed CloudKit configuration and troubleshooting.

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

## Development History

See [HISTORY.md](HISTORY.md) for a detailed log of all features, bug fixes, and design decisions made during development.
