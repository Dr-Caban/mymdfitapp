import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.mdOrange.opacity(0.2))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(authService.currentUser?.initials ?? "?")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.mdOrange)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "Guest User")
                                .font(.mdHeadline)
                            Text(authService.currentUser?.email ?? "Sign in to save progress")
                                .font(.mdCaption)
                                .foregroundColor(.mdGray)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Quick stats
                Section("Your Progress") {
                    HStack {
                        StatItem(value: "12", label: "Sessions")
                        Divider()
                        StatItem(value: "45", label: "Exercises")
                        Divider()
                        StatItem(value: "28", label: "Days Active")
                    }
                    .padding(.vertical, 8)
                }

                // Account settings
                Section("Account") {
                    NavigationLink {
                        Text("Personal Information")
                    } label: {
                        Label("Personal Info", systemImage: "person")
                    }

                    NavigationLink {
                        Text("Health Data")
                    } label: {
                        Label("Health Data", systemImage: "heart")
                    }

                    NavigationLink {
                        Text("Payment Methods")
                    } label: {
                        Label("Payment", systemImage: "creditcard")
                    }

                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                // Support
                Section("Support") {
                    Link(destination: URL(string: "tel:9413130562")!) {
                        Label("Call Office", systemImage: "phone")
                    }

                    Link(destination: URL(string: "https://mdfitsrq.com")!) {
                        Label("Website", systemImage: "globe")
                    }

                    NavigationLink {
                        Text("Help & FAQ")
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                }

                // Legal
                Section("Legal") {
                    NavigationLink {
                        Text("Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        Text("Terms of Service")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Sign out
                Section {
                    if authService.currentUser != nil {
                        Button(role: .destructive) {
                            authService.signOut()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button {
                            // TODO: Show sign in
                        } label: {
                            Label("Sign In", systemImage: "person.badge.plus")
                                .foregroundColor(.mdOrange)
                        }
                    }
                }

                // App info
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("MD Fit")
                                .font(.mdCaption)
                                .foregroundColor(.mdGray)
                            Text("Version 1.0.0")
                                .font(.system(size: 11))
                                .foregroundColor(.mdGray)
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.mdOrange)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.mdGray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}
