import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var notificationCount = 2
    @State private var checkedActivities: Set<String> = []
    @State private var selectedActivityLevel: ActivityLevel = .advanced
    @State private var showAllActivities = false
    @State private var dailyActivitiesExpanded = true

    enum ActivityLevel: String, CaseIterable {
        case beginner = "Beginner"
        case advanced = "Advanced"
        case elite = "Elite"

        var xpGoal: Int {
            switch self {
            case .beginner: return 50
            case .advanced: return 75
            case .elite: return 100
            }
        }

        var displayXP: String {
            switch self {
            case .beginner: return "50 XP"
            case .advanced: return "75 XP"
            case .elite: return "100+ XP"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        VStack(spacing: 16) {
                            Group {
                                searchBar
                                becomePatientCard
                                gemCard
                                dailyActivitiesSection
                                todayWorkoutSection
                            }
                            Group {
                                myWorkoutsSection
                                drJaredProgramsSection
                                quickActionsSection
                                myProgramsSection
                            }
                            Group {
                                upcomingEventsSection
                                recentActivitySection
                                getTheAppSection
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        ZStack {
            Color.mdInk
            RadialGradient(colors: [Color.mdAccent.opacity(0.16), .clear], center: .topTrailing, startRadius: 0, endRadius: 400)
        }
        .frame(height: 140)
        .overlay(
            VStack(spacing: 0) {
                HStack {
                    MDFitLogo(height: 52)
                    Spacer()
                    Button { } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell").font(.system(size: 22)).foregroundColor(.white)
                            if notificationCount > 0 {
                                Text("\(notificationCount)").font(.system(size: 10, weight: .bold)).foregroundColor(.white).frame(width: 16, height: 16).background(Color.mdErr).clipShape(Circle()).offset(x: 6, y: -4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back").font(.system(size: 15)).foregroundColor(.white.opacity(0.7))
                        Text(authService.currentUser?.firstName ?? "Alex").font(.mdDisplay(32, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Text("Amethyst").font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(.horizontal, 10).padding(.vertical, 5).background(Color.mdInk3).cornerRadius(999)
                        Text("320 XP").font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8).background(Color.mdInk2).cornerRadius(999)
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }
        )
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundColor(.mdMuted)
            TextField("What hurts? Search anything", text: $searchText).font(.system(size: 15)).foregroundColor(.mdText)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color.mdPaper).cornerRadius(MDTheme.radius)
        .overlay(RoundedRectangle(cornerRadius: MDTheme.radius).stroke(Color.mdLine, lineWidth: 1))
    }

    // MARK: - Become a Patient Card
    private var becomePatientCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12).fill(Color.mdInk).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "doc.text").font(.system(size: 20)).foregroundColor(.mdGold))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Become a patient").font(.mdDisplay(18, weight: .bold)).foregroundColor(.mdInk)
                    Text("Fill out your intake documents once, before your first visit. They stay on file for every appointment.").font(.system(size: 14)).foregroundColor(.mdText).lineLimit(2)
                }
                Spacer()
            }
            Button { } label: {
                Text("Start intake documents ›").font(.system(size: 14, weight: .bold)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 10).background(Color.mdInk).cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.mdGoldSoft).cornerRadius(MDTheme.radius)
        .overlay(RoundedRectangle(cornerRadius: MDTheme.radius).stroke(Color(hex: "e6d5ad"), lineWidth: 1))
    }

    // MARK: - Gem Card
    private var gemCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR GEM · LEVEL 2").font(.system(size: 11, weight: .bold)).foregroundColor(.mdGold).tracking(1)
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16).fill(Color.mdInk3).frame(width: 56, height: 56)
                            Image(systemName: "diamond.fill").font(.system(size: 28)).foregroundColor(Color(hex: "9b59b6"))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Amethyst").font(.mdDisplay(26, weight: .bold)).foregroundColor(.white)
                            Text("320 XP total").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("#4").font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdGold)
                    Text("OVERALL").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.7)).tracking(1)
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdGold, lineWidth: 1.5))
            }

            // XP Progress bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4).fill(LinearGradient(colors: [.mdGold, Color(hex: "e9d39f")], startPoint: .leading, endPoint: .trailing)).frame(width: geometry.size.width * 0.64)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("430 XP").font(.system(size: 14, weight: .bold)).foregroundColor(.mdGold)
                    Text("to").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    Image(systemName: "diamond.fill").font(.system(size: 12)).foregroundColor(Color(hex: "3498db"))
                    Text("Sapphire").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                }
            }

            // Stats row
            HStack(spacing: 12) {
                StatBox(value: "35", label: "XP today")
                StatBox(value: "2", label: "day streak", icon: "flame.fill", iconColor: .orange)
                StatBox(value: "35/50", label: "daily goal")
            }

            // Daily activities button
            Button { } label: {
                HStack {
                    Text("Daily activities: extra XP").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdGold)
                    Image(systemName: "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdGold)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.mdInk3).cornerRadius(8)
            }

            // Build a workout button
            Button { } label: {
                Text("BUILD A WORKOUT").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk).tracking(1)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [.mdGold, Color(hex: "e9d39f")], startPoint: .leading, endPoint: .trailing)).cornerRadius(8)
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color.mdInk
                RadialGradient(colors: [Color(hex: "9b59b6").opacity(0.15), .clear], center: .topLeading, startRadius: 0, endRadius: 200)
            }
        )
        .cornerRadius(MDTheme.radius)
        .overlay(RoundedRectangle(cornerRadius: MDTheme.radius).stroke(Color.mdInk3, lineWidth: 1))
        .overlay(
            VStack { LinearGradient(colors: [.mdGold, .clear], startPoint: .leading, endPoint: .trailing).frame(height: 3); Spacer() }.cornerRadius(MDTheme.radius)
        )
    }

    // MARK: - Daily Activities Section
    private var dailyActivitiesSection: some View {
        let earnedXP = DailyActivity.manualActivities.filter { checkedActivities.contains($0.id) }.reduce(0) { $0 + $1.xp }
        let goalMet = earnedXP >= selectedActivityLevel.xpGoal
        let visibleActivities = showAllActivities ? DailyActivity.manualActivities : Array(DailyActivity.manualActivities.prefix(8))

        return VStack(alignment: .leading, spacing: 16) {
            // Header with collapse arrow
            Button {
                withAnimation { dailyActivitiesExpanded.toggle() }
            } label: {
                HStack {
                    Text("DAILY ACTIVITIES").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                    Spacer()
                    Text("\(checkedActivities.count) of \(DailyActivity.manualActivities.count) done · +\(earnedXP) XP today")
                        .font(.system(size: 13)).foregroundColor(.mdMuted)
                    Image(systemName: dailyActivitiesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.mdMuted)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if dailyActivitiesExpanded {
                // Level selector
                HStack(spacing: 8) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Button {
                            selectedActivityLevel = level
                        } label: {
                            VStack(spacing: 2) {
                                Text(level.rawValue).font(.system(size: 14, weight: .semibold))
                                Text(level.displayXP).font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(selectedActivityLevel == level ? .mdInk : .mdText)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(selectedActivityLevel == level ? Color.mdGold : Color.mdPaper)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedActivityLevel == level ? Color.mdGold : Color.mdLine, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // XP Progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("+\(earnedXP)").font(.system(size: 18, weight: .bold)).foregroundColor(.mdAccent)
                        Text("XP from activities today").font(.system(size: 15)).foregroundColor(.mdText)
                    }
                    HStack(spacing: 8) {
                        Text(goalMet ? "Goal met (\(selectedActivityLevel.xpGoal) XP)." : "Goal: \(selectedActivityLevel.xpGoal) XP")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(goalMet ? .mdSuccess : .mdText)
                        Text("·").foregroundColor(.mdMuted)
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").font(.system(size: 12)).foregroundColor(.orange)
                            Text("1-day streak").font(.system(size: 13, weight: .medium)).foregroundColor(.mdText)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.mdPaper2).cornerRadius(999)
                    }
                }

                // Activities list (single column with descriptions)
                VStack(spacing: 10) {
                    ForEach(visibleActivities, id: \.id) { activity in
                        DailyActivityRowFull(
                            activity: activity,
                            isChecked: checkedActivities.contains(activity.id),
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if checkedActivities.contains(activity.id) {
                                        checkedActivities.remove(activity.id)
                                    } else {
                                        checkedActivities.insert(activity.id)
                                    }
                                }
                            }
                        )
                    }
                }

                // Show all activities button
                if !showAllActivities {
                    Button {
                        withAnimation { showAllActivities = true }
                    } label: {
                        Text("Show all \(DailyActivity.manualActivities.count) activities")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.mdAccent)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }

                // Info text
                Text("Workouts: **30 XP** a day · **35** when you built it yourself · **50** for a Dr. Jared program or pain track · challenges: **+5** for sending, **+10** for doing one.")
                    .font(.system(size: 13)).foregroundColor(.mdMuted)
                + Text(" Build a workout").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdAccent)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Today's Workout Section
    private var todayWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S WORKOUT").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Text("Ready").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdSuccess)
            }

            // Full Body Strength card
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Body Strength").font(.mdDisplay(18, weight: .bold)).foregroundColor(.mdHeading)
                    Text("About 30 min · 8 exercises · 5 rounds · Intermediate").font(.system(size: 13)).foregroundColor(.mdMuted)
                }
                Button { } label: {
                    Text("Start Workout").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.mdInk).cornerRadius(8)
                }
            }
            .padding(16).background(Color.mdPaper2).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))

            // Short on time card
            VStack(alignment: .leading, spacing: 8) {
                Text("Short on time? 10-minute workout").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                Button { } label: {
                    Text("Change workout").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdAccentText)
                }
            }
            .padding(14).background(Color.mdPaper2).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
        }
        .mdCardStyle()
    }

    // MARK: - My Workouts Section
    private var myWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY WORKOUTS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Button { } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                        Text("Build a workout").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 8).background(Color.mdInk).cornerRadius(999)
                }
            }
            Text("Pick exercises from Dr. Jared's library, set your sets and reps, and save it. Doing your own workout is worth 35 XP(30 + 5), and you can send it to another member as a challenge.").font(.system(size: 13)).foregroundColor(.mdMuted)
        }
        .mdCardStyle()
    }

    // MARK: - Dr. Jared's Programs Section
    private var drJaredProgramsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("DR. JARED'S PROGRAMS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Text("Not sure where to start?").font(.mdDisplay(20, weight: .bold)).foregroundColor(.mdHeading)
                Text("Guided multi-week plans Dr. Jared built for the most common things we see: knee pain, back pain, plantar fasciitis, golf, pickleball, marathon, mobility, and more. Pick one and follow along.").font(.system(size: 14)).foregroundColor(.mdMuted)
            }

            Button { } label: {
                Text("Browse all programs").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.mdInk).cornerRadius(8)
            }

            // Program cards
            VStack(spacing: 12) {
                ProgramRow(category: "REHAB PROTOCOLS", title: "6 Week Low Back Reset", details: "6 weeks · beginner")
                ProgramRow(category: "REHAB PROTOCOLS", title: "Weak Shoulder Rebuild", details: "6 weeks · beginner")
                ProgramRow(category: "SPORT PERFORMANCE", title: "Golf Performance", details: "8 weeks · intermediate")
                ProgramRow(category: "MOBILITY", title: "Mobility Ladder", details: "4 weeks · all levels")
                ProgramRow(category: "STRENGTH", title: "Hypertrophy Block", details: "8 weeks · intermediate")
                ProgramRow(category: "REHAB PROTOCOLS", title: "Hip Strength", details: "6 weeks · beginner")
            }
        }
        .mdCardStyle()
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QUICK ACTIONS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)

            VStack(spacing: 12) {
                QuickActionRow(icon: "wand.and.stars", title: "Generate Workout", subtitle: "Custom routine")
                QuickActionRow(icon: "plus.square", title: "Build a Workout", subtitle: "Your own, +35 XP")

                HStack(spacing: 12) {
                    QuickActionCard(icon: "figure.walk", title: "Pain Tool", subtitle: "Find relief")
                    QuickActionCard(icon: "play.rectangle.fill", title: "Video Library", subtitle: "55 exercises")
                }

                QuickActionRow(icon: "calendar.badge.plus", title: "Book a Visit", subtitle: "See Dr. Jared")
            }
        }
        .mdCardStyle()
    }

    // MARK: - My Programs Section
    private var myProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY PROGRAMS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Button { } label: {
                    Text("See all").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdAccentText)
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk").font(.system(size: 16)).foregroundColor(.mdAccent)
                        Text("Knee & Hip Strength").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                    }
                    Text("Strength · 3 × 3 rounds About 25 min").font(.system(size: 12)).foregroundColor(.mdMuted)
                }
                Spacer()
                Button { } label: {
                    Text("Start").font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Color.mdInk).cornerRadius(999)
                }
            }
            .padding(14).background(Color.mdPaper2).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
        }
        .mdCardStyle()
    }

    // MARK: - Upcoming Events Section
    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UPCOMING EVENTS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Button { } label: {
                    Text("Book").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdAccentText)
                }
            }

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("Nov").font(.system(size: 11, weight: .semibold)).foregroundColor(.mdMuted)
                    Text("10").font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdHeading)
                }
                .frame(width: 50).padding(.vertical, 8).background(Color.mdPaper2).cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("In-Studio Follow-up / Training Session").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                    Text("Tue · 10:30 AM · 60 min").font(.system(size: 12)).foregroundColor(.mdMuted)
                }
                Spacer()
                Text("Booked").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdSuccess)
            }
            .padding(14).background(Color.mdPaper).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
        }
        .mdCardStyle()
    }

    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT ACTIVITY").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)

            VStack(spacing: 8) {
                ActivityRow(icon: "dumbbell.fill", title: "Knee strength", subtitle: "22 min · 6 exercises", date: "Yesterday", xp: nil)
                ActivityRow(icon: "figure.walk", title: "Logged knee pain", subtitle: nil, date: "Yesterday", xp: nil)
                ActivityRow(icon: "figure.flexibility", title: "Hip mobility", subtitle: "15 min · 5 exercises", date: "Nov 4", xp: nil)
                ActivityRow(icon: "figure.walk", title: "Logged knee pain", subtitle: nil, date: "Nov 3", xp: nil)
                ActivityRow(icon: "figure.walk", title: "Logged knee pain", subtitle: "6/10 · After work", date: "Oct 30", xp: nil)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Get The App Section
    private var getTheAppSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GET THE APP").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Get MD Fit on your Home Screen. One tap to open, full-screen, no App Store needed.").font(.system(size: 14)).foregroundColor(.mdMuted)
            Button { } label: {
                Text("Install MD Fit").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.mdInk).cornerRadius(8)
            }
        }
        .mdCardStyle()
    }
}

// MARK: - Supporting Components

struct StatBox: View {
    let value: String
    let label: String
    var icon: String? = nil
    var iconColor: Color = .mdGold

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon).font(.system(size: 12)).foregroundColor(iconColor)
                }
                Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
            }
            Text(label).font(.system(size: 11)).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(Color.mdInk3).cornerRadius(8)
    }
}

struct ProgramRow: View {
    let category: String
    let title: String
    let details: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category).font(.system(size: 10, weight: .bold)).foregroundColor(.mdAccentText).tracking(1)
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                Text(details).font(.system(size: 12)).foregroundColor(.mdMuted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.mdMuted)
        }
        .padding(14).background(Color.mdPaper2).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(.mdInk).frame(width: 40, height: 40).background(Color.mdPaper2).cornerRadius(10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                Text(subtitle).font(.system(size: 13)).foregroundColor(.mdMuted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.mdMuted)
        }
        .padding(14).background(Color.mdPaper).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(.mdInk)
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
            Text(subtitle).font(.system(size: 12)).foregroundColor(.mdMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(14)
        .background(Color.mdPaper).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let date: String
    let xp: Int?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16)).foregroundColor(.mdInk).frame(width: 36, height: 36).background(Color.mdPaper2).cornerRadius(8)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                if let subtitle = subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundColor(.mdMuted)
                }
            }
            Spacer()
            Text(date).font(.system(size: 12)).foregroundColor(.mdMuted)
        }
        .padding(.vertical, 8)
    }
}

struct DailyActivityRow: View {
    let activity: DailyActivity
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isChecked ? Color.mdGold : Color.mdLine, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isChecked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.mdGold)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Icon
                Image(systemName: activity.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isChecked ? .mdGold : .mdMuted)
                    .frame(width: 20)

                // Activity name and XP
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isChecked ? .mdHeading : .mdText)
                        .lineLimit(1)
                    Text("+\(activity.xp) XP")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isChecked ? .mdGold : .mdMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(isChecked ? Color.mdGoldSoft.opacity(0.5) : Color.mdPaper2)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isChecked ? Color.mdGold.opacity(0.5) : Color.mdLine, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Full-width activity row with description (matching web design)
struct DailyActivityRowFull: View {
    let activity: DailyActivity
    let isChecked: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: 12) {
                // Circular checkbox
                ZStack {
                    Circle()
                        .stroke(isChecked ? Color.mdSuccess : Color.mdLine, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if isChecked {
                        Circle()
                            .fill(Color.mdSuccess)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 2)

                // Activity details
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.mdHeading)
                    Text(activity.description)
                        .font(.system(size: 14))
                        .foregroundColor(.mdMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                // XP badge
                Text("+\(activity.xp)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.mdAccent)
            }
            .padding(16)
            .background(isChecked ? Color(hex: "e8f4fd") : Color.mdPaper)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isChecked ? Color.mdAccent.opacity(0.3) : Color.mdLine, lineWidth: 1)
            )
            .overlay(
                // Left accent bar when checked
                HStack {
                    if isChecked {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mdAccent)
                            .frame(width: 4)
                    }
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthService.shared)
    }
}
