import SwiftUI

// Named ProgressTabView so it doesn't shadow SwiftUI.ProgressView (the spinner / progress bar).
struct ProgressTabView: View {
    @State private var selectedMonth = Date()
    @State private var weightInput = ""
    @State private var selectedSleep: String? = nil
    @State private var painLevel: Double = 5
    @State private var selectedPainArea = "Knee"
    @State private var painNote = ""

    let sleepOptions = ["<5h", "6h", "7h", "8h", "9h+"]
    let painAreas = ["Knee", "Lower Back", "Shoulder", "Neck", "Hip", "Ankle"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        VStack(spacing: 16) {
                            calendarSection
                            todayCheckInSection
                            performanceSection
                            painTrackerSection
                            leaderboardSection
                            badgesSection
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

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack {
            Color.mdInk
            RadialGradient(colors: [Color.mdAccent.opacity(0.15), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
        }
        .frame(height: 120)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    Text("Your ").font(.mdDisplay(30, weight: .bold)).foregroundColor(.white)
                    Text("Progress").font(.mdDisplay(30, weight: .bold)).italic().foregroundColor(.mdGold)
                }
                Text("EVERY REP, EVERY VISIT, EVERY WIN. SAVED TO YOUR ACCOUNT.").font(.system(size: 10, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
        )
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month navigation
            HStack {
                Text("CALENDAR").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                HStack(spacing: 16) {
                    Button { } label: {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdInk)
                    }
                    Text("November 2026").font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                    Button { } label: {
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdInk)
                    }
                }
            }

            // Calendar grid
            CalendarGrid()

            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .mdGold, label: "Goal reached")
                LegendItem(color: .mdAccent, label: "Repaired")
                LegendItem(color: .mdMuted, label: "Missed")
            }

            HStack(spacing: 16) {
                LegendItem(icon: "circle.fill", color: .mdInk, label: "Workout")
                LegendItem(icon: "circle.fill", color: .mdSuccess, label: "Visit")
                LegendItem(icon: "circle.fill", color: .mdAccent, label: "Pain log")
            }

            // Today summary
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1)
                Text("Nothing logged. A quick workout keeps your streak alive.")
                    .font(.system(size: 14)).foregroundColor(.mdMuted)
            }
            .padding(14).background(Color.mdPaper2).cornerRadius(12)
        }
        .mdCardStyle()
    }

    // MARK: - Today Check-In Section
    private var todayCheckInSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TODAY").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Text(Date(), style: .date).font(.system(size: 13)).foregroundColor(.mdMuted)
            }

            // Weight input
            VStack(alignment: .leading, spacing: 8) {
                Text("Weigh-in").font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                HStack {
                    Button { } label: {
                        Image(systemName: "minus").font(.system(size: 16, weight: .bold)).foregroundColor(.mdInk)
                            .frame(width: 44, height: 44).background(Color.mdPaper2).cornerRadius(10)
                    }
                    TextField("—", text: $weightInput)
                        .font(.system(size: 18, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.mdPaper2)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
                    Button { } label: {
                        Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundColor(.mdInk)
                            .frame(width: 44, height: 44).background(Color.mdPaper2).cornerRadius(10)
                    }
                    Text("lb").font(.system(size: 15)).foregroundColor(.mdMuted)
                }
                Text("Optional. Skip it anytime.").font(.system(size: 12)).foregroundColor(.mdMuted)
            }

            // Sleep selector
            VStack(alignment: .leading, spacing: 8) {
                Text("How'd you sleep?").font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                HStack(spacing: 8) {
                    ForEach(sleepOptions, id: \.self) { option in
                        Button {
                            selectedSleep = option
                        } label: {
                            Text(option)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedSleep == option ? .white : .mdInk)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(selectedSleep == option ? Color.mdInk : Color.mdPaper)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
                        }
                    }
                }
            }

            // Done button
            Button { } label: {
                Text("Done").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14).background(Color.mdInk).cornerRadius(10)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Performance Section
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PERFORMANCE").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Menu {
                    Button("Body weight") { }
                    Button("Workouts") { }
                } label: {
                    HStack(spacing: 4) {
                        Text("Body weight · workouts").font(.system(size: 13)).foregroundColor(.mdMuted)
                        Image(systemName: "chevron.down").font(.system(size: 10)).foregroundColor(.mdMuted)
                    }
                }
            }

            // Chart placeholder
            VStack(alignment: .leading, spacing: 8) {
                Text("Body weight").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                Text("— lb").font(.system(size: 13)).foregroundColor(.mdMuted)
                Text("No readings yet").font(.system(size: 12)).foregroundColor(.mdMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .padding(14).background(Color.mdPaper2).cornerRadius(12)

            // Compare workouts
            VStack(alignment: .leading, spacing: 12) {
                Text("Compare workouts").font(.system(size: 16, weight: .bold)).foregroundColor(.mdHeading)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This session").font(.system(size: 12)).foregroundColor(.mdMuted)
                        Menu {
                            Button("11-01 · Full body") { }
                        } label: {
                            HStack {
                                Text("11-01 · Full bo...").font(.system(size: 13, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down").font(.system(size: 10))
                            }
                            .foregroundColor(.mdInk).padding(10)
                            .background(Color.mdPaper2).cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compared with").font(.system(size: 12)).foregroundColor(.mdMuted)
                        Menu {
                            Button("11-04 · Hip mo...") { }
                        } label: {
                            HStack {
                                Text("11-04 · Hip mo...").font(.system(size: 13, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down").font(.system(size: 10))
                            }
                            .foregroundColor(.mdInk).padding(10)
                            .background(Color.mdPaper2).cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                        }
                    }
                }

                // Comparison table
                HStack {
                    Text("").frame(width: 60)
                    Text("11-01").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdHeading).frame(maxWidth: .infinity)
                    Text("11-04").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdHeading).frame(maxWidth: .infinity)
                    Text("Change").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdHeading).frame(maxWidth: .infinity)
                }
                HStack {
                    Text("Time").font(.system(size: 13)).foregroundColor(.mdMuted).frame(width: 60, alignment: .leading)
                    Text("30 min").font(.system(size: 13)).foregroundColor(.mdText).frame(maxWidth: .infinity)
                    Text("15 min").font(.system(size: 13)).foregroundColor(.mdText).frame(maxWidth: .infinity)
                    Text("+900s").font(.system(size: 13, weight: .bold)).foregroundColor(.mdSuccess).frame(maxWidth: .infinity)
                }

                Button { } label: {
                    HStack {
                        Image(systemName: "chevron.right").font(.system(size: 10))
                        Text("Edit this session").font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.mdAccent)
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Pain Tracker Section
    private var painTrackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PAIN TRACKER").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Menu {
                    ForEach(painAreas, id: \.self) { area in
                        Button(area) { selectedPainArea = area }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPainArea).font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .foregroundColor(.mdInk).padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.mdPaper2).cornerRadius(999)
                }
            }

            // Pain chart placeholder
            VStack {
                HStack {
                    Text("5/10").font(.system(size: 24, weight: .bold)).foregroundColor(.mdHeading)
                    Spacer()
                    Text("Nov 4").font(.system(size: 12)).foregroundColor(.mdMuted)
                }
                // Chart would go here
                Rectangle().fill(Color.mdPaper2).frame(height: 80).cornerRadius(8)
            }

            // Pain area selector
            Menu {
                ForEach(painAreas, id: \.self) { area in
                    Button(area) { selectedPainArea = area }
                }
            } label: {
                HStack {
                    Text(selectedPainArea).font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 12))
                }
                .foregroundColor(.mdInk).padding(12)
                .background(Color.mdPaper2).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
            }

            // Pain slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Pain now \(Int(painLevel))/10").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                Slider(value: $painLevel, in: 0...10, step: 1)
                    .tint(.mdAccent)
            }

            // Note input
            TextField("Note (optional)", text: $painNote)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.mdPaper2)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))

            // Log button
            Button { } label: {
                Text("Log it").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 10).background(Color.mdInk).cornerRadius(8)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 10))
                    Text("All entries (3)").font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.mdAccent)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        Button { } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LEADERBOARD").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                    Text("See where you rank today and this month").font(.system(size: 14)).foregroundColor(.mdText)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 14)).foregroundColor(.mdMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .mdCardStyle()
    }

    // MARK: - Badges Section
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BADGES").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Text("4 of 6").font(.system(size: 13)).foregroundColor(.mdMuted)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BadgeCard(icon: "dumbbell.fill", title: "First workout", subtitle: "Earned Nov 4", isEarned: true)
                BadgeCard(icon: "flame.fill", title: "3-day streak", subtitle: "Earned Nov 4", isEarned: true)
                BadgeCard(icon: "figure.walk", title: "Pain logger", subtitle: "Earned Nov 4", isEarned: true)
                BadgeCard(icon: "calendar", title: "First visit", subtitle: "Earned Nov 4", isEarned: true)
                BadgeCard(icon: "star.fill", title: "10 workouts", subtitle: "10 workouts", isEarned: false, progress: 0.3)
                BadgeCard(icon: "flame.fill", title: "30-day streak", subtitle: "30-day streak", isEarned: false, progress: 0.1)
            }
        }
        .mdCardStyle()
    }
}

// MARK: - Supporting Components

struct CalendarGrid: View {
    let days = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack {
                ForEach(days, id: \.self) { day in
                    Text(day).font(.system(size: 12, weight: .semibold)).foregroundColor(.mdMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days (simplified - would need real date logic)
            ForEach(0..<5) { week in
                HStack {
                    ForEach(0..<7) { day in
                        let dayNum = week * 7 + day - 1
                        if dayNum >= 0 && dayNum <= 29 {
                            ProgressCalendarDay(number: dayNum + 1, hasWorkout: [3, 4, 5, 6, 7].contains(dayNum + 1), isToday: dayNum + 1 == 7)
                        } else {
                            Text("").frame(maxWidth: .infinity, minHeight: 36)
                        }
                    }
                }
            }
        }
    }
}

struct ProgressCalendarDay: View {
    let number: Int
    let hasWorkout: Bool
    let isToday: Bool

    var body: some View {
        ZStack {
            if isToday {
                Circle().fill(Color.mdGold).frame(width: 32, height: 32)
            }
            Text("\(number)")
                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : .mdText)
            if hasWorkout && !isToday {
                Circle().fill(Color.mdAccent).frame(width: 6, height: 6).offset(y: 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 36)
    }
}

struct LegendItem: View {
    var icon: String? = nil
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon).font(.system(size: 8)).foregroundColor(color)
            } else {
                Circle().fill(color).frame(width: 10, height: 10)
            }
            Text(label).font(.system(size: 11)).foregroundColor(.mdMuted)
        }
    }
}

struct BadgeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isEarned: Bool
    var progress: Double = 1.0

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.mdGoldSoft : Color.mdPaper2)
                    .frame(width: 56, height: 56)
                if !isEarned {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.mdAccent, lineWidth: 3)
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                }
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isEarned ? .mdGold : .mdMuted)
            }
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.mdHeading)
            Text(subtitle).font(.system(size: 11)).foregroundColor(.mdMuted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color.mdPaper).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
    }
}

// MARK: - Preview

struct ProgressTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressTabView()
    }
}
