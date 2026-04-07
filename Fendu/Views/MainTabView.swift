import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            BillsView()
                .tabItem {
                    Image(systemName: "arrow.clockwise")
                    Text("Recurring")
                }
                .tag(1)

            chatTab

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(profileTabTag)
        }
        .tint(Color.brandGreen)
    }

    @ViewBuilder
    private var chatTab: some View {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .tag(2)
        }
        #endif
    }

    private var profileTabTag: Int {
        #if canImport(FoundationModels)
        if #available(iOS 26, *) { return 3 }
        #endif
        return 2
    }
}
