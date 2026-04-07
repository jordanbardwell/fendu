import SwiftUI
import SwiftData
import WidgetKit
import UserNotifications

@main
struct BalanceBookGoldApp: App {
    @State private var appState = AppState()
    @State private var subscriptionManager = SubscriptionManager()
    @State private var liveActivityManager = LiveActivityManager()
    @Environment(\.scenePhase) private var scenePhase

    private let notificationDelegate = NotificationDelegate()
    let container: ModelContainer

    init() {
        StoreMigrator.migrateIfNeeded()

        do {
            container = try SharedContainer.makeModelContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(subscriptionManager)
                .environment(liveActivityManager)
                .task {
                    await subscriptionManager.loadProducts()
                    await subscriptionManager.checkSubscriptionStatus()
                }
                .onOpenURL { url in
                    if url.scheme == "fendu" && url.host == "dashboard" {
                        appState.selectedTab = 0
                    }
                }
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                WidgetCenter.shared.reloadAllTimelines()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let id = notification.request.identifier
        // Show overspending alerts even in foreground; suppress others
        if id == "fendu.overspending" {
            return [.banner, .sound]
        }
        return []
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Query private var configs: [PaycheckConfig]
    @State private var needsOnboarding: Bool?

    var body: some View {
        let showOnboarding = needsOnboarding ?? configs.isEmpty

        if showOnboarding {
            OnboardingView {
                withAnimation { needsOnboarding = false }
            }
            .onAppear {
                if needsOnboarding == nil {
                    needsOnboarding = configs.isEmpty
                }
            }
        } else {
            MainTabView()
        }
    }
}
