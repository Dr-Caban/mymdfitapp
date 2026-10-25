import SwiftUI

struct WorkoutGeneratorView: View {
    @State private var settings = WorkoutGeneratorSettings()
    @State private var showCalendar = false
    @State private var selectedDate = Date()
    @State private var generatedWorkout: Workout?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.mdBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Main content in two columns on iPad, single on iPhone
                        HStack(alignment: .top, spacing: 20) {
                            // Left: Generator options
                            VStack(spacing: 20) {
                                goalTypeSection
                                locationSection
                                difficultySection
                                workoutLengthSection
                                exercisesPerRoundSection
                                roundsSection
                                restBetweenExercisesSection
                                restBetweenRoundsSection
                            }
                            .frame(maxWidth: .infinity)

                            // Right: Summary + Calendar (on larger screens)
                            VStack(spacing: 16) {
                                workoutSummary
                                generateButtons
                                optionalAddOns
                                calendarSection
                            }
                            .frame(width: 280)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("WORKOUT")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("GENERATOR")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.mdGold)
            }

            Text("CUSTOMIZE EVERY DETAIL. CREATE A WORKOUT THAT FITS YOU.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .tracking(1)
        }
        .padding(.top, 20)
    }

    // MARK: - Section 1: Goal Type

    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Workout Goal / Type", number: 1, subtitle: "Choose the primary focus (you can also mix types)")

            HStack(spacing: 8) {
                ForEach(WorkoutGoalType.allCases, id: \.self) { type in
                    GoalTypeCard(
                        type: type,
                        isSelected: settings.goalType == type
                    ) {
                        settings.goalType = type
                    }
                }
            }
        }
    }

    // MARK: - Section 2: Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Location", number: 2, subtitle: "Where will you be working out?")

            HStack(spacing: 8) {
                ForEach(WorkoutLocation.allCases, id: \.self) { location in
                    SelectionChip(
                        title: location.displayName,
                        icon: location.icon,
                        isSelected: settings.location == location
                    ) {
                        settings.location = location
                    }
                }
            }
        }
    }

    // MARK: - Section 3: Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Difficulty Level", number: 3, subtitle: "Match the workout to your current ability")

            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    DifficultyCard(
                        level: level,
                        isSelected: settings.difficulty == level
                    ) {
                        settings.difficulty = level
                    }
                }
            }
        }
    }

    // MARK: - Section 4: Workout Length

    private var workoutLengthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Workout Length", number: 4, subtitle: "Total time for your workout")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WorkoutGeneratorSettings.lengthOptions, id: \.self) { mins in
                        NumberChip(
                            value: mins,
                            label: mins >= 60 ? (mins == 240 ? "4 Hours" : "Min") : "Min",
                            isSelected: settings.lengthMinutes == mins
                        ) {
                            settings.lengthMinutes = mins
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section 5: Exercises Per Round

    private var exercisesPerRoundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Exercises Per Round", number: 5, subtitle: "How many different exercises in each round?")

            HStack(spacing: 6) {
                ForEach(WorkoutGeneratorSettings.exercisesPerRoundOptions, id: \.self) { count in
                    NumberChip(
                        value: count,
                        label: count == 12 ? "+" : nil,
                        isSelected: settings.exercisesPerRound == count
                    ) {
                        settings.exercisesPerRound = count
                    }
                }
            }
        }
    }

    // MARK: - Section 6: Rounds

    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Rounds", number: 6, subtitle: "How many total rounds of the workout?")

            HStack(spacing: 6) {
                ForEach(WorkoutGeneratorSettings.roundOptions, id: \.self) { count in
                    NumberChip(
                        value: count,
                        isSelected: settings.totalRounds == count
                    ) {
                        settings.totalRounds = count
                    }
                }

                Button {
                    // Custom input
                } label: {
                    Text("Custom")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Section 7: Rest Between Exercises

    private var restBetweenExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Rest Between Exercises", number: 7, subtitle: "How much rest between each exercise?")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WorkoutGeneratorSettings.restOptions, id: \.self) { secs in
                        RestChip(
                            seconds: secs,
                            isSelected: settings.restBetweenExercises == secs
                        ) {
                            settings.restBetweenExercises = secs
                        }
                    }

                    Button {
                        // Custom input
                    } label: {
                        Text("Custom")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Section 8: Rest Between Rounds

    private var restBetweenRoundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MDSectionHeader("Rest Between Rounds", number: 8, subtitle: "How much rest between each round?")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(WorkoutGeneratorSettings.restOptions, id: \.self) { secs in
                        RestChip(
                            seconds: secs,
                            isSelected: settings.restBetweenRounds == secs
                        ) {
                            settings.restBetweenRounds = secs
                        }
                    }

                    Button {
                        // Custom input
                    } label: {
                        Text("Custom")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Workout Summary

    private var workoutSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WORKOUT SUMMARY")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .tracking(1)

            VStack(spacing: 8) {
                SummaryRow(icon: "figure.mixed.cardio", label: "Type:", value: settings.goalType.displayName)
                SummaryRow(icon: "house.fill", label: "Location:", value: settings.location.displayName)
                SummaryRow(icon: "chart.bar.fill", label: "Difficulty:", value: settings.difficulty.displayName)
                SummaryRow(icon: "clock.fill", label: "Length:", value: "\(settings.lengthMinutes) Minutes")
                SummaryRow(icon: "list.number", label: "Exercises per Round:", value: "\(settings.exercisesPerRound)")
                SummaryRow(icon: "arrow.clockwise", label: "Total Rounds:", value: "\(settings.totalRounds)")
                SummaryRow(icon: "pause.fill", label: "Rest Between Exercises:", value: formatRest(settings.restBetweenExercises))
                SummaryRow(icon: "pause.circle.fill", label: "Rest Between Rounds:", value: formatRest(settings.restBetweenRounds))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Generate Buttons

    private var generateButtons: some View {
        VStack(spacing: 12) {
            Button {
                generateWorkout()
            } label: {
                HStack {
                    Text("GENERATE WORKOUT")
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "chevron.right")
                }
            }
            .buttonStyle(.mdPrimary)

            Button {
                settings.randomize()
            } label: {
                HStack {
                    Image(systemName: "shuffle")
                    Text("RANDOMIZE SETTINGS")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .buttonStyle(.mdSecondary)
        }
    }

    // MARK: - Optional Add-Ons

    private var optionalAddOns: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OPTIONAL ADD-ONS")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(1)

            Text("Include additional elements in your workout.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            VStack(spacing: 0) {
                MDToggleRow(icon: "flame.fill", title: "Warm-Up", isOn: $settings.addOns.warmUp)
                MDToggleRow(icon: "snowflake", title: "Cool-Down", isOn: $settings.addOns.coolDown)
                MDToggleRow(icon: "figure.flexibility", title: "Mobility / Flexibility", isOn: $settings.addOns.mobilityFlexibility)
                MDToggleRow(icon: "figure.core.training", title: "Core Work", isOn: $settings.addOns.coreWork)
                MDToggleRow(icon: "figure.stand", title: "Balance / Stability", isOn: $settings.addOns.balanceStability)
                MDToggleRow(icon: "sportscourt.fill", title: "Sport Specific", isOn: $settings.addOns.sportSpecific)
                MDToggleRow(icon: "dumbbell.fill", title: "Equipment Restrictions", isOn: $settings.addOns.equipmentRestrictions)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SCHEDULE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)

                Spacer()

                Button {
                    showCalendar.toggle()
                } label: {
                    Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                        .foregroundColor(.mdGold)
                }
            }

            if showCalendar {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.mdGold)
                .colorScheme(.dark)
                .padding(8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            } else {
                Button {
                    showCalendar = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Add to Calendar")
                        Spacer()
                        Image(systemName: "plus")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.mdGold)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    // MARK: - Helpers

    private func formatRest(_ seconds: Int) -> String {
        if seconds == 0 {
            return "None (0 sec)"
        } else if seconds < 60 {
            return "\(seconds) sec"
        } else {
            return "\(seconds / 60) min"
        }
    }

    private func generateWorkout() {
        // TODO: Generate workout from settings
        generatedWorkout = Workout.sample
    }
}

// MARK: - Supporting Views

struct GoalTypeCard: View {
    let type: WorkoutGoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Placeholder for image
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 60)
                    .overlay(
                        Image(systemName: type.icon)
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? .mdGold : .white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.mdGold : Color.clear, lineWidth: 2)
                    )

                Text(type.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)

                if let subtitle = type.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct DifficultyCard: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let action: () -> Void

    var subtitle: String {
        switch level {
        case .beginner: return "Build the foundation"
        case .intermediate: return "Progress and improve"
        case .advanced: return "Challenge yourself"
        case .elite: return "Maximum intensity"
        }
    }

    var icon: String {
        switch level {
        case .beginner: return "chart.bar.fill"
        case .intermediate: return "chart.bar.fill"
        case .advanced: return "chart.bar.fill"
        case .elite: return "chart.bar.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .mdBlueDark : .white)

                Text(level.displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .mdBlueDark : .white)

                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .mdBlueDark.opacity(0.7) : .white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.mdGold : Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.mdGold : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct RestChip: View {
    let seconds: Int
    let isSelected: Bool
    let action: () -> Void

    var label: String {
        if seconds == 0 {
            return "None"
        } else {
            return "\(seconds)"
        }
    }

    var sublabel: String {
        seconds == 0 ? "(0 sec)" : "sec"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                Text(sublabel)
                    .font(.system(size: 9))
            }
            .foregroundColor(isSelected ? .mdBlueDark : .white)
            .frame(width: 50, height: 44)
            .background(isSelected ? Color.mdGold : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mdGold)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    WorkoutGeneratorView()
}
