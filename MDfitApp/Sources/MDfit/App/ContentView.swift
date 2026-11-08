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

// MARK: - Main Tab View (7 Tabs matching web exactly - custom tab bar)

struct MainTabView: View {
    @Binding var selectedTab: Int
    @State private var showMoreMenu = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: WorkoutGeneratorView()
                case 2: VideoLibraryView()
                case 3: PainToolView()
                case 4: ProgressView()
                case 5: ProfileView()
                case 6: Color.mdCream.onAppear { showMoreMenu = true }
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom 7-tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showMoreMenu) {
            MoreMenuSheet()
        }
        .onChange(of: selectedTab) { newValue in
            if newValue == 6 {
                showMoreMenu = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { selectedTab = 5 }
            }
        }
    }
}

// MARK: - Custom Tab Bar (7 tabs visible)

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("slider.horizontal.3", "Workout"),
        ("play.rectangle.fill", "Videos"),
        ("figure.stand", "Pain"),
        ("chart.bar.fill", "Progress"),
        ("person.fill", "Profile"),
        ("ellipsis", "More")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                        Text(tabs[index].label)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .medium))
                    }
                    .foregroundColor(selectedTab == index ? .mdGold : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                }
            }
        }
        .background(Color(hex: "0f2942"))
        .padding(.bottom, UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0 > 0 ? 20 : 0)
        .background(Color(hex: "0f2942"))
    }
}

// MARK: - More Menu Sheet (Exact match)

struct MoreMenuSheet: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.mdCream.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("More").font(.system(size: 22, weight: .semibold)).foregroundColor(.mdHeading)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.mdMuted)
                                .frame(width: 36, height: 36)
                                .background(Circle().stroke(Color.mdLine, lineWidth: 1.5))
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 20)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            // Quick access group
                            VStack(spacing: 0) {
                                MoreMenuRow(icon: "figure.stand", title: "Pain Tool")
                                MoreMenuRow(icon: "play.rectangle.fill", title: "Video Library")
                                MoreMenuRow(icon: "calendar.badge.plus", title: "Book an appointment", showDivider: false)
                            }
                            .background(Color.mdGoldSoft.opacity(0.5))
                            .cornerRadius(12)

                            // Main sections
                            VStack(spacing: 0) {
                                NavigationLink(destination: PremadeProgramsView()) {
                                    MoreMenuRow(icon: "checkmark.square.fill", title: "Programs")
                                }
                                NavigationLink(destination: LecturesView()) {
                                    MoreMenuRow(icon: "graduationcap.fill", title: "Lectures & Live Q&A")
                                }
                                NavigationLink(destination: LeaderboardView()) {
                                    MoreMenuRow(icon: "trophy.fill", title: "Leaderboard")
                                }
                                NavigationLink(destination: MembershipView()) {
                                    MoreMenuRow(icon: "crown.fill", title: "Membership & 1-on-1")
                                }
                                NavigationLink(destination: MessengerView()) {
                                    MoreMenuRow(icon: "bubble.left.fill", title: "Message Dr. Jared")
                                }
                                NavigationLink(destination: HealthTipsView()) {
                                    MoreMenuRow(icon: "lightbulb.fill", title: "Health Tips", showDivider: false)
                                }
                            }
                            .background(Color.mdGoldSoft.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
    }
}

struct MoreMenuRow: View {
    let icon: String
    let title: String
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "1a6b9f"))
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mdHeading)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            if showDivider {
                Divider().padding(.leading, 54)
            }
        }
    }
}

// MARK: - Remaining Views (Programs, Lectures, Leaderboard, etc.)

struct PremadeProgramsView: View {
    @State private var selectedCategory: String = "All"
    private let categories = ["All", "Rehab Protocols", "Sport Performance", "Mobility", "Strength"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    programsHero
                    VStack(spacing: 16) {
                        categoryFilters
                        VStack(spacing: 20) {
                            ProgramCardLarge(category: "REHAB PROTOCOLS", title: "Low Back Reset", duration: "6-WEEK PROGRAM", description: "Calm the back down, then build it up.", details: "6 weeks · 0 days/week · Beginner")
                            ProgramCardLarge(category: "REHAB PROTOCOLS", title: "Shoulder Rebuild", duration: "6-WEEK PROGRAM", description: "Rotator cuff strength and range.", details: "6 weeks · 0 days/week · Beginner")
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16).padding(.top, 16)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var programsHero: some View {
        ZStack { Color.mdInk; RadialGradient(colors: [Color.mdInk3.opacity(0.5), .clear], center: .topTrailing, startRadius: 0, endRadius: 300) }
        .frame(height: 130)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) { Text("Premade ").font(.mdDisplay(28, weight: .bold)).foregroundColor(.white); Text("Programs").font(.mdDisplay(28, weight: .bold)).italic().foregroundColor(.mdGold) }
                Text("MULTI-WEEK PLANS FROM DR. JARED.").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.7)).tracking(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
        )
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button { selectedCategory = category } label: {
                        Text(category).font(.system(size: 14, weight: .medium)).foregroundColor(selectedCategory == category ? .white : .mdInk).padding(.horizontal, 16).padding(.vertical, 10).background(selectedCategory == category ? Color.mdInk : Color.mdPaper).cornerRadius(999).overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.mdLine, lineWidth: selectedCategory == category ? 0 : 1))
                    }
                }
            }
        }
    }
}

struct ProgramCardLarge: View {
    let category: String; let title: String; let duration: String; let description: String; let details: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color.mdInk
                VStack(spacing: 4) {
                    Text("MD FIT · \(category)").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.7)).tracking(1)
                    Text(title).font(.mdDisplay(24, weight: .bold)).foregroundColor(.white)
                    Text(duration).font(.system(size: 11, weight: .bold)).foregroundColor(.mdGold)
                }
            }
            .frame(height: 140).cornerRadius(14, corners: [.topLeft, .topRight])
            VStack(alignment: .leading, spacing: 6) { Text(description).font(.system(size: 14)).foregroundColor(.mdText); Text(details).font(.system(size: 12)).foregroundColor(.mdMuted) }
            .padding(16).background(Color.mdPaper).cornerRadius(14, corners: [.bottomLeft, .bottomRight])
        }
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mdLine, lineWidth: 1))
    }
}

// LecturesView, LeaderboardView, MembershipView, MessengerView, and HealthTipsView are defined in MoreMenuView.swift

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthService.shared)
    }
}
