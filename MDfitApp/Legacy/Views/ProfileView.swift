import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var name: String = "Alex Rivera"
    @State private var email: String = "alex.demo@example.com"
    @State private var phone: String = "941-555-0100"
    @State private var bugReport: String = ""
    @State private var bugDetails: String = ""
    @State private var showFeedbackType: FeedbackType = .bug

    enum FeedbackType: String, CaseIterable {
        case bug = "Report a bug"
        case feature = "Suggest a feature"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        profileHeader
                        VStack(spacing: 16) {
                            Group {
                                appointmentsSection
                                workoutHistorySection
                                profileFormSection
                            }
                            Group {
                                helpImproveSection
                                referFriendSection
                                getAppSection
                                footerSection
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

    // MARK: - Profile Header
    private var profileHeader: some View {
        ZStack {
            Color.mdInk
            RadialGradient(colors: [Color.mdInk3.opacity(0.5), .clear], center: .topTrailing, startRadius: 0, endRadius: 300)
        }
        .frame(height: 160)
        .overlay(
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Circle().fill(Color.mdInk3).frame(width: 56, height: 56)
                        .overlay(Text("A").font(.system(size: 24, weight: .bold)).foregroundColor(.white))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.fullName ?? "Alex Rivera").font(.mdDisplay(22, weight: .bold)).foregroundColor(.white)
                        Text(authService.currentUser?.email ?? "alex.demo@example.com").font(.system(size: 13)).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill").font(.system(size: 12)).foregroundColor(Color(hex: "9b59b6"))
                        Text("Amethyst").font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        Text("320 XP").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8).background(Color.mdInk3).cornerRadius(999)
                    HStack(spacing: 4) {
                        Text("#4").font(.system(size: 14, weight: .bold)).foregroundColor(.mdGold)
                        Text("overall").font(.system(size: 12)).foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8).background(Color.mdInk2).cornerRadius(999)
                    Spacer()
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
        )
    }

    // MARK: - Appointments Section
    private var appointmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MY APPOINTMENTS").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Button { } label: {
                Text("Book an evaluation").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.mdInk).cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Appointment card
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("NOV").font(.system(size: 10, weight: .semibold)).foregroundColor(.mdMuted)
                    Text("10").font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdHeading)
                }
                .frame(width: 50).padding(.vertical, 8).background(Color.mdPaper2).cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text("In-Studio Follow-up / Training Session").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                    Text("Tue · 10:30 AM · 60 min").font(.system(size: 12)).foregroundColor(.mdMuted)
                    Button { } label: {
                        Text("Add to calendar").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdAccentText)
                    }
                }
                Spacer()
                Button { } label: {
                    Text("Cancel").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdErr)
                }
            }
            .padding(14).background(Color.mdPaper).cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    Text("Visit history").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdAccentText)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Workout History Section
    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WORKOUT HISTORY").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            VStack(spacing: 8) {
                WorkoutHistoryRow(icon: "checkmark", title: "Knee strength", subtitle: "22 min · 6 exercises", date: "Yesterday")
                WorkoutHistoryRow(icon: "checkmark", title: "Hip mobility", subtitle: "15 min · 5 exercises", date: "Nov 4")
            }
        }
        .mdCardStyle()
    }

    // MARK: - Profile Form Section
    private var profileFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PROFILE").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.system(size: 12)).foregroundColor(.mdMuted)
                TextField("Name", text: $name).font(.system(size: 15)).foregroundColor(.mdHeading)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Color.mdPaper).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Email").font(.system(size: 12)).foregroundColor(.mdMuted)
                TextField("Email", text: $email).font(.system(size: 15)).foregroundColor(.mdHeading)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Color.mdPaper).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mobile phone").font(.system(size: 12)).foregroundColor(.mdMuted)
                TextField("Phone", text: $phone).font(.system(size: 15)).foregroundColor(.mdHeading)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Color.mdPaper).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            Button { } label: {
                Text("Save").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.mdGold).cornerRadius(8)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    Text("Change password").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdAccentText)
            }

            Divider().padding(.vertical, 8)

            Button {
                Task { await authService.signOut() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right").font(.system(size: 14))
                    Text("Log out").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdErr)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.mdErr.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Help Improve Section
    private var helpImproveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HELP US IMPROVE").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Found a bug? Have an idea for a feature? Dr. Jared reads every one.").font(.system(size: 13)).foregroundColor(.mdMuted)

            HStack(spacing: 8) {
                Button { showFeedbackType = .bug } label: {
                    Text("Report a bug").font(.system(size: 13, weight: showFeedbackType == .bug ? .bold : .medium))
                        .foregroundColor(showFeedbackType == .bug ? .mdInk : .mdMuted)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(showFeedbackType == .bug ? Color.mdPaper2 : Color.clear)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
                Button { showFeedbackType = .feature } label: {
                    Text("Suggest a feature").font(.system(size: 13, weight: showFeedbackType == .feature ? .bold : .medium))
                        .foregroundColor(showFeedbackType == .feature ? .mdInk : .mdMuted)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(showFeedbackType == .feature ? Color.mdPaper2 : Color.clear)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("What went wrong, in one line?").font(.system(size: 12)).foregroundColor(.mdMuted)
                TextField("Brief description", text: $bugReport).font(.system(size: 15)).foregroundColor(.mdHeading)
                    .padding(.horizontal, 14).padding(.vertical, 12).background(Color.mdPaper).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Details (what you did, what happened, what you expected)").font(.system(size: 12)).foregroundColor(.mdMuted)
                TextEditor(text: $bugDetails).font(.system(size: 15)).foregroundColor(.mdHeading).frame(minHeight: 100)
                    .padding(8).background(Color.mdPaper).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            Button { } label: {
                Text("Send").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.mdGold).cornerRadius(8)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    Text("What I've sent (0)").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdAccentText)
            }
        }
        .mdCardStyle()
    }

    // MARK: - Refer a Friend Section
    private var referFriendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REFER A FRIEND").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Share your code — when someone signs up with it, ").font(.system(size: 13)).foregroundColor(.mdMuted) +
            Text("you get 1 free month").font(.system(size: 13, weight: .bold)).foregroundColor(.mdHeading) +
            Text(" of membership credit.").font(.system(size: 13)).foregroundColor(.mdMuted)

            Text("ALEX10").font(.system(size: 20, weight: .bold)).foregroundColor(.mdHeading)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.mdPaper2).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))

            HStack(spacing: 12) {
                Button { } label: {
                    Text("Copy").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.mdPaper).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
                Button { } label: {
                    Text("Share link").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.mdGold).cornerRadius(8)
                }
            }

            Text("No one has used your code yet — share it!").font(.system(size: 12)).foregroundColor(.mdMuted).frame(maxWidth: .infinity, alignment: .center)
        }
        .mdCardStyle()
    }

    // MARK: - Get App Section
    private var getAppSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GET THE APP").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Get MD Fit on your Home Screen. One tap to open, full-screen, no App Store needed.").font(.system(size: 13)).foregroundColor(.mdMuted)
            Button { } label: {
                HStack {
                    Image(systemName: "arrow.down.to.line").font(.system(size: 14, weight: .bold))
                    Text("Install MD Fit").font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.mdInk).frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(Color.mdPaper).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }
        }
        .mdCardStyle()
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                Button { } label: { Text("mymdfit.com").font(.system(size: 13)).foregroundColor(.mdAccentText) }
                Button { } label: { Text("Call 941-313-0562").font(.system(size: 13)).foregroundColor(.mdAccentText) }
                Button { } label: { Text("Privacy").font(.system(size: 13)).foregroundColor(.mdAccentText) }
            }
            HStack(spacing: 20) {
                Button { } label: { Text("Terms").font(.system(size: 13)).foregroundColor(.mdMuted) }
                Button {
                    Task { await authService.signOut() }
                } label: {
                    Text("Log out").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdErr)
                }
            }
            Text("Guides and tracking are educational and don't replace an in-person evaluation. In an emergency, call 911.").font(.system(size: 11)).foregroundColor(.mdMuted).multilineTextAlignment(.center).padding(.top, 8)
        }
        .padding(.top, 16)
    }
}

// MARK: - Workout History Row

struct WorkoutHistoryRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let date: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold)).foregroundColor(.mdSuccess)
                .frame(width: 24, height: 24).background(Color.mdSuccess.opacity(0.15)).clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                Text(subtitle).font(.system(size: 12)).foregroundColor(.mdMuted)
            }
            Spacer()
            Text(date).font(.system(size: 12)).foregroundColor(.mdAccentText)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Legacy Compatibility Views

struct ProfileStatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdGold)
            Text(label).font(.system(size: 11)).foregroundColor(.mdMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileAchievementBadge: View {
    let achievement: Achievement
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(achievement.color.opacity(0.15)).frame(width: 50, height: 50)
                Image(systemName: achievement.icon).font(.system(size: 22)).foregroundColor(achievement.color)
            }
            Text(achievement.title).font(.system(size: 9, weight: .medium)).foregroundColor(.mdHeading).multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(width: 70)
    }
}

struct ProfileMenuRow: View {
    let icon: String
    let title: String
    var showDivider: Bool = true
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(.mdAccentText).frame(width: 24)
                Text(title).font(.system(size: 15)).foregroundColor(.mdHeading)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundColor(.mdMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            if showDivider { Rectangle().fill(Color.mdLine).frame(height: 1).padding(.leading, 52) }
        }
    }
}

struct AchievementsView: View {
    @StateObject private var streakService = StreakService.shared
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("\(streakService.achievements.count)").font(.mdDisplay(48, weight: .bold)).foregroundColor(.mdGold)
                            Text("of \(Achievement.allCases.count) achievements earned").font(.system(size: 14)).foregroundColor(.mdMuted)
                        }
                        .padding(.top, 20)
                        achievementSection(title: "Streaks", achievements: [.streak3, .streak7, .streak14, .streak30, .streak100])
                        achievementSection(title: "Workouts", achievements: [.firstWorkout, .workouts10, .workouts50, .workouts100])
                        achievementSection(title: "Time Spent", achievements: [.hour1, .hours10, .hours50])
                        achievementSection(title: "Special", achievements: [.perfectWeek, .earlyBird, .nightOwl, .painWarrior])
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
        }
    }

    private func achievementSection(title: String, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased()).font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(achievements, id: \.self) { achievement in
                    AchievementCard(achievement: achievement, isEarned: streakService.achievements.contains(achievement))
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isEarned: Bool
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(isEarned ? achievement.color.opacity(0.15) : Color.mdLine.opacity(0.5)).frame(width: 60, height: 60)
                Image(systemName: achievement.icon).font(.system(size: 26)).foregroundColor(isEarned ? achievement.color : .mdMuted.opacity(0.5))
            }
            VStack(spacing: 2) {
                Text(achievement.title).font(.system(size: 11, weight: .semibold)).foregroundColor(isEarned ? .mdHeading : .mdMuted).multilineTextAlignment(.center)
                Text(achievement.description).font(.system(size: 9)).foregroundColor(.mdMuted).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.mdPaper).cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.mdLine, lineWidth: 1)).opacity(isEarned ? 1 : 0.6)
    }
}

struct DarkStatItem: View { let value: String; let label: String; let color: Color; var body: some View { ProfileStatItem(value: value, label: label) } }
struct DarkAchievementBadge: View { let achievement: Achievement; var body: some View { ProfileAchievementBadge(achievement: achievement) } }
struct DarkMenuRow: View { let icon: String; let title: String; var showDivider: Bool = true; var body: some View { ProfileMenuRow(icon: icon, title: title, showDivider: showDivider) } }
struct DarkAchievementCard: View { let achievement: Achievement; let isEarned: Bool; var body: some View { AchievementCard(achievement: achievement, isEarned: isEarned) } }
struct StatItem: View { let value: String; let label: String; var body: some View { ProfileStatItem(value: value, label: label) } }
struct AchievementBadge: View { let achievement: Achievement; var body: some View { ProfileAchievementBadge(achievement: achievement) } }

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView().environmentObject(AuthService())
    }
}
