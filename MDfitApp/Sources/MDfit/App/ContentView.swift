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
    @State private var showSidebar = false

    var body: some View {
        NavigationSplitView {
            // Sidebar (iPad/Mac)
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            // Main content
            TabContent(selectedTab: selectedTab)
        }
    }
}

// MARK: - Sidebar Navigation

struct SidebarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        List(selection: $selectedTab) {
            Section {
                SidebarItem(icon: "house.fill", title: "Dashboard", tag: 0, selectedTab: $selectedTab)
                SidebarItem(icon: "list.bullet.rectangle.fill", title: "My Programs", tag: 1, selectedTab: $selectedTab)
                SidebarItem(icon: "slider.horizontal.3", title: "Workout Generator", tag: 2, selectedTab: $selectedTab)
                SidebarItem(icon: "play.rectangle.fill", title: "Video Library", tag: 3, selectedTab: $selectedTab)
                SidebarItem(icon: "figure.stand", title: "Pain Tool", tag: 4, selectedTab: $selectedTab)
                SidebarItem(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", tag: 5, selectedTab: $selectedTab)
                SidebarItem(icon: "book.fill", title: "Resources", tag: 6, selectedTab: $selectedTab)
                SidebarItem(icon: "person.fill", title: "My Profile", tag: 7, selectedTab: $selectedTab)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MD Fit")
        .background(Color.mdBlue)
    }
}

struct SidebarItem: View {
    let icon: String
    let title: String
    let tag: Int
    @Binding var selectedTab: Int

    var isSelected: Bool {
        selectedTab == tag
    }

    var body: some View {
        Button {
            selectedTab = tag
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .mdGold : .white.opacity(0.7))
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.mdGold.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content

struct TabContent: View {
    let selectedTab: Int

    var body: some View {
        switch selectedTab {
        case 0:
            DashboardView()
        case 1:
            ProgramsView()
        case 2:
            WorkoutGeneratorView()
        case 3:
            VideoLibraryView()
        case 4:
            PainToolView()
        case 5:
            ProgressTrackingView()
        case 6:
            ResourcesView()
        case 7:
            ProfileView()
        default:
            DashboardView()
        }
    }
}

// MARK: - Placeholder Views (to be built out)

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome
                    welcomeSection

                    // Next workout
                    nextWorkoutCard

                    // Quick actions
                    quickActions

                    // Upcoming events
                    upcomingEventsSection

                    // Recent progress
                    progressSnapshot
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }

    private var welcomeSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning")
                    .font(.mdSubheadline)
                    .foregroundColor(.mdGray)
                Text("John")
                    .font(.mdTitle)
            }
            Spacer()
            Circle()
                .fill(Color.mdBlue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text("JD")
                        .font(.mdHeadline)
                        .foregroundColor(.mdBlue)
                )
        }
    }

    private var nextWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Workout")
                    .font(.mdHeadline)
                Spacer()
                Text("Today")
                    .font(.mdCaption)
                    .foregroundColor(.mdGold)
            }

            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mdBlue.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "figure.mixed.cardio")
                            .font(.system(size: 28))
                            .foregroundColor(.mdBlue)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Body Power")
                        .font(.mdBody)
                    Text("60 min • Intermediate")
                        .font(.mdCaption)
                        .foregroundColor(.mdGray)
                }

                Spacer()

                Button {
                    // Start workout
                } label: {
                    Text("Start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.mdBlue)
                        .cornerRadius(8)
                }
            }
        }
        .mdCard()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickAction(icon: "plus.circle.fill", label: "Generate", color: .mdBlue) {}
            QuickAction(icon: "figure.stand", label: "Pain Tool", color: .mdGold) {}
            QuickAction(icon: "play.rectangle.fill", label: "Library", color: .mdBlue) {}
            QuickAction(icon: "calendar", label: "Schedule", color: .mdGold) {}
        }
    }

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Events")
                    .font(.mdHeadline)
                Spacer()
                Text("View All")
                    .font(.mdCaption)
                    .foregroundColor(.mdBlue)
            }

            EventRow(event: Event.sample)
        }
        .mdCard()
    }

    private var progressSnapshot: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.mdHeadline)

            HStack(spacing: 16) {
                StatBox(value: "4", label: "Workouts", color: .mdBlue)
                StatBox(value: "180", label: "Minutes", color: .mdGold)
                StatBox(value: "12", label: "Exercises", color: .mdBlue)
            }
        }
        .mdCard()
    }
}

struct QuickAction: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.mdGray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Text(event.startDate, format: .dateTime.month(.abbreviated))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.mdGold)
                Text(event.startDate, format: .dateTime.day())
                    .font(.system(size: 20, weight: .bold))
            }
            .frame(width: 48, height: 48)
            .background(Color.mdGold.opacity(0.1))
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.mdBody)
                Text(event.formattedTimeRange)
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            Spacer()

            if let spots = event.spotsRemaining {
                Text("\(spots) spots")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mdBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mdBlue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - More Placeholder Views

struct ProgramsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Enrolled") {
                    Text("8-Week Running: Beginner")
                    Text("Lower Back & SI Relief")
                }
                Section("Available") {
                    ForEach(Program.samples) { program in
                        ProgramRow(program: program)
                    }
                }
            }
            .navigationTitle("My Programs")
        }
    }
}

struct ProgramRow: View {
    let program: Program

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mdBlue.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: program.category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.mdBlue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.mdBody)
                Text("\(program.durationWeeks) weeks • \(program.difficulty.displayName)")
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            Spacer()

            Text(program.formattedPrice)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.mdGold)
        }
    }
}

struct VideoLibraryView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(.mdBlue)
                            Text(category.displayName)
                            Spacer()
                            Text("24")
                                .foregroundColor(.mdGray)
                        }
                    }
                }
            }
            .navigationTitle("Video Library")
            .searchable(text: $searchText)
        }
    }
}

struct PainToolView: View {
    @State private var selectedView: BodyMapSelection.BodyView = .front

    var body: some View {
        NavigationStack {
            VStack {
                // Body view toggle
                Picker("View", selection: $selectedView) {
                    Text("Front").tag(BodyMapSelection.BodyView.front)
                    Text("Back").tag(BodyMapSelection.BodyView.back)
                }
                .pickerStyle(.segmented)
                .padding()

                // Body diagram placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.mdBlue.opacity(0.05))

                    Image(systemName: "figure.stand")
                        .font(.system(size: 200))
                        .foregroundColor(.mdBlue.opacity(0.3))

                    Text("Tap where you feel pain")
                        .font(.mdSubheadline)
                        .foregroundColor(.mdGray)
                        .offset(y: 140)
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Pain Tool")
        }
    }
}

struct ProgressTrackingView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("This Week") {
                    HStack {
                        Text("Workouts Completed")
                        Spacer()
                        Text("4 / 5")
                            .foregroundColor(.mdBlue)
                    }
                    HStack {
                        Text("Total Minutes")
                        Spacer()
                        Text("180")
                            .foregroundColor(.mdBlue)
                    }
                }
                Section("Streak") {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.mdGold)
                        Text("12 Day Streak")
                        Spacer()
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}

struct ResourcesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Educational") {
                    Text("Understanding Pain")
                    Text("Movement Fundamentals")
                    Text("Recovery & Rest")
                }
                Section("Guides") {
                    Text("Getting Started")
                    Text("Equipment Guide")
                    Text("Nutrition Basics")
                }
            }
            .navigationTitle("Resources")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
