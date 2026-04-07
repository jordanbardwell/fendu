# Smart Notifications

Fendu uses local notifications via `UNUserNotificationCenter` — no server or push infrastructure required. All scheduling happens on-device.

## Notification Types

### Bill Reminders
- **Content**: "You have {N} bills totaling {$X} on your next paycheck" with bill names in the subtitle
- **Trigger**: 1 day before the next paycheck date at 9:00 AM
- **Conditions**: At least one bill assigned, next paycheck date exists and is in the future
- **Preference key**: `notif.billReminders`

### Overspending Alerts
- **Content**: "You've used {X}% of this paycheck with {N} days left"
- **Trigger**: 8:00 PM the same day the threshold is crossed (or 30 seconds if already past 8 PM)
- **Conditions**: Spending exceeds 90% of paycheck, more than 1 day until next paycheck, paycheck not marked done
- **Preference key**: `notif.overspending`
- **Dedup key**: `notif.overspendingSentForPaycheck` — stores the paycheck timestamp to prevent repeat alerts
- **Note**: Also displays as an in-app banner (not suppressed in foreground like other notification types)
- **Re-trigger behavior**: Fires once per threshold crossing. If spending drops below 90% (e.g., deleting a transaction) and then exceeds 90% again, the alert fires again. The dedup flag resets when spending drops below the threshold.

### Payday Notifications
- **Content**: "New pay period started! You have {$X} to budget"
- **Trigger**: Next paycheck date at 8:00 AM
- **Conditions**: Next paycheck date exists and is in the future
- **Preference key**: `notif.payday`

## Architecture

### Key Files

| File | Purpose |
|------|---------|
| `Fendu/Services/NotificationScheduler.swift` | Core scheduling engine — schedules, cancels, and evaluates all three notification types |
| `Fendu/Services/NotificationPreferences.swift` | UserDefaults-backed toggles for each notification type (default: all enabled) |
| `Fendu/Fendu.swift` | `NotificationDelegate` for foreground handling, clears delivered notifications on app foreground |
| `Fendu/Views/Dashboard/DashboardView.swift` | Calls `scheduleNotificationsIfNeeded()` on appear and when spending changes |
| `Fendu/Views/Onboarding/OnboardingView.swift` | Permission request at onboarding step 5 |
| `Fendu/Views/Profile/ProfileView.swift` | Notification settings card with per-type toggles |

### Scheduling Flow

1. User opens the app → `DashboardView.onAppear` fires
2. `scheduleNotificationsIfNeeded()` builds a `BudgetSnapshot` via `BudgetCalculator.currentSnapshot()` (always uses the current active paycheck, not the one being viewed)
3. `NotificationScheduler.rescheduleAll()` is called:
   - Removes all pending Fendu notifications
   - Checks system permission (`authorizationStatus == .authorized`)
   - Checks each `NotificationPreferences` toggle
   - Schedules only enabled types with appropriate triggers
4. When spending changes (`totalAllocated` updates), step 2–3 repeat reactively

### Notification Budget

iOS caps pending local notifications at 64. Fendu uses at most 3 at any time (1 per type), well within the limit.

### Foreground Behavior

The `NotificationDelegate` in `Fendu.swift` controls what happens when a notification fires while the app is open:
- **Overspending alerts**: Shown as a banner + sound (timely, actionable)
- **All others**: Suppressed (bill reminders and payday are not useful while actively in the app)

### Permission Request

- **Onboarding**: Step 5 ("Stay on Track") requests `[.alert, .sound, .badge]` permission. Users can skip with "Maybe Later".
- **Profile settings**: If system permission is denied, the Notifications card shows a warning banner with a button to open iOS Settings. Toggles are disabled when system permission is off.

## User Preferences

Stored in `UserDefaults.standard`:

| Key | Type | Default | Controls |
|-----|------|---------|----------|
| `notif.billReminders` | Bool | `true` | Bill reminder notifications |
| `notif.overspending` | Bool | `true` | Overspending alert notifications |
| `notif.payday` | Bool | `true` | Payday notifications |
| `notif.overspendingSentForPaycheck` | String | `nil` | Paycheck timestamp for which overspending alert already fired (resets when spending drops below 90%) |

Toggling a preference off in Profile cancels all pending notifications. They are rescheduled on the next DashboardView appear with the updated preferences.

### Permission States in Profile

The Notifications card in ProfileView handles three states:
- **Never asked** (`notDetermined`): Shows a green "Enable Notifications" button that triggers the iOS permission dialog
- **Denied**: Shows an orange warning banner with a "Settings" button to open iOS Settings
- **Authorized**: Shows the three toggles fully enabled
