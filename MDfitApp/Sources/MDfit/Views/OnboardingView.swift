import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showSignIn = false
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.mdDark, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Logo
                    VStack(spacing: 16) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 72, weight: .light))
                            .foregroundColor(.mdOrange)

                        Text("MD FIT")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)

                        Text("Physical Rehabilitation & Fitness")
                            .font(.mdSubheadline)
                            .foregroundColor(.mdGray)
                    }

                    // Tagline
                    VStack(spacing: 8) {
                        Text("Pain Has Haunted You")
                            .font(.mdTitle)
                            .foregroundColor(.white)
                        Text("Long Enough")
                            .font(.mdTitle)
                            .foregroundColor(.mdOrange)
                    }

                    Spacer()

                    // Buttons
                    VStack(spacing: 16) {
                        Button("Get Started") {
                            showSignUp = true
                        }
                        .buttonStyle(.mdPrimary)

                        Button("I have an account") {
                            showSignIn = true
                        }
                        .buttonStyle(.mdSecondary)

                        Button("Continue as Guest") {
                            authService.continueAsGuest()
                        }
                        .font(.mdSubheadline)
                        .foregroundColor(.mdGray)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
            .sheet(isPresented: $showSignIn) {
                SignInView()
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
        }
    }
}

// MARK: - Sign In

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                Section {
                    Button("Sign In") {
                        Task {
                            do {
                                try await authService.signIn(email: email, password: password)
                                dismiss()
                            } catch {
                                showError = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Sign In Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(authService.error?.localizedDescription ?? "Please try again.")
            }
        }
    }
}

// MARK: - Sign Up

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false

    var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && password.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Name") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Account") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password (8+ characters)", text: $password)
                        .textContentType(.newPassword)
                }

                Section {
                    Button("Create Account") {
                        Task {
                            do {
                                try await authService.signUp(
                                    firstName: firstName,
                                    lastName: lastName,
                                    email: email,
                                    password: password
                                )
                                dismiss()
                            } catch {
                                showError = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!isValid || authService.isLoading)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Sign Up Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(authService.error?.localizedDescription ?? "Please try again.")
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService())
}
