import SwiftUI
import SwiftData

@main
struct BalanceBookGoldApp: App {
    @State private var appState = AppState()

    let container: ModelContainer

    init() {
        let schema = Schema([Account.self, Transaction.self, PaycheckConfig.self, PaycheckStatus.self, BillAssignment.self, BillSkip.self, BillAmountOverride.self, PaycheckSplit.self])
        let config = ModelConfiguration(
            "BalanceBookGold",
            schema: schema,
            cloudKitDatabase: .automatic
        )

        do {
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        .modelContainer(container)
    }
}

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
