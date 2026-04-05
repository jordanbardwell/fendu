# BalanceBook Gold — Development History

## Phase 1: React to iOS Conversion

Converted the original React web app (`src/App.tsx`, 652 lines) into a native iOS app using SwiftUI and SwiftData. Created 21 Swift files across Models, Views, Services, ViewModels, and Extensions. The app targets iOS 17+ for `@Observable` and SwiftData support.

**Key decisions:**
- SwiftData over CoreData for simpler persistence
- `PaycheckInstance` is a computed struct (not persisted) — generated at runtime from `PaycheckConfig`
- Paycheck IDs are date-based: `"paycheck-\(Int(date.timeIntervalSince1970))"`
- Single `AppState` (@Observable) manages all modal/selection state

## Phase 2: Credit Card Catalog

Added a credit card issuer/card picker when creating credit card accounts. 12 issuers (Amex, Chase, Capital One, Citi, Discover, etc.) with their specific card products. When type is `.credit`, the account form shows a horizontal issuer scroller and a 2-column card grid. The resolved name becomes "Issuer CardName" (e.g., "Chase Sapphire Reserve").

## Phase 3: iCloud Sync via CloudKit

Enabled CloudKit sync using `ModelConfiguration(cloudKitDatabase: .automatic)`. Required several fixes for CloudKit compatibility:
- Removed `@Attribute(.unique)` constraints (not allowed by CloudKit)
- Changed all relationships to optional (`[Transaction]? = []`)
- All `@Model` properties have default values
- `UIBackgroundModes` had to be array format `("remote-notification")` in project.pbxproj
- Added `BalanceBookGold.entitlements` with iCloud container `iCloud.com.balancebook.gold`

## Phase 4: Paycheck "Done" State

Added ability to mark paychecks as complete. Created `PaycheckStatus` SwiftData model linking a paycheck ID to a done state. Initial implementation used progress rings on paycheck pills with long-press context menus — both were rejected:
- **Progress rings**: User said they looked "old and stupid" — reverted to clean date-only pills
- **Context menus**: Always marked the newest paycheck due to gesture interception between List and ScrollView — removed entirely

**Final solution:** Added an explicit "Mark Paycheck as Done" / "Reopen Paycheck" button in the Allocations section. When done:
- Pills show a checkmark badge
- "+ Add Transaction" is replaced with "Paycheck Closed"
- Swipe-to-delete is disabled on transactions
- Section gets reduced opacity

## Phase 5: Native Swipe-to-Delete

Needed native `.swipeActions` for deleting transactions. First attempt used a custom `DragGesture` which caused "Invalid frame dimension" errors and felt non-native. Fixed by converting the dashboard from `ScrollView` + `VStack` to a `List` with `Section`s, which supports `.swipeActions` natively.

## Phase 6: Paycheck Settings Bug Fix

Fixed a bug where changing the paycheck amount would reset/orphan all allocated transactions. Root cause: `PaycheckSettingsSheet` always wrote back `startDate` on save, even if only the amount changed. The `@State` variable defaulted to `Date()` (not the config's date), and `DatePicker` could subtly modify the time component. Since paycheck IDs are date-based, any date drift orphaned transactions.

**Fix:**
- Initialize state via `init()` instead of `onAppear` (avoids `Date()` default)
- Only write back `startDate`/`frequency` if they actually changed (day-level comparison)

## Phase 7: Bills System — Paycheck-Assigned Recurring Bills

Separated bills from the generic "Accounts & Bills" grid into their own paycheck-aware system. Users can now plan which paycheck pays for which bill (mortgage, car insurance, phone, etc.) and move bills between paychecks for cash flow planning.

### Data model
- **`BillAssignment`** — Links a bill account to a paycheck ID with amount and recurrence
- **`BillRecurrence`** enum — `once`, `everyPaycheck`, `everyOther`
- **`BillSkip`** — One-time skip record for recurring bills (enables "move this time only")

### Recurrence logic
Each `BillAssignment` has an anchor paycheck (where it was first assigned). The `appliesTo(paycheckId:frequency:)` method computes whether the bill applies to any given paycheck by calculating the number of pay periods between the anchor and the target, then checking `periods % interval == 0`. The anchor date is extracted from the paycheck ID string.

### Views created
- **`BillsSectionView`** — Section between Allocations and Accounts showing assigned bills
- **`BillRowView`** — Displays bill name, amount, recurrence badge, and move button
- **`AssignBillSheet`** — Assign existing bills or create new ones inline with recurrence picker
- **`EditBillSheet`** — Edit name, amount, frequency, starting paycheck, and "Move This Time Only" for recurring bills

### Dashboard changes
- Bills section appears between Allocations and Accounts
- Remaining balance = paycheck amount - allocations - bills
- Portfolio header shows "Bills: $X · Spent: $Y" breakdown when bills are assigned
- Accounts grid renamed from "Your Accounts & Bills" to "Your Accounts", excludes bill-type accounts
- Add Transaction picker filters out bill-type accounts
- Account form shows "BILL AMOUNT" label when creating a bill

### One-time move for recurring bills
When a recurring bill needs to move just once (e.g., free up cash flow), the "Move This Time Only" option in the Edit Bill sheet:
1. Creates a `BillSkip` record for the current paycheck
2. Creates a one-time `BillAssignment` on the target paycheck
3. The recurring schedule continues unchanged on future paychecks

## UI/UX Fixes

- **Allocations header padding**: Fixed `.listRowInsets(EdgeInsets())` causing "Allocations" / "+ Add Transaction" to overflow to screen edges. Changed to `EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)`.
- **Color.brandGreen in ternaries**: Swift couldn't resolve `.brandGreen` in `foregroundStyle` ternaries. Fixed by using `Color.brandGreen` explicitly everywhere.

## Phase 8: Onboarding & Profile — Tabbed Navigation

Added a full onboarding flow and profile/settings screen. Onboarding is a 5-step wizard: Welcome → Paycheck Setup → Deposit Accounts → Other Accounts → Bills. Profile lets users edit paycheck settings and manage deposit accounts post-onboarding. Added `MainTabView` with Dashboard, Bills, and Profile tabs.

**Key files:** `OnboardingView.swift`, `ProfileView.swift`, `MainTabView.swift`, `BillsView.swift`

## Phase 9: Deposit Account Splits (PaycheckSplit)

Added ability to split paychecks across multiple deposit accounts. Created `PaycheckSplit` SwiftData model with `accountId`, `amount`, `isRemainder`, and `orderIndex`. One account can be designated as "Remainder" to receive whatever's left after fixed allocations.

Dashboard shows per-account breakdown bar in the portfolio header when 2+ accounts receive money, and groups allocations/bills by funding account.

## Phase 10: Income Transactions

Added ability to record extra income (Venmo, cash, refunds). `AddTransactionSheet` now has an Expense/Income segmented toggle. Income transactions store as negative amounts so all existing calculations (remaining balance, progress bars) work unchanged without formula modifications.

- `Transaction.isIncome` computed property (`amount < 0`)
- Income rows show green `arrow.down.left` icon, "INCOME" label, "+$amount" display
- Income mode: select FROM (payment method) + INTO (deposit account)

## Phase 11: Active Progress Bars & UI Polish

- **Two-tone breakdown bar** — Portfolio header segments now show a lighter fill for the full allocation and a darker fill for the spent portion within each segment
- **Paycheck pill progress** — Pills show a subtle green fill proportional to how much of the paycheck has been allocated
- **Keyboard dismiss** — Added tap-to-dismiss keyboard on ProfileView, CreateBillSheet, EditBillSheet, AssignBillSheet, and AddTransactionSheet
- **Allocation delete swipe** — Changed from green to red tint
- **Breakdown bar labels** — Added "left" suffix, line limits for long names, vertical layout at 3+ accounts
- **Dark mode** — Bumped pill stroke opacity for better visibility

## Phase 12: App Rename — BalanceBook Gold → Fendu

Renamed the app from "BalanceBook Gold" to "Fendu". Updated all in-code references, Xcode project name, and toolbar branding. Scheme remained `BalanceBookGold` for build compatibility.

## Phase 13: Deposit Account Split Redesign

Friend's feedback: the deposit account setup screen was cluttered with 2+ accounts, the remainder button was invisible, and splitting money felt like filling out a form rather than deliberately assigning a paycheck.

### Solution: Per-Account Assignment Screens

Broke the monolithic deposit account screen into focused, spacious screens — one screen to add accounts, then one screen per account to assign money, with a running total that counts down as you go.

### New shared component: `SplitAssignmentView`

Reusable view (used by both onboarding and profile) for assigning money to a single deposit account. Features:
- **Running total banner** — Large `"$X,XXX left to assign"` that counts down as you type, green when positive, orange when negative, with `.contentTransition(.numericText())` animation
- **Account identity** — Large icon + account name + type badge
- **Two tappable selection cards** — "Fixed Amount" (reveals dollar TextField) and "Remainder" (shows computed value). Spring-animated selection with checkmark indicators.
- Only one account can be remainder at a time

### Onboarding: Sub-step flow

The deposit accounts step (step 2) became a mini multi-step flow using `depositSubStep`:
- **Sub-step 0**: Add accounts (name + type picker, list of added accounts)
- **Sub-steps 1...N**: Per-account assignment using `SplitAssignmentView`
- **Final sub-step**: Summary showing all accounts with their assignments and a total bar
- Single account auto-assigns remainder and skips assignment screens entirely
- Slide transitions (`.push(from:)`) with forward/backward tracking

### Profile: Tappable rows + sheet

Replaced the cluttered inline split editing with clean tappable account rows:
- Each row shows icon + name + split summary ("$500 Fixed" or "Remainder: $1,500") + chevron
- Tapping opens `DepositAccountEditSheet` — a sheet wrapping `SplitAssignmentView` with Save and Delete buttons
- No more inline TextFields, remainder toggle badges, or total bars in the card itself

### New files
- `Views/Shared/SplitAssignmentView.swift` — Reusable per-account assignment view
- `Views/Profile/DepositAccountEditSheet.swift` — Sheet wrapper for profile editing

## Architecture Notes

- All `@Model` classes are CloudKit-compatible: optional relationships, default values, no unique constraints
- `PaycheckInstance` is ephemeral (computed from `PaycheckConfig`), everything else persists via SwiftData
- The app uses a flat `List` with `Section`s for the dashboard — required for native swipe actions
- Bill recurrence is date-math based, not index-based, so it works correctly even as the paycheck window shifts over time
