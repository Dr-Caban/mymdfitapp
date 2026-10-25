import SwiftUI

// MARK: - MD Fit Brand Colors (from Workout Generator screenshot)

extension Color {
    // Primary blue - headers, nav, backgrounds
    static let mdBlue = Color(red: 0.0, green: 0.322, blue: 0.647)          // #0052A5
    static let mdBlueDark = Color(red: 0.0, green: 0.2, blue: 0.4)          // #003366
    static let mdBlueLight = Color(red: 0.2, green: 0.5, blue: 0.8)         // #3380CC

    // Gold/Orange accent - CTAs, selected states
    static let mdGold = Color(red: 0.831, green: 0.659, blue: 0.294)        // #D4A84B
    static let mdOrange = Color(red: 1.0, green: 0.478, blue: 0.0)          // #FF7A00

    // Neutrals
    static let mdWhite = Color.white
    static let mdGray = Color(red: 0.541, green: 0.541, blue: 0.541)        // #8A8A8A
    static let mdGrayLight = Color(red: 0.9, green: 0.9, blue: 0.92)
    static let mdDark = Color(red: 0.102, green: 0.102, blue: 0.180)        // #1A1A2E

    // Status colors
    static let mdSuccess = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let mdWarning = Color(red: 1.0, green: 0.76, blue: 0.03)
    static let mdError = Color(red: 0.94, green: 0.27, blue: 0.27)
}

// MARK: - Gradients

extension LinearGradient {
    static let mdHeader = LinearGradient(
        colors: [Color.mdBlueDark, Color.mdBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mdBackground = LinearGradient(
        colors: [Color.mdBlue.opacity(0.95), Color.mdBlueDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    // Large title - 34pt bold
    static let mdLargeTitle = Font.system(size: 34, weight: .bold)

    // Title - 28pt bold
    static let mdTitle = Font.system(size: 28, weight: .bold)

    // Title 2 - 22pt bold
    static let mdTitle2 = Font.system(size: 22, weight: .bold)

    // Section header - 14pt bold uppercase
    static let mdSectionHeader = Font.system(size: 14, weight: .bold)

    // Headline - 17pt semibold
    static let mdHeadline = Font.system(size: 17, weight: .semibold)

    // Body - 17pt regular
    static let mdBody = Font.system(size: 17, weight: .regular)

    // Subheadline - 15pt regular
    static let mdSubheadline = Font.system(size: 15, weight: .regular)

    // Caption - 12pt regular
    static let mdCaption = Font.system(size: 12, weight: .regular)

    // Small - 11pt
    static let mdSmall = Font.system(size: 11, weight: .regular)
}

// MARK: - Button Styles

struct MDPrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.mdBlueDark)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.mdGold)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct MDSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == MDPrimaryButtonStyle {
    static var mdPrimary: MDPrimaryButtonStyle { MDPrimaryButtonStyle() }
}

extension ButtonStyle where Self == MDSecondaryButtonStyle {
    static var mdSecondary: MDSecondaryButtonStyle { MDSecondaryButtonStyle() }
}

// MARK: - Selection Chip Style (for generator options)

struct SelectionChip: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10))
                        .opacity(0.8)
                }
            }
            .foregroundColor(isSelected ? .mdBlueDark : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.mdGold : Color.white.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.mdGold : Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Number Chip (for exercises per round, rounds, etc.)

struct NumberChip: View {
    let value: Int
    let label: String?
    let isSelected: Bool
    let action: () -> Void

    init(value: Int, label: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.value = value
        self.label = label
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold))
                if let label = label {
                    Text(label)
                        .font(.system(size: 9))
                }
            }
            .foregroundColor(isSelected ? .mdBlueDark : .white)
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.mdGold : Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Card Style

struct MDCardModifier: ViewModifier {
    var backgroundColor: Color = Color(.systemBackground)

    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func mdCard(backgroundColor: Color = Color(.systemBackground)) -> some View {
        modifier(MDCardModifier(backgroundColor: backgroundColor))
    }
}

// MARK: - Section Header

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
        HStack(spacing: 12) {
            if let number = number {
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.mdBlueDark)
                    .frame(width: 28, height: 28)
                    .background(Color.mdGold)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()
        }
    }
}

// MARK: - Toggle Row

struct MDToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.mdGold)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.mdGold)
        }
        .padding(.vertical, 8)
    }
}
