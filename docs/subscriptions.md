# Fendu Pro — Subscription Plans

## Overview

Fendu uses a freemium model powered by StoreKit 2. Free users get a functional budgeting experience with limits, while Pro unlocks everything. The goal is to let users see enough value to convert without crippling the free experience.

## Plans

### Free

| Feature | Limit |
|---------|-------|
| Checking accounts | 1 |
| Savings accounts | 1 |
| Accounts (credit card, other) | 2 |
| Recurring bills | 2 |
| Deposit splits | Up to 2 accounts |
| Income tracking | Locked |
| iCloud sync | Yes |
| Allocations & transactions | Unlimited |

### Pro ($3.99/month or $29.99/year)

| Feature | Limit |
|---------|-------|
| Checking accounts | Unlimited |
| Savings accounts | Unlimited |
| Accounts (credit card, other) | Unlimited |
| Recurring bills | Unlimited |
| Deposit splits | Full access |
| Income tracking | Full access |
| iCloud sync | Yes |
| Allocations & transactions | Unlimited |

Both plans include a **7-day free trial** on first subscription.

## Graceful Degradation

If a Pro subscription expires:
- All existing data (accounts, bills, transactions) remains **visible and accessible**
- Users can still edit and delete existing items
- Only **creation** of new items beyond free limits is blocked
- No data is deleted or hidden

## Subscription Gates

Gates are centralized in `SubscriptionManager.swift`:

| Gate Method | What It Controls |
|-------------|-----------------|
| `canCreateChecking(currentCount:)` | Free: 1 checking account |
| `canCreateSavings(currentCount:)` | Free: 1 savings account |
| `canCreateAccount(currentCount:)` | Free: 2 accounts (credit/other) |
| `canCreateBill(currentCount:)` | Free: 2 recurring bills |
| `canSplitDeposits(depositCount:)` | Free: up to 2 deposit accounts, Pro: unlimited |
| `canTrackIncome()` | Pro only |

## Gate Locations

| File | What's Gated |
|------|-------------|
| `DashboardView.swift` | "Add Account" button, "Assign Bill" action |
| `BillsView.swift` | "+" toolbar button (at 2 bill limit) |
| `OnboardingView.swift` | Deposit account creation, account creation, bill creation |
| `AddTransactionSheet.swift` | Income toggle |
| `ProfileView.swift` | Deposit split editing |

## Paywall Screens

### ProPaywallView (Full Paywall)
- Shown at end of onboarding (step 5) and from Profile upgrade CTA
- Dark background with gradient glow, app icon, trial timeline
- Yearly/Monthly toggle, "Start for $0.00" CTA
- "Or continue with Free plan" option

### ProFeaturePaywallView (Contextual Paywall)
- Shown when a user hits a specific limit
- Triggers: `.accountLimit`, `.depositLimit`, `.bills`, `.depositSplits`, `.incomeTracking`
- Gradient title matching the trigger, feature bullet list, Yearly/Monthly toggle
- Full-sheet presentation

## Product IDs

| Product | ID | Price |
|---------|----|-------|
| Monthly | `com.jordanbardwell.fendu.pro.monthly` | $3.99/mo |
| Yearly | `com.jordanbardwell.fendu.pro.yearly` | $29.99/yr |

## StoreKit Testing

1. The StoreKit Configuration file (`FenduPro.storekit`) must be created via **Xcode > File > New > StoreKit Configuration File** (not hand-crafted)
2. Select it in **Edit Scheme > Run > Options > StoreKit Configuration**
3. Use **Debug > StoreKit > Manage Transactions** to view/delete test transactions
4. Delete app from simulator and clean build to reset state

## Architecture

- `SubscriptionManager` is `@MainActor @Observable`, injected via `.environment()` from the app root
- Products loaded on launch via `.task` in `Fendu.swift`
- `Transaction.updates` listener handles purchases/revocations from outside the app
- On successful purchase, `isPro` is set directly from the verified transaction for immediate UI unlock
- Paywall views retry `loadProducts()` on appear if products array is empty
