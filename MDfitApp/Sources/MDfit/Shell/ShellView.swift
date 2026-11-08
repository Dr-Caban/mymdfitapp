import SwiftUI

extension Color {
    static let mdNavy = Color(red: 10 / 255, green: 26 / 255, blue: 46 / 255)   // #0A1A2E, the site's --navy
    static let mdGoldBrand = Color(red: 200 / 255, green: 167 / 255, blue: 99 / 255) // #C8A763
}

/// Full-screen member app, with a branded splash until the first page is ready and an offline screen.
struct ShellView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ZStack {
            Color.mdNavy.ignoresSafeArea()

            // The site handles the notch and home bar itself (viewport-fit=cover + safe-area insets)
            WebContainer()
                .ignoresSafeArea()

            if !model.hasLoadedOnce && model.loadError == nil {
                SplashView().transition(.opacity)
            }
            if let message = model.loadError {
                OfflineView(message: message) { model.retry() }
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: model.hasLoadedOnce)
        .animation(.easeOut(duration: 0.25), value: model.loadError)
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.mdNavy.ignoresSafeArea()
            VStack(spacing: 28) {
                Image("MDFitLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

struct OfflineView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ZStack {
            Color.mdNavy.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.mdGoldBrand)
                Text("Can't reach MD Fit")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button(action: retry) {
                    Text("Try again")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.mdNavy)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(Color.mdGoldBrand)
                        .clipShape(Capsule())
                }
                .padding(.top, 6)
                Link("Call 941-313-0562", destination: URL(string: "tel:+19413130562")!)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
