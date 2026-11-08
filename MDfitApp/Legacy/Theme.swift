import SwiftUI

// MARK: - MD Fit Design System
// Exact tokens from mdfit-frontend/styles.css

// MARK: - Brand Colors (from CSS :root)

extension Color {
    // Brand navy - primary dark color
    static let mdInk = Color(hex: "0A1A2E")
    static let mdInk2 = Color(hex: "10233b")
    static let mdInk3 = Color(hex: "1d3352")

    // Brand cream background
    static let mdCream = Color(hex: "F6F4EE")

    // Card backgrounds
    static let mdPaper = Color(hex: "FFFFFF")
    static let mdPaper2 = Color(hex: "EFEBE1")

    // Border color
    static let mdLine = Color(hex: "e4ded1")

    // Text colors
    static let mdText = Color(hex: "424244")
    static let mdHeading = Color(hex: "0A1A2E")
    static let mdMuted = Color(hex: "6b6a6e")

    // Accent blue
    static let mdAccent = Color(hex: "7AAFD7")
    static let mdAccentHover = Color(hex: "6AA2CD")
    static let mdAccentInk = Color(hex: "0A1A2E")
    static let mdAccentText = Color(hex: "2F6E9E")
    static let mdAccentBright = Color(hex: "8EC0E6")
    static let mdAccentSoft = Color(hex: "EAF3FA")

    // Brand gold
    static let mdGold = Color(hex: "C8A763")
    static let mdGoldSoft = Color(hex: "FBF3E3")

    // Status colors
    static let mdOk = Color(hex: "2e7d4f")
    static let mdErr = Color(hex: "c62828")

    // Text on navy backgrounds
    static let mdOnNavy = Color.white.opacity(0.7)

    // Legacy aliases
    static let mdBlue = Color(hex: "2F6E9E")
    static let mdDark = Color(hex: "0A1A2E")
    static let mdBackground = Color(hex: "F6F4EE")
    static let mdGray = Color(hex: "6b6a6e")
    static let mdBlueDark = Color(hex: "0A1A2E")
    static let mdSuccess = Color(hex: "2e7d4f")
    static let mdBlueLight = Color(hex: "7AAFD7")

    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Constants

enum MDTheme {
    // Corner radius (14px from CSS)
    static let radius: CGFloat = 14
    static let radiusSmall: CGFloat = 10
    static let radiusLarge: CGFloat = 20

    // Padding
    static let cardPadding: CGFloat = 22
    static let sectionPadding: CGFloat = 16

    // Shadow
    static let shadowColor = Color(hex: "0A1A2E").opacity(0.28)
    static let shadowRadius: CGFloat = 15
    static let shadowY: CGFloat = 6
}

// MARK: - Typography (Libre Baskerville for display, Montserrat for body)

extension Font {
    // Display font (serif for headings)
    static func mdDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }

    // Body font (sans-serif)
    static func mdBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    // Heading sizes
    static let mdH1 = Font.custom("Georgia", size: 34).weight(.bold)
    static let mdH2 = Font.custom("Georgia", size: 22).weight(.bold)
    static let mdH3 = Font.custom("Georgia", size: 16).weight(.bold)

    // Body sizes
    static let mdBodyLarge = Font.system(size: 17, weight: .regular)
    static let mdBodyMedium = Font.system(size: 15, weight: .regular)
    static let mdBodySmall = Font.system(size: 14, weight: .regular)
    static let mdCaption = Font.system(size: 12, weight: .regular)

    // Eyebrow/Label
    static let mdEyebrow = Font.system(size: 12, weight: .bold)

    // Legacy fonts
    static let mdTitle = Font.custom("Georgia", size: 28).weight(.bold)
    static let mdSubheadline = Font.system(size: 15, weight: .regular)
}

// MARK: - Card Styles

struct MDCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 22

    init(padding: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.mdPaper)
            .cornerRadius(MDTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: MDTheme.radius)
                    .stroke(Color.mdLine, lineWidth: 1)
            )
    }
}

struct MDNavyCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 22

    init(padding: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.mdInk)
            .cornerRadius(MDTheme.radius)
    }
}

struct MDGoldCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 22

    init(padding: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.mdGoldSoft)
            .cornerRadius(MDTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: MDTheme.radius)
                    .stroke(Color(hex: "e6d5ad"), lineWidth: 1)
            )
    }
}

// MARK: - Button Styles

struct MDPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.mdAccentInk)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.mdAccent)
                .cornerRadius(999)
        }
    }
}

struct MDSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.mdInk)
                .cornerRadius(999)
        }
    }
}

struct MDOutlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.mdText)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Color.clear)
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(Color.mdLine, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Section Header with Number Badge

struct MDSectionHeader: View {
    let number: Int?
    let title: String
    let subtitle: String?

    init(_ title: String, number: Int? = nil, subtitle: String? = nil) {
        self.title = title
        self.number = number
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: 10) {
            if let number = number {
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.mdInk)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.mdEyebrow)
                    .foregroundColor(.mdHeading)
                    .tracking(1.2)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.mdCaption)
                        .foregroundColor(.mdMuted)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Eyebrow Label (uppercase tracking)

struct MDEyebrow: View {
    let text: String
    var color: Color = .mdAccentText

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12.5, weight: .bold))
            .foregroundColor(color)
            .tracking(2)
    }
}

// MARK: - Hero Header Card (navy background with radial gradient)

struct MDHeroCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .background(
                ZStack {
                    Color.mdInk
                    RadialGradient(
                        colors: [Color.mdAccent.opacity(0.16), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                }
            )
            .cornerRadius(MDTheme.radius)
    }
}

// MARK: - XP/Gem Badge

struct MDGemBadge: View {
    let gemName: String
    let xp: Int
    let rank: Int?

    var body: some View {
        HStack(spacing: 8) {
            Text(gemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.mdInk)
                .cornerRadius(999)

            Text("\(xp) XP")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            if let rank = rank {
                Spacer()
                Text("#\(rank)")
                    .font(.mdDisplay(18, weight: .bold))
                    .foregroundColor(.mdGold)
                Text("OVERALL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.mdInk.opacity(0.9))
        .cornerRadius(MDTheme.radius)
    }
}

// MARK: - Search Bar

struct MDSearchBar: View {
    @Binding var text: String
    var placeholder: String = "What hurts? Search anything"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.mdMuted)

            TextField(placeholder, text: $text)
                .font(.mdBodyMedium)
                .foregroundColor(.mdText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.mdPaper)
        .cornerRadius(MDTheme.radius)
        .overlay(
            RoundedRectangle(cornerRadius: MDTheme.radius)
                .stroke(Color.mdLine, lineWidth: 1)
        )
    }
}

// MARK: - Tab Bar Item

struct MDTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .mdAccentBright : .white.opacity(0.6))

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .mdAccentBright : .white.opacity(0.6))
        }
    }
}

// MARK: - Appointment Row (from account.css)

struct MDAppointmentRow: View {
    let month: String
    let day: Int
    let title: String
    let time: String
    let duration: String

    var body: some View {
        HStack(spacing: 14) {
            // Date badge
            VStack(spacing: 0) {
                Text(month.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.mdGold)
                    .tracking(1)
                Text("\(day)")
                    .font(.mdDisplay(20, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 52)
            .padding(.vertical, 6)
            .background(Color.mdInk)
            .cornerRadius(10)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundColor(.mdHeading)

                Text("\(time) · \(duration)")
                    .font(.system(size: 13))
                    .foregroundColor(.mdMuted)

                HStack(spacing: 14) {
                    Button("Cancel") {}
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mdErr)

                    Button("Add to calendar") {}
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mdAccentText)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.mdPaper)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mdLine, lineWidth: 1)
        )
    }
}

// MARK: - Workout History Row

struct MDWorkoutRow: View {
    let title: String
    let duration: String
    let exercises: Int
    let date: String
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Checkmark circle
            Circle()
                .fill(isCompleted ? Color.mdAccentSoft : Color.mdPaper2)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: isCompleted ? "checkmark" : "dumbbell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isCompleted ? .mdAccentText : .mdMuted)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.mdHeading)

                Text("\(duration) · \(exercises) exercises")
                    .font(.system(size: 13))
                    .foregroundColor(.mdMuted)
            }

            Spacer()

            Text(date)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.mdAccentText)
        }
    }
}

// MARK: - Progress Bar

struct MDProgressBar: View {
    let progress: Double
    var height: CGFloat = 10
    var backgroundColor: Color = .mdAccentSoft
    var foregroundColor: Color = .mdGold

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * min(progress, 1.0))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Calendar Day Cell

struct MDCalendarDay: View {
    let day: Int
    let isToday: Bool
    let hasWorkout: Bool
    let hasVisit: Bool
    let hasPainLog: Bool

    var body: some View {
        ZStack {
            if hasWorkout {
                Circle()
                    .fill(Color.mdGold)
            } else if isToday {
                Circle()
                    .stroke(Color.mdAccent, lineWidth: 2)
            } else {
                Circle()
                    .fill(Color.mdPaper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Color.mdLine, lineWidth: 1)
                    )
            }

            Text("\(day)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(hasWorkout ? .mdInk : .mdText)
        }
        .frame(width: 32, height: 32)
    }
}

// MARK: - Menu Row (More sheet)

struct MDMenuRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.mdAccentText)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mdHeading)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.mdPaper2)
            .cornerRadius(12)
        }
    }
}

// MARK: - Logo

struct MDFitLogo: View {
    var height: CGFloat = 62

    var body: some View {
        Image("MDFitLogo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}

// MARK: - View Extensions

extension View {
    func mdCardStyle(padding: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .background(Color.mdPaper)
            .cornerRadius(MDTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: MDTheme.radius)
                    .stroke(Color.mdLine, lineWidth: 1)
            )
    }

    func mdNavyCardStyle(padding: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .background(Color.mdInk)
            .cornerRadius(MDTheme.radius)
    }

    func mdGoldCardStyle(padding: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .background(Color.mdGoldSoft)
            .cornerRadius(MDTheme.radius)
            .overlay(
                RoundedRectangle(cornerRadius: MDTheme.radius)
                    .stroke(Color(hex: "e6d5ad"), lineWidth: 1)
            )
    }

    func mdShadow() -> some View {
        self.shadow(
            color: MDTheme.shadowColor,
            radius: MDTheme.shadowRadius,
            x: 0,
            y: MDTheme.shadowY
        )
    }
}

// MARK: - Button Styles

struct MDPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.mdInk)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MDSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.mdInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.mdPaper)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mdLine, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MDGoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.mdInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.mdGold)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == MDPrimaryButtonStyle {
    static var mdPrimary: MDPrimaryButtonStyle { MDPrimaryButtonStyle() }
}

extension ButtonStyle where Self == MDSecondaryButtonStyle {
    static var mdSecondary: MDSecondaryButtonStyle { MDSecondaryButtonStyle() }
}

extension ButtonStyle where Self == MDGoldButtonStyle {
    static var mdGold: MDGoldButtonStyle { MDGoldButtonStyle() }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    static let mdDarkBackground = LinearGradient(
        colors: [Color.mdInk, Color.mdInk2],
        startPoint: .top,
        endPoint: .bottom
    )

    static let mdBackground = LinearGradient(
        colors: [Color.mdCream, Color.mdCream],
        startPoint: .top,
        endPoint: .bottom
    )

    static let mdGoldGradient = LinearGradient(
        colors: [Color.mdGold, Color(hex: "e9d39f")],
        startPoint: .leading,
        endPoint: .trailing
    )
}
