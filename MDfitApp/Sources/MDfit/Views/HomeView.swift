import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    welcomeHeader

                    // Next appointment card
                    nextAppointmentCard

                    // Quick actions
                    quickActions

                    // Today's exercises
                    todaysExercises

                    // Recent progress
                    recentProgress
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
        }
    }

    // MARK: - Components

    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.mdSubheadline)
                    .foregroundColor(.mdGray)

                Text(authService.currentUser?.firstName ?? "Welcome")
                    .font(.mdTitle)
            }
            Spacer()

            // Profile avatar
            Circle()
                .fill(Color.mdOrange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(authService.currentUser?.initials ?? "?")
                        .font(.mdHeadline)
                        .foregroundColor(.mdOrange)
                )
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var nextAppointmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next Appointment")
                    .font(.mdHeadline)
                Spacer()
                Text("In 2 days")
                    .font(.mdCaption)
                    .foregroundColor(.mdOrange)
            }

            HStack(spacing: 16) {
                // Date badge
                VStack {
                    Text("OCT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.mdOrange)
                    Text("26")
                        .font(.system(size: 24, weight: .bold))
                }
                .frame(width: 56, height: 56)
                .background(Color.mdOrange.opacity(0.1))
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Physical Rehabilitation")
                        .font(.mdBody)
                    Text("10:00 AM • 60 min")
                        .font(.mdCaption)
                        .foregroundColor(.mdGray)
                    Text("Dr. Jared Caban")
                        .font(.mdCaption)
                        .foregroundColor(.mdGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.mdGray)
            }
        }
        .mdCard()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Log Pain",
                color: .mdOrange
            ) {
                // TODO: Open pain logging
            }

            QuickActionButton(
                icon: "calendar.badge.plus",
                label: "Book",
                color: .mdOrange
            ) {
                // TODO: Open booking
            }

            QuickActionButton(
                icon: "message.fill",
                label: "Message",
                color: .mdOrange
            ) {
                // TODO: Open messaging
            }

            QuickActionButton(
                icon: "phone.fill",
                label: "Call",
                color: .mdOrange
            ) {
                // TODO: Call office
            }
        }
    }

    private var todaysExercises: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Exercises")
                    .font(.mdHeadline)
                Spacer()
                Text("3 remaining")
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            ForEach(Exercise.samples.prefix(2)) { exercise in
                ExerciseRow(exercise: exercise)
            }

            Button("View All Exercises") {
                // TODO: Navigate to exercises
            }
            .font(.mdSubheadline)
            .foregroundColor(.mdOrange)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .mdCard()
    }

    private var recentProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pain Level Trend")
                    .font(.mdHeadline)
                Spacer()
                Text("Last 7 days")
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            // Simple trend visualization
            HStack(alignment: .bottom, spacing: 8) {
                ForEach([7, 6, 5, 6, 4, 4, 3], id: \.self) { level in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(painColor(for: level))
                            .frame(width: 32, height: CGFloat(level * 12 + 20))
                        Text("\(level)")
                            .font(.system(size: 10))
                            .foregroundColor(.mdGray)
                    }
                }
            }
            .frame(height: 120)

            HStack {
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.mdSuccess)
                Text("Down 57% from last week")
                    .font(.mdCaption)
                    .foregroundColor(.mdSuccess)
            }
        }
        .mdCard()
    }

    private func painColor(for level: Int) -> Color {
        switch level {
        case 0...3: return .mdSuccess
        case 4...6: return .mdWarning
        default: return .mdError
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
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

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.mdOrange.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: exercise.category.icon)
                        .foregroundColor(.mdOrange)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.mdBody)
                Text(exercise.formattedDuration ?? "")
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            Spacer()

            Button {
                // TODO: Start exercise
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.mdOrange)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService())
}
