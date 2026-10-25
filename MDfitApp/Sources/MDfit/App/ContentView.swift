import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0

    var body: some View {
        if authService.isAuthenticated {
            MainTabView(selectedTab: $selectedTab)
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            BookingView()
                .tabItem {
                    Label("Book", systemImage: "calendar")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            ExercisesView()
                .tabItem {
                    Label("Exercises", systemImage: "figure.run")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
        .tint(Color.mdOrange)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
