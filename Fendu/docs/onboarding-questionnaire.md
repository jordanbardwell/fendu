# Onboarding Questionnaire Flow

## Overview

A 7-screen persuasion/personalization layer that plays **before** the existing functional onboarding (paycheck setup, accounts, bills, notifications, paywall). Designed to build desire and psychological investment before users hit the setup screens.

## Target User

People who currently use spreadsheets to budget — they pre-allocate each paycheck to accounts and bills **before** spending. The key differentiator from other budgeting apps (Mint, YNAB, Every Dollar) is **forward allocation vs. backward tracking**.

## User Transformation

**Before:** User gets paid, opens a spreadsheet, manually calculates what goes to rent, car payment, credit cards, savings. Tedious, error-prone, dreaded every pay period. Other budgeting apps only show where money already went — useless for planning ahead.

**After:** Payday hits and Fendu already knows the plan. Paycheck is split across accounts, bills are accounted for, and the user can see exactly what's left to spend. Set up once, adjust as needed. 30 seconds instead of 30 minutes.

**Core Benefits:**
1. "Replace your paycheck spreadsheet in under 2 minutes"
2. "Know exactly what's left after every bill, every paycheck"
3. "Plan where your money goes — don't just watch where it went"

---

## Complete Flow

```
Questionnaire (NEW)          Existing Setup (unchanged)
┌─────────────────┐          ┌─────────────────┐
│ 1. Welcome       │          │ 8.  Paycheck     │
│ 2. Goal Question │          │ 9.  Deposits     │
│ 3. Pain Points   │          │ 10. Accounts     │
│ 4. Solution      │    →     │ 11. Bills        │
│ 5. Processing    │          │ 12. Notifications│
│ 6. App Demo      │          │ 13. Pro Paywall  │
│ 7. Value Delivery│          └─────────────────┘
└─────────────────┘
```

---

## Screen-by-Screen Breakdown

### Screen 1: Welcome

- **Headline:** "Your paycheck, planned in seconds"
- **Subheadline:** "Stop splitting paychecks in a spreadsheet. Fendu allocates your money before you spend it."
- **Visual:** Arrow branch icon in green circle
- **CTA:** "Get Started"
- **Progress:** Bar at top (1/7)

### Screen 2: Goal Question

- **Headline:** "What would help you most?"
- **Type:** Single-select (must pick one to continue)
- **Options:**
  - 📉 Stop living paycheck to paycheck
  - 📋 Replace my budgeting spreadsheet
  - 💵 Know what I can actually spend after bills
  - 🏦 Split my paycheck across accounts
  - 📅 Stay ahead of recurring bills
  - 🎯 Finally stick to a budget that works
- **CTA:** "Continue" (appears after selection)

### Screen 3: Pain Points

- **Headline:** "What makes budgeting frustrating?"
- **Subheadline:** "Select all that apply"
- **Type:** Multi-select with checkboxes (must pick at least one)
- **Options:**
  - ✏️ Manually calculating where each paycheck goes
  - 🔄 Other apps only track where money already went
  - 😰 Forgetting a bill and overdrafting
  - ⏳ Spending 30+ min on budget math each pay period
  - 🤔 Never knowing what's actually safe to spend
  - 🗂️ Juggling multiple accounts with no clear plan
- **Navigation:** Back + Continue buttons

### Screen 4: Personalized Solution

- **Headline:** "Here's how Fendu fixes that"
- **Type:** Dynamic — only shows solutions for pain points the user selected
- **Format per item:**
  - Pain point (small, gray, strikethrough)
  - Solution (bold, with green icon)
- **Pain → Solution mappings:**
  - "Manually calculating..." → "Set up once — auto-split every paycheck" (arrow.triangle.branch)
  - "Other apps only track..." → "Plan where money goes before you spend it" (arrow.right.circle)
  - "Forgetting a bill..." → "Every bill accounted for, every pay period" (bell.badge)
  - "Spending 30+ min..." → "Full paycheck planned in under 2 minutes" (clock)
  - "Never knowing..." → "See exactly what's left after every bill" (eye)
  - "Juggling accounts..." → "One view — every account, every paycheck" (square.grid.2x2)
- **CTA:** "Show Me How It Works"

### Screen 5: Processing Moment

- **Visual:** Pulsing green circle with spinning gear icon
- **Text:** "Building your experience..."
- **Behavior:** 2-second animation, auto-advances to Screen 6
- **No CTA** — automatic transition
- **Progress bar hidden** during this screen

### Screen 6: App Demo

- **Headline:** "Try it — split a paycheck"
- **Subheadline:** "You just got paid $2,500.00. Tap to allocate."
- **Remaining counter:** Shows real-time remaining balance (starts at $2,500, updates as items are toggled)
- **Budget items (tap to toggle on/off):**
  - 🏠 Rent — $1,200.00
  - 💰 Savings — $400.00
  - 🚗 Car Payment — $350.00
  - ⚡ Utilities — $150.00
  - 📱 Phone — $85.00
  - 🎬 Subscriptions — $45.00
- **Minimum:** Must select at least 3 items to continue
- **Helper text:** "Select at least X more" (when < 3 selected)
- **CTA:** "See My Breakdown" (enabled after 3+ selections)

### Screen 7: Value Delivery

- **Headline:** "Your budget at a glance"
- **Content:** Clean list of selected allocations with amounts
- **Highlight:** "✨ Left to spend" row in green background with remaining amount
- **Subheadline:** "You just planned a whole paycheck in 15 seconds."
- **CTA:** "Set Up My Real Budget" → transitions to existing onboarding setup

---

## Files Changed

### New File

**`Views/Onboarding/OnboardingQuestionnaireView.swift`**

Single SwiftUI view containing all 7 screens, navigated via `@State private var step`. Matches existing codebase patterns:
- Brand green (`Color.brandGreen`) for all primary actions
- Spring animations (`response: 0.3, dampingFraction: 0.8`)
- `systemGray6` backgrounds for cards/inputs
- `cornerRadius(16)` for buttons, `cornerRadius(14)` for option cards
- `.padding(.horizontal, 24)` for content, `.padding(.bottom, 40)` for bottom buttons
- Progress bar (capsule fill) at top instead of dots to differentiate from setup flow

### Modified File

**`Fendu.swift`** — `RootView`

Added `@AppStorage("hasCompletedQuestionnaire")` to track questionnaire completion. Flow logic:

```
configs.isEmpty?
  ├── YES (new user)
  │   ├── hasCompletedQuestionnaire == false → OnboardingQuestionnaireView
  │   └── hasCompletedQuestionnaire == true  → OnboardingView (setup)
  └── NO (returning user) → MainTabView
```

If a user completes the questionnaire but force-quits before finishing setup, they'll see the setup flow on relaunch (skipping the questionnaire). Once setup is complete, they go straight to the main app on all future launches.

### Xcode Project

**`Fendu.xcodeproj/project.pbxproj`** — Added `OnboardingQuestionnaireView.swift` to:
- PBXBuildFile section (`AA000064001`)
- PBXFileReference section (`AB000064001`)
- Onboarding group (`AE000015001`)
- Sources build phase (`AF000002001`)

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Progress bar instead of dots | Differentiates questionnaire from setup flow; feels more modern for a quiz-style experience |
| Emojis for option icons | Makes lists feel lighter and more conversational than SF Symbols; questionnaire should feel like a quiz, not a form |
| Dynamic solution screen | Only shows solutions for pain points the user actually selected — feels personalized, not generic |
| 2-second processing pause | Psychological trick: makes the demo feel "earned" and personalized even though nothing is computed |
| Demo requires 3+ selections | Ensures enough investment to make the value delivery screen feel substantial |
| $2,500 demo paycheck | Realistic middle-ground amount; budget items total $2,230, leaving $270 "spending money" |
| No back button on Welcome | Standard pattern — first screen doesn't need one |
| AppStorage for state | Persists across force-quit; doesn't require SwiftData; automatically scoped to UserDefaults |

## Screens Skipped (Lean V1)

| Screen | Why Skipped |
|--------|-------------|
| Social Proof | No real testimonials yet — can add later when reviews exist |
| Tinder Cards (Pain Amplification) | Fun but not essential; pain points screen already captures this |
| Comparison Table | The interactive demo makes the case more effectively |
| Preference Configuration | The existing setup flow already handles all preference collection |
| Account Creation | App is anonymous — local data + iCloud backup, no accounts needed |
