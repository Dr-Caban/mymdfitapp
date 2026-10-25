import SwiftUI

// MARK: - Brand Colors

extension Color {
    /// MD Fit primary orange - #FF7A00
    static let mdOrange = Color(red: 1.0, green: 0.478, blue: 0.0)

    /// Dark background - #1A1A2E
    static let mdDark = Color(red: 0.102, green: 0.102, blue: 0.180)

    /// Secondary gray - #8A8A8A
    static let mdGray = Color(red: 0.541, green: 0.541, blue: 0.541)

    /// Success green
    static let mdSuccess = Color(red: 0.2, green: 0.78, blue: 0.35)

    /// Warning amber
    static let mdWarning = Color(red: 1.0, green: 0.76, blue: 0.03)

    /// Error red
    static let mdError = Color(red: 0.94, green: 0.27, blue: 0.27)
}

// MARK: - Typography

extension Font {
    /// Large title - 34pt bold
    static let mdLargeTitle = Font.system(size: 34, weight: .bold)

    /// Title - 28pt bold
    static let mdTitle = Font.system(size: 28, weight: .bold)

    /// Headline - 17pt semibold
    static let mdHeadline = Font.system(size: 17, weight: .semibold)

    /// Body - 17pt regular
    static let mdBody = Font.system(size: 17, weight: .regular)

    /// Subheadline - 15pt regular
    static let mdSubheadline = Font.system(size: 15, weight: .regular)

    /// Caption - 12pt regular
    static let mdCaption = Font.system(size: 12, weight: .regular)
}

// MARK: - Button Styles

struct MDPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.mdHeadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.mdOrange)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct MDSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.mdHeadline)
            .foregroundColor(.mdOrange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mdOrange, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == MDPrimaryButtonStyle {
    static var mdPrimary: MDPrimaryButtonStyle { MDPrimaryButtonStyle() }
}

extension ButtonStyle where Self == MDSecondaryButtonStyle {
    static var mdSecondary: MDSecondaryButtonStyle { MDSecondaryButtonStyle() }
}

// MARK: - Card Style

struct MDCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func mdCard() -> some View {
        modifier(MDCardModifier())
    }
}
