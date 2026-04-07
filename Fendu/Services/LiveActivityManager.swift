import ActivityKit
import Foundation

@MainActor @Observable
final class LiveActivityManager {

    private var currentActivity: Activity<FenduLiveActivityAttributes>?

    func startOrUpdate(snapshot: BudgetSnapshot) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let state = FenduLiveActivityAttributes.ContentState(
            remainingBalance: snapshot.remainingBalance,
            totalAllocated: snapshot.totalAllocated,
            totalBills: snapshot.totalBills,
            paycheckAmount: snapshot.paycheckAmount,
            daysUntilNextPaycheck: snapshot.daysUntilNextPaycheck
        )

        if let activity = currentActivity, activity.activityState == .active {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
        } else {
            let attributes = FenduLiveActivityAttributes(
                paycheckDate: snapshot.paycheckDate,
                nextPaycheckDate: snapshot.nextPaycheckDate ?? Date()
            )
            do {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
            } catch {
                print("[LiveActivityManager] Failed to start activity: \(error)")
            }
        }
    }

    func endIfNeeded() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    func restartIfExpired(snapshot: BudgetSnapshot) {
        if currentActivity == nil || currentActivity?.activityState != .active {
            startOrUpdate(snapshot: snapshot)
        }
    }
}
