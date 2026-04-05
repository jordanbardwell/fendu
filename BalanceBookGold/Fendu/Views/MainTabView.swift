import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

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

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(Color.brandGreen)
    }
}
