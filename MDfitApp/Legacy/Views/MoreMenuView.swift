import SwiftUI

struct MoreMenuView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showPrograms = false
    @State private var showLectures = false
    @State private var showLeaderboard = false
    @State private var showMembership = false
    @State private var showMessages = false
    @State private var showHealthTips = false
    @State private var bugReport = ""
    @State private var bugDetails = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.mdCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            Text("More").font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdHeading)
                            Spacer()
                            Button { dismiss() } label: {
                                Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundColor(.mdInk)
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 20)

                        // Menu items
                        VStack(spacing: 0) {
                            MenuRow(icon: "figure.walk", title: "Pain Tool", destination: { AnyView(PainToolView()) })
                            MenuRow(icon: "play.rectangle.fill", title: "Video Library", destination: { AnyView(VideoLibraryView()) })
                            MenuRow(icon: "calendar.badge.plus", title: "Book an appointment", destination: { AnyView(BookingView()) })
                        }
                        .background(Color.mdPaper).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
                        .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            MenuRow(icon: "checkmark.square.fill", title: "Programs", destination: { AnyView(ProgramsListView()) })
                            MenuRow(icon: "video.fill", title: "Lectures & Live Q&A", destination: { AnyView(LecturesView()) })
                            MenuRow(icon: "trophy.fill", title: "Leaderboard", destination: { AnyView(LeaderboardView()) })
                            MenuRow(icon: "creditcard.fill", title: "Membership & 1-on-1", destination: { AnyView(MembershipView()) })
                            MenuRow(icon: "bubble.left.fill", title: "Message Dr. Jared", destination: { AnyView(MessengerView()) })
                            MenuRow(icon: "lightbulb.fill", title: "Health Tips", destination: { AnyView(HealthTipsView()) })
                        }
                        .background(Color.mdPaper).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
                        .padding(.horizontal, 16)

                        // Profile section
                        profileSection

                        // Help us improve
                        helpSection

                        // Refer a friend
                        referSection

                        // Get the app
                        getAppSection

                        // Footer links
                        footerSection

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PROFILE").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)

            VStack(alignment: .leading, spacing: 12) {
                ProfileField(label: "Name", value: authService.currentUser?.firstName ?? "Alex Rivera")
                ProfileField(label: "Email", value: authService.currentUser?.email ?? "alex.demo@example.com")
                ProfileField(label: "Mobile phone", value: "941-555-0100")
            }

            Button { } label: {
                Text("Save").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.mdInk).cornerRadius(8)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 10))
                    Text("Change password").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdAccent)
            }
        }
        .mdCardStyle()
        .padding(.horizontal, 16)
    }

    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HELP US IMPROVE").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Found a bug? Have an idea for a feature? Dr. Jared reads every one.").font(.system(size: 14)).foregroundColor(.mdMuted)

            HStack(spacing: 10) {
                Button { } label: {
                    Text("Report a bug").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdInk)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.mdPaper2).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
                Button { } label: {
                    Text("Suggest a feature").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdInk)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.mdPaper2).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What went wrong, in one line?").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                TextField("", text: $bugReport)
                    .padding(12).background(Color.mdPaper2).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Details (what you did, what happened, what you expected)").font(.system(size: 14, weight: .semibold)).foregroundColor(.mdHeading)
                TextEditor(text: $bugDetails)
                    .frame(minHeight: 100)
                    .padding(8).background(Color.mdPaper2).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
            }

            Button { } label: {
                Text("Send").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.mdInk).cornerRadius(8)
            }

            Button { } label: {
                HStack {
                    Image(systemName: "chevron.right").font(.system(size: 10))
                    Text("What I've sent (0)").font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mdAccent)
            }
        }
        .mdCardStyle()
        .padding(.horizontal, 16)
    }

    private var referSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("REFER A FRIEND").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
            Text("Share your code — when someone signs up with it, **you get 1 free month** of membership credit.")
                .font(.system(size: 14)).foregroundColor(.mdMuted)

            Text("ALEX10").font(.mdDisplay(24, weight: .bold)).foregroundColor(.mdHeading)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(Color.mdPaper2).cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))

            HStack(spacing: 12) {
                Button { } label: {
                    Text("Copy").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.mdPaper2).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
                }
                Button { } label: {
                    Text("Share link").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.mdInk).cornerRadius(8)
                }
            }

            Text("No one has used your code yet — share it!").font(.system(size: 13)).foregroundColor(.mdMuted)
        }
        .mdCardStyle()
        .padding(.horizontal, 16)
    }

    private var getAppSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GET THE APP").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                .padding(.horizontal, 20)
            Text("Get MD Fit on your Home Screen. One tap to open, full-screen, no App Store needed.")
                .font(.system(size: 14)).foregroundColor(.mdMuted)
                .padding(.horizontal, 20)

            Button { } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 18))
                    Text("Install MD Fit").font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.mdInk).cornerRadius(10)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color.mdGoldSoft).cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var footerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Link("mymdfit.com", destination: URL(string: "https://mymdfit.com")!)
                    .font(.system(size: 13)).foregroundColor(.mdAccent)
                Link("Call 941-313-0562", destination: URL(string: "tel:9413130562")!)
                    .font(.system(size: 13)).foregroundColor(.mdAccent)
                Link("Privacy", destination: URL(string: "https://mymdfit.com/privacy")!)
                    .font(.system(size: 13)).foregroundColor(.mdAccent)
            }

            HStack(spacing: 16) {
                Link("Terms", destination: URL(string: "https://mymdfit.com/terms")!)
                    .font(.system(size: 13)).foregroundColor(.mdAccent)
                Button {
                    Task { await authService.signOut() }
                } label: {
                    Text("Log out").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdErr)
                }
            }

            Text("Guides and tracking are educational and don't replace an in-person evaluation. In an emergency, call 911.")
                .font(.system(size: 11)).foregroundColor(.mdMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
}

// MARK: - Menu Row

struct MenuRow<Destination: View>: View {
    let icon: String
    let title: String
    let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.mdInk).frame(width: 24)
                Text(title).font(.system(size: 15)).foregroundColor(.mdHeading)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.mdMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        Divider().padding(.leading, 54)
    }
}

struct ProfileField: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 12)).foregroundColor(.mdMuted)
            Text(value).font(.system(size: 15)).foregroundColor(.mdHeading)
                .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                .background(Color.mdPaper2).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mdLine, lineWidth: 1))
        }
    }
}

// MARK: - Sub-Views (Placeholders)

struct BookingView: View {
    var body: some View {
        Text("Book an Appointment").navigationTitle("Booking")
    }
}

struct ProgramsListView: View {
    let categories = ["All", "Rehab Protocols", "Sport Performance", "Mobility", "Strength"]
    @State private var selectedCategory = "All"

    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    ZStack {
                        Color.mdInk
                    }
                    .frame(height: 100)
                    .overlay(
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text("Premade ").font(.mdDisplay(26, weight: .bold)).foregroundColor(.white)
                                Text("Programs").font(.mdDisplay(26, weight: .bold)).italic().foregroundColor(.mdGold)
                            }
                            Text("MULTI-WEEK PLANS FROM DR. JARED. SAME SESSIONS EACH WEEK SO YOU CAN SEE YOUR PROGRESS.")
                                .font(.system(size: 9, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(0.5)
                        }
                        .padding(.horizontal, 20), alignment: .bottomLeading
                    )

                    // Category filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    Text(cat).font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedCategory == cat ? .white : .mdInk)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.mdInk : Color.mdPaper)
                                        .cornerRadius(999)
                                        .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.mdLine, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Program cards
                    VStack(spacing: 16) {
                        ProgramCard(category: "REHAB PROTOCOLS", title: "Low Back Reset", weeks: 6, level: "Beginner", description: "Calm the back down, then build it up.")
                        ProgramCard(category: "REHAB PROTOCOLS", title: "Shoulder Rebuild", weeks: 6, level: "Beginner", description: "Rotator cuff strength and range.")
                        ProgramCard(category: "MOBILITY", title: "Mobility Ladder", weeks: 4, level: "All levels", description: "Daily mobility you can do anywhere.")
                        ProgramCard(category: "STRENGTH", title: "Hypertrophy Block", weeks: 8, level: "Intermediate", description: "Build muscle with smart volume.")
                        ProgramCard(category: "REHAB PROTOCOLS", title: "Hip Strength", weeks: 6, level: "Beginner", description: "Glutes and lateral hip.")
                        ProgramCard(category: "SPORT PERFORMANCE", title: "Golf Performance", weeks: 8, level: "Intermediate", description: "Rotation, hips and power.")
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProgramCard: View {
    let category: String
    let title: String
    let weeks: Int
    let level: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                Color.mdInk
                RadialGradient(colors: [Color.mdAccent.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 150)
                VStack(spacing: 4) {
                    Text("MD FIT · \(category)").font(.system(size: 9, weight: .bold)).foregroundColor(.mdOnNavy).tracking(1)
                    Text(title).font(.mdDisplay(22, weight: .bold)).foregroundColor(.white)
                    Text("\(weeks)-WEEK PROGRAM").font(.system(size: 10, weight: .bold)).foregroundColor(.mdGold).tracking(1)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Color.mdInk2).cornerRadius(999)
                }
            }
            .frame(height: 150).cornerRadius(12)

            Text(description).font(.system(size: 14)).foregroundColor(.mdMuted)
            Text("\(weeks) weeks · 0 days/week · \(level)").font(.system(size: 12)).foregroundColor(.mdAccentText)
        }
        .padding(16).background(Color.mdPaper).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mdLine, lineWidth: 1))
    }
}

struct LecturesView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    ZStack { Color.mdInk }
                        .frame(height: 100)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    Text("Learn & ").font(.mdDisplay(26, weight: .bold)).foregroundColor(.white)
                                    Text("Live").font(.mdDisplay(26, weight: .bold)).italic().foregroundColor(.mdGold)
                                }
                                Text("LECTURES ON HEALTH, WELLNESS, HORMONES AND INFLAMMATION, PLUS A MONTHLY LIVE Q&A WITH DR. JARED.")
                                    .font(.system(size: 9, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(0.5)
                            }
                            .padding(.horizontal, 20), alignment: .bottomLeading
                        )

                    // Monthly Q&A card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "video.fill").foregroundColor(.mdGold)
                            Text("MONTHLY LIVE Q&A").font(.system(size: 11, weight: .bold)).foregroundColor(.mdGold).tracking(1)
                        }
                        Text("Monthly live Q&A").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        Text("Next date coming soon").font(.system(size: 14)).foregroundColor(.white.opacity(0.7)).italic()
                        Text("LIVE").font(.system(size: 11, weight: .bold)).foregroundColor(.mdAccent)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.mdAccent, lineWidth: 1))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .background(Color.mdInk).cornerRadius(16)
                    .padding(.horizontal, 16)

                    // Lectures section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LECTURES").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)
                        Text("All").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8).background(Color.mdInk).cornerRadius(999)

                        Text("DR. JARED'S PAIN GUIDES").font(.system(size: 11, weight: .bold)).foregroundColor(.mdAccentText).tracking(1)
                            .padding(.top, 12)

                        // Protocol guides list
                        ForEach(["The Posterior Neck Power Grid", "The Scalenes & Intercostals", "The Rotator Cuff", "The Iliopsoas Complex", "Lateral Hip Powerhouse"], id: \.self) { title in
                            LectureRow(title: title)
                        }
                    }
                    .padding(16)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LectureRow: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROTOCOL GUIDE").font(.system(size: 10, weight: .bold)).foregroundColor(.mdAccentText).tracking(1)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
            Button { } label: {
                Text("Open guide ›").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdAccent)
            }
        }
        .padding(14).background(Color.mdPaper).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mdLine, lineWidth: 1))
    }
}

struct LeaderboardView: View {
    @State private var selectedTime = "Today"
    @State private var selectedLeague = "Pro League"
    let times = ["Today", "This month", "This week", "All time"]
    let leagues = ["Pro League", "Olympic League", "Overall"]

    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    ZStack { Color.mdInk }
                        .frame(height: 140)
                        .overlay(
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 0) {
                                    Text("Leader").font(.mdDisplay(30, weight: .bold)).foregroundColor(.white)
                                    Text("board").font(.mdDisplay(30, weight: .bold)).italic().foregroundColor(.mdGold)
                                }
                                Text("EARN XP FOR WORKOUTS, DAILY ACTIVITIES, CHALLENGES, CHECK-INS AND VISITS. TODAY'S BOARD RESETS AT MIDNIGHT, THE MONTHLY BOARD ON THE 1ST.")
                                    .font(.system(size: 9, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(0.5)
                            }
                            .padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
                        )

                    VStack(alignment: .leading, spacing: 16) {
                        Text("LEADERBOARD").font(.system(size: 12, weight: .bold)).foregroundColor(.mdAccentText).tracking(1.5)

                        // Time selector
                        HStack(spacing: 0) {
                            ForEach(times, id: \.self) { time in
                                Button {
                                    selectedTime = time
                                } label: {
                                    Text(time).font(.system(size: 13, weight: selectedTime == time ? .bold : .regular))
                                        .foregroundColor(selectedTime == time ? .white : .mdMuted)
                                        .padding(.horizontal, 12).padding(.vertical, 10)
                                        .background(selectedTime == time ? Color.mdInk : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .background(Color.mdPaper2).cornerRadius(10)

                        // League selector
                        HStack(spacing: 8) {
                            ForEach(leagues, id: \.self) { league in
                                Button {
                                    selectedLeague = league
                                } label: {
                                    HStack(spacing: 6) {
                                        if league == "Pro League" {
                                            Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(.orange)
                                        } else if league == "Olympic League" {
                                            Image(systemName: "crown.fill").font(.system(size: 12)).foregroundColor(.mdGold)
                                        } else {
                                            Image(systemName: "globe").font(.system(size: 12)).foregroundColor(.mdAccent)
                                        }
                                        Text(league).font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(selectedLeague == league ? .white : .mdInk)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .background(selectedLeague == league ? Color.mdInk : Color.mdPaper)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
                                }
                            }
                        }

                        Text("Resets at midnight · everyone starts from zero").font(.system(size: 13, weight: .semibold)).foregroundColor(.mdHeading)
                        Text("You're in the Pro League. Reach level undefined to move up to the Olympic League.")
                            .font(.system(size: 13)).foregroundColor(.mdMuted)

                        // Rankings
                        VStack(spacing: 0) {
                            LeaderboardRow(rank: 1, name: "Sam K.", gem: "Amethyst", xp: 120, medal: "gold")
                            LeaderboardRow(rank: 2, name: "Jordan P.", gem: "Amethyst", xp: 95, medal: "silver")
                            LeaderboardRow(rank: 3, name: "Taylor M.", gem: "Amethyst", xp: 60, medal: "bronze")
                            LeaderboardRow(rank: 4, name: "Alex Rivera (you)", gem: "Amethyst", xp: 35, isCurrentUser: true)
                            LeaderboardRow(rank: 5, name: "Chris L.", gem: "Amethyst", xp: 20)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "square").font(.system(size: 16)).foregroundColor(.mdLine)
                            Text("Hide me from the leaderboard").font(.system(size: 14)).foregroundColor(.mdText)
                        }
                    }
                    .mdCardStyle()
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let gem: String
    let xp: Int
    var medal: String? = nil
    var isCurrentUser: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if let medal = medal {
                ZStack {
                    Image(systemName: "medal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(medal == "gold" ? .orange : medal == "silver" ? .gray : Color(hex: "cd7f32"))
                    Text("\(rank)").font(.system(size: 8, weight: .bold)).foregroundColor(.white).offset(y: 2)
                }
                .frame(width: 30)
            } else {
                Text("\(rank)").font(.system(size: 16, weight: .semibold)).foregroundColor(.mdMuted).frame(width: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .semibold)).foregroundColor(.mdHeading)
                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill").font(.system(size: 10)).foregroundColor(Color(hex: "9b59b6"))
                    Text(gem).font(.system(size: 12)).foregroundColor(.mdMuted)
                }
            }

            Spacer()

            Text("\(xp)").font(.system(size: 18, weight: .bold)).foregroundColor(.mdHeading)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(isCurrentUser ? Color.mdGoldSoft : Color.clear)
        .cornerRadius(isCurrentUser ? 10 : 0)
    }
}

struct MembershipView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Hero
                    ZStack { Color.mdInk }
                        .frame(height: 140)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 0) {
                                    Text("Membership & ").font(.mdDisplay(26, weight: .bold)).foregroundColor(.white)
                                    Text("1-on-1").font(.mdDisplay(26, weight: .bold)).italic().foregroundColor(.mdGold)
                                }
                                Text("UNLOCK EVERY PROGRAM, THE LECTURE LIBRARY AND LIVE Q&A, OR WORK WITH DR. JARED DIRECTLY.")
                                    .font(.system(size: 9, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(0.5)
                            }
                            .padding(.horizontal, 20).padding(.bottom, 16), alignment: .bottomLeading
                        )

                    Text("Pick a membership below and tap **Request**. Dr. Jared confirms it and sends payment details.")
                        .font(.system(size: 14)).foregroundColor(.mdText)
                        .padding(.horizontal, 20)

                    // Member tier
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Member").font(.mdDisplay(22, weight: .bold)).foregroundColor(.mdHeading)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$49").font(.mdDisplay(32, weight: .bold)).foregroundColor(.mdHeading)
                            Text("/month").font(.system(size: 16)).foregroundColor(.mdMuted)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "All programs")
                            BulletPoint(text: "Lectures")
                        }
                        Button { } label: {
                            Text("Request Member").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                                .padding(.horizontal, 20).padding(.vertical, 12)
                                .background(Color.mdPaper2).cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mdLine, lineWidth: 1))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .background(Color.mdPaper).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mdLine, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Premium tier
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Spacer()
                            Text("MOST POPULAR").font(.system(size: 10, weight: .bold)).foregroundColor(.white).tracking(1)
                                .padding(.horizontal, 12).padding(.vertical, 6).background(Color.mdGold).cornerRadius(999)
                        }
                        Text("Premium").font(.mdDisplay(22, weight: .bold)).foregroundColor(.white)
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$149").font(.mdDisplay(32, weight: .bold)).foregroundColor(.white)
                            Text("/month").font(.system(size: 16)).foregroundColor(.white.opacity(0.7))
                        }
                        Text("2 remote 1-on-1 sessions a month · 30 min each")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.mdGold)
                        VStack(alignment: .leading, spacing: 6) {
                            BulletPoint(text: "Everything in Member", light: true)
                            BulletPoint(text: "1-on-1 sessions", light: true)
                        }
                        Button { } label: {
                            Text("Request Premium").font(.system(size: 14, weight: .bold)).foregroundColor(.mdInk)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(Color.mdGold).cornerRadius(10)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                    .background(Color.mdInk).cornerRadius(16)
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletPoint: View {
    let text: String
    var light: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(light ? Color.white.opacity(0.5) : Color.mdInk).frame(width: 6, height: 6)
            Text(text).font(.system(size: 14)).foregroundColor(light ? .white : .mdText)
        }
    }
}

struct MessengerView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            VStack(spacing: 0) {
                // Messenger card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bubble.left.fill").font(.system(size: 20)).foregroundColor(.mdAccent)
                        Text("Messenger").font(.mdDisplay(22, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Button { } label: {
                            Image(systemName: "pencil").font(.system(size: 18)).foregroundColor(.white)
                                .frame(width: 44, height: 44).background(Color.mdInk2).cornerRadius(12)
                        }
                    }

                    // Dr. Jared row
                    HStack(spacing: 14) {
                        Circle().fill(Color.mdInk2).frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "stethoscope").font(.system(size: 24)).foregroundColor(.mdAccent)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Dr. Jared Caban").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            Text("Members can message Dr. Ja...").font(.system(size: 14)).foregroundColor(.white.opacity(0.6))
                            HStack(spacing: 8) {
                                Text("DIRECT").font(.system(size: 10, weight: .bold)).foregroundColor(.mdAccent)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.mdAccent, lineWidth: 1))
                                Text("MEMBERS").font(.system(size: 10, weight: .bold)).foregroundColor(.mdGold)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.mdGold.opacity(0.2)).cornerRadius(999)
                            }
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // Monthly Q&A row
                    HStack(spacing: 14) {
                        Circle().fill(Color.mdInk2).frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "video").font(.system(size: 24)).foregroundColor(.mdAccent)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly live Q&A").font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                            Text("Next date coming soon").font(.system(size: 14)).foregroundColor(.white.opacity(0.6)).italic()
                            Text("LIVE").font(.system(size: 10, weight: .bold)).foregroundColor(.mdAccent)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .overlay(RoundedRectangle(cornerRadius: 999).stroke(Color.mdAccent, lineWidth: 1))
                        }
                    }
                }
                .padding(20).background(Color.mdInk).cornerRadius(20)
                .padding(16)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthTipsView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.mdCream.ignoresSafeArea()
            VStack(spacing: 16) {
                // Hero
                ZStack { Color.mdInk }
                    .frame(height: 100)
                    .overlay(
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 0) {
                                Text("Health ").font(.mdDisplay(26, weight: .bold)).foregroundColor(.white)
                                Text("Tips").font(.mdDisplay(26, weight: .bold)).italic().foregroundColor(.mdGold)
                            }
                            Text("DR. JARED'S PROTOCOLS, WRITTEN OUT TO READ ON ANY SCREEN.")
                                .font(.system(size: 9, weight: .semibold)).foregroundColor(.mdOnNavy).tracking(0.5)
                        }
                        .padding(.horizontal, 20), alignment: .bottomLeading
                    )

                Text("All").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8).background(Color.mdInk).cornerRadius(999)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 16)

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct MoreMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MoreMenuView()
            .environmentObject(AuthService.shared)
    }
}
