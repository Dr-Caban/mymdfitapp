import SwiftUI

struct WorkoutGeneratorView: View {
    @State private var settings = WorkoutGeneratorSettings()
    @State private var showHowItWorks = false
    @State private var generatedWorkout: Workout?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        VStack(spacing: 16) {
                            Group {
                                freeAccountBanner
                                howItWorksSection
                                myWorkoutsSection
                                myProgramsSection
                            }
                            Group {
                                sessionTypeSection
                                focusAreaSection
                                locationSection
                                difficultySection
                            }
                            Group {
                                workoutLengthSection
                                exercisesPerRoundSection
                                roundsSection
                                restBetweenSection
                            }
                            Group {
                                optionalAddOnsSection
                                workoutSummary
                                generateButtons
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

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack {
            Color.mdInk
            RadialGradient(colors: [Color.mdInk3.opacity(0.5), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
        }
        .frame(height: 120)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    Text("Workout ").font(.mdDisplay(30, weight: .bold)).foregroundColor(.white)
                    Text("Generator").font(.mdDisplay(30, weight: .bold)).italic().foregroundColor(.mdGold)
                }
                Text("CUSTOMIZE EVERY DETAIL. CREATE A WORKOUT THAT FITS YOU.").font(.system(size: 11, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(1.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
        )
    }

    // MARK: - Free Account Banner
    private var freeAccountBanner: some View {
        HStack(spacing: 8) {
            Text("Free account").font(.system(size: 13)).foregroundColor(.mdMuted)
            Text("Unlock unlimited workouts").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdAccentText)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
        .background(Color.mdPaper).cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
    }

    // MARK: - How It Works
    private var howItWorksSection: some View {
        Button { showHowItWorks.toggle() } label: {
            HStack {
                Image(systemName: showHowItWorks ? "chevron.down" : "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdInk)
                Text("How it works with Dr. Jared").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdInk)
                Spacer()
            }
            .padding(14).background(Color.mdPaper).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
        }
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
            Text("Pick exercises from Dr. Jared's library, set your sets and reps, and save it. Doing your own workout is worth 35 XP (30 + 5), and you can send it to another member as a challenge.").font(.system(size: 13)).foregroundColor(.mdMuted)
        }
        .mdCardStyle()
    }

    // MARK: - My Programs Section
    private var myProgramsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MY PROGRAMS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                Spacer()
                Text("1 saved").font(.system(size: 12)).foregroundColor(.mdMuted)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("🦵").font(.system(size: 20))
                        Text("Knee & Hip Strength").font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                    }
                    Text("Strength · 3 × 3 rounds · about 25 min").font(.system(size: 12)).foregroundColor(.mdMuted)
                }
                Spacer()
                Button { } label: {
                    Text("Start").font(.system(size: 13, weight: .bold)).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8).background(Color.mdInk).cornerRadius(999)
                }
                Button { } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.mdMuted)
                }
            }
            .padding(14).background(Color.mdPaper2).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
        }
        .mdCardStyle()
    }

    // MARK: - Step 1: Session Type
    private var sessionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "1", title: "SESSION TYPE", subtitle: "Rehab sessions use only Dr. Jared's corrective movements, kept gentle. Workouts train strength and conditioning.")
            HStack(spacing: 10) {
                SessionTypeCard(icon: "figure.strengthtraining.traditional", title: "Workout", subtitle: "Strength, power and conditioning.", isSelected: settings.sessionType == .workout) { settings.sessionType = .workout }
                SessionTypeCard(icon: "figure.walk", title: "Rehab session", subtitle: "Corrective work for pain and recovery.", isSelected: settings.sessionType == .rehab) { settings.sessionType = .rehab }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 2: Focus Area
    private var focusAreaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "2", title: "FOCUS AREA", subtitle: "Choose the primary focus.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                FocusAreaCard(icon: "figure.arms.open", title: "Upper Body", isSelected: settings.goalType == .upperBody) { settings.goalType = .upperBody }
                FocusAreaCard(icon: "figure.walk", title: "Lower Body", isSelected: settings.goalType == .lowerBody) { settings.goalType = .lowerBody }
                FocusAreaCard(icon: "figure.mixed.cardio", title: "Full Body", isSelected: settings.goalType == .fullBody) { settings.goalType = .fullBody }
                FocusAreaCard(icon: "figure.core.training", title: "Core & Spine", isSelected: settings.goalType == .core) { settings.goalType = .core }
                FocusAreaCard(icon: "figure.flexibility", title: "Mobility & Recovery", isSelected: settings.goalType == .mobility) { settings.goalType = .mobility }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 3: Location
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "3", title: "LOCATION", subtitle: "Where will you be working out?")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                LocationCard(icon: "house.fill", title: "Home", isSelected: settings.location == .home) { settings.location = .home }
                LocationCard(icon: "dumbbell.fill", title: "Gym", isSelected: settings.location == .gym) { settings.location = .gym }
                LocationCard(icon: "sun.max.fill", title: "Outdoor", isSelected: settings.location == .outdoor) { settings.location = .outdoor }
                LocationCard(icon: "desktopcomputer", title: "Office / Desk", isSelected: settings.location == .office) { settings.location = .office }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 4: Difficulty
    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "4", title: "DIFFICULTY LEVEL", subtitle: "Match the workout to your current ability.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                DifficultyCard(icon: "figure.stand", title: "Beginner", subtitle: "Build the foundation.", isSelected: settings.difficulty == .beginner) { settings.difficulty = .beginner }
                DifficultyCard(icon: "figure.walk", title: "Intermediate", subtitle: "Progress and improve.", isSelected: settings.difficulty == .intermediate) { settings.difficulty = .intermediate }
                DifficultyCard(icon: "figure.run", title: "Advanced", subtitle: "Challenge yourself.", isSelected: settings.difficulty == .advanced) { settings.difficulty = .advanced }
                DifficultyCard(icon: "bolt.fill", title: "Elite", subtitle: "Maximum intensity.", isSelected: settings.difficulty == .elite) { settings.difficulty = .elite }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 5: Workout Length
    private var workoutLengthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "5", title: "WORKOUT LENGTH", subtitle: "Sets exercises, rounds and rest to fit. Fine-tune below.")
            HStack(spacing: 8) {
                ForEach([10, 15, 20, 30, 45, 60], id: \.self) { minutes in
                    Button { settings.lengthMinutes = minutes } label: {
                        VStack(spacing: 2) {
                            Text("\(minutes)").font(.system(size: 16, weight: .bold)).foregroundColor(settings.lengthMinutes == minutes ? .white : .mdInk)
                            Text("min").font(.system(size: 10)).foregroundColor(settings.lengthMinutes == minutes ? .white.opacity(0.7) : .mdMuted)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(settings.lengthMinutes == minutes ? Color.mdInk : Color.mdPaper)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(settings.lengthMinutes == minutes ? Color.mdInk : Color.mdLine, lineWidth: 1))
                    }
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 6: Exercises Per Round
    private var exercisesPerRoundSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "6", title: "EXERCISES PER ROUND", subtitle: "How many different exercises in each round?")
            HStack(spacing: 8) {
                ForEach([2, 3, 4, 5, 6, 8, 10], id: \.self) { num in
                    Button { settings.exercisesPerRound = num } label: {
                        Text("\(num)").font(.system(size: 16, weight: .bold)).foregroundColor(settings.exercisesPerRound == num ? .white : .mdInk)
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(settings.exercisesPerRound == num ? Color.mdInk : Color.mdPaper)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(settings.exercisesPerRound == num ? Color.mdInk : Color.mdLine, lineWidth: 1))
                    }
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 7: Rounds
    private var roundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "7", title: "ROUNDS", subtitle: "How many total rounds? Pick 1 for one long round with high reps on every movement (reps scale with your level).")
            HStack(spacing: 8) {
                ForEach([1, 2, 3, 4, 5, 6, 8, 10], id: \.self) { num in
                    Button { settings.totalRounds = num } label: {
                        VStack(spacing: 2) {
                            Text("\(num)").font(.system(size: 16, weight: .bold)).foregroundColor(settings.totalRounds == num ? .white : .mdInk)
                            if num == 1 { Text("high reps").font(.system(size: 8)).foregroundColor(settings.totalRounds == num ? .white.opacity(0.7) : .mdMuted) }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(settings.totalRounds == num ? Color.mdInk : Color.mdPaper)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(settings.totalRounds == num ? Color.mdInk : Color.mdLine, lineWidth: 1))
                    }
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Step 8: Rest Between Exercises
    private var restBetweenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeneratorStepHeader(number: "8", title: "REST BETWEEN EXERCISES", subtitle: "None by default. Add rest if you need it.")
            HStack(spacing: 8) {
                ForEach(["None", "15", "20", "30", "45", "60", "90"], id: \.self) { rest in
                    Button {
                        settings.restBetweenExercises = rest == "None" ? 0 : (Int(rest) ?? 0)
                    } label: {
                        VStack(spacing: 2) {
                            Text(rest).font(.system(size: rest == "None" ? 12 : 16, weight: .bold)).foregroundColor(isRestSelected(rest) ? .white : .mdInk)
                            if rest != "None" { Text("sec").font(.system(size: 10)).foregroundColor(isRestSelected(rest) ? .white.opacity(0.7) : .mdMuted) }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(isRestSelected(rest) ? Color.mdInk : Color.mdPaper)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(isRestSelected(rest) ? Color.mdInk : Color.mdLine, lineWidth: 1))
                    }
                }
            }
        }
        .mdCardStyle()
    }

    private func isRestSelected(_ rest: String) -> Bool {
        if rest == "None" { return settings.restBetweenExercises == 0 }
        return settings.restBetweenExercises == (Int(rest) ?? 0)
    }

    // MARK: - Optional Add-Ons
    private var optionalAddOnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OPTIONAL ADD-ONS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Include extra elements in your workout.").font(.system(size: 13)).foregroundColor(.mdMuted)
            VStack(spacing: 0) {
                AddOnToggleRow(title: "Mobility / flexibility", isOn: $settings.addOns.mobilityFlexibility)
                AddOnToggleRow(title: "Core work", isOn: $settings.addOns.coreWork)
                AddOnToggleRow(title: "Balance / stability", isOn: $settings.addOns.balanceStability)
                AddOnToggleRow(title: "Sport specific (power)", isOn: $settings.addOns.sportSpecific)
                AddOnToggleRow(title: "No equipment", isOn: $settings.addOns.noEquipment, showDivider: false)
            }
            .background(Color.mdPaper2).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
        }
        .mdCardStyle()
    }

    // MARK: - Workout Summary
    private var workoutSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text").font(.system(size: 14)).foregroundColor(.mdInk)
                Text("WORKOUT SUMMARY").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            }
            VStack(spacing: 8) {
                SummaryLine(label: "Type", value: settings.sessionType.displayName)
                SummaryLine(label: "Location", value: settings.location.displayName)
                SummaryLine(label: "Difficulty", value: settings.difficulty.displayName)
                SummaryLine(label: "Estimated time", value: "\(settings.lengthMinutes) min")
                SummaryLine(label: "Exercises per round", value: "\(settings.exercisesPerRound)")
                SummaryLine(label: "Total rounds", value: "\(settings.totalRounds)")
                SummaryLine(label: "Rest between exercises", value: settings.restBetweenExercises == 0 ? "None" : "\(settings.restBetweenExercises)s")
            }
        }
        .mdCardStyle()
    }

    // MARK: - Generate Buttons
    private var generateButtons: some View {
        VStack(spacing: 12) {
            Button { generateWorkout() } label: {
                Text("GENERATE WORKOUT").font(.system(size: 16, weight: .bold)).foregroundColor(.white).tracking(1)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.mdInk).cornerRadius(12)
            }
            Button { settings.randomize() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("RANDOMIZE SETTINGS").font(.system(size: 14, weight: .bold)).tracking(0.5)
                }
                .foregroundColor(.mdInk).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.mdPaper).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
            }
        }
    }

    private func generateWorkout() { generatedWorkout = Workout.sample }
}

// MARK: - Supporting Components

struct GeneratorStepHeader: View {
    let number: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(width: 28, height: 28).background(Color.mdInk).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.mdHeading).tracking(1)
                Text(subtitle).font(.system(size: 13)).foregroundColor(.mdMuted).lineLimit(3)
            }
        }
    }
}

struct SessionTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 28)).foregroundColor(isSelected ? .mdGold : .white)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(isSelected ? .mdGold : .white)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.white.opacity(0.6)).multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 8)
            .background(Color.mdInk).cornerRadius(14)
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14).stroke(Color.mdGold, lineWidth: 2)
                        VStack { HStack { Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 20)).foregroundColor(.mdGold).background(Circle().fill(Color.white).padding(4)).offset(x: 8, y: -8) }; Spacer() }
                    }
                }
            )
        }
    }
}

struct FocusAreaCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(isSelected ? .mdGold : .mdInk)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(isSelected ? .mdGold : .mdHeading).lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(isSelected ? Color.mdGoldSoft : Color.mdPaper).cornerRadius(12)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.mdGold : Color.mdLine, lineWidth: isSelected ? 2 : 1)
                    if isSelected { VStack { HStack { Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(.mdGold).background(Circle().fill(Color.white).padding(2)).offset(x: 6, y: -6) }; Spacer() } }
                }
            )
        }
    }
}

struct LocationCard: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 22)).foregroundColor(isSelected ? .mdGold : .mdInk)
                Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(isSelected ? .mdGold : .mdHeading).lineLimit(2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(isSelected ? Color.mdGoldSoft : Color.mdPaper).cornerRadius(12)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.mdGold : Color.mdLine, lineWidth: isSelected ? 2 : 1)
                    if isSelected { VStack { HStack { Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(.mdGold).background(Circle().fill(Color.white).padding(2)).offset(x: 6, y: -6) }; Spacer() } }
                }
            )
        }
    }
}

struct DifficultyCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(isSelected ? .mdGold : .mdInk)
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundColor(isSelected ? .mdGold : .mdHeading)
                Text(subtitle).font(.system(size: 10)).foregroundColor(.mdMuted).lineLimit(2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isSelected ? Color.mdGoldSoft : Color.mdPaper).cornerRadius(12)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.mdGold : Color.mdLine, lineWidth: isSelected ? 2 : 1)
                    if isSelected { VStack { HStack { Spacer(); Image(systemName: "checkmark.circle.fill").font(.system(size: 16)).foregroundColor(.mdGold).background(Circle().fill(Color.white).padding(2)).offset(x: 6, y: -6) }; Spacer() } }
                }
            )
        }
    }
}

struct AddOnToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.system(size: 14)).foregroundColor(.mdHeading)
                Spacer()
                Toggle("", isOn: $isOn).labelsHidden().tint(.mdAccent)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            if showDivider { Divider() }
        }
    }
}

struct SummaryLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.mdMuted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(.mdHeading)
        }
    }
}

// MARK: - Preview

struct WorkoutGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutGeneratorView()
    }
}
