import AuthenticationServices
import UIKit

/// Payments. Stripe's hosted Checkout opens in a Safari-based sheet where Apple Pay works (it is disabled inside
/// the app's own web view). When Stripe finishes it sends the member to /app-return, which redirects to
/// mdfit://checkout?to=…; the sheet closes and AppModel opens that page.
///
/// Memberships are digital subscriptions: Apple's rules want those bought through In-App Purchase, or through a
/// link that leaves the app (allowed in the US). So "membership" opens in Safari itself and comes back the same way.
@MainActor
enum CheckoutSheet {
    private static var session: ASWebAuthenticationSession?
    private static let anchor = Anchor()

    static func start(url: URL, kind: String) {
        if kind == "membership" {
            UIApplication.shared.open(url)
            return
        }
        session?.cancel()
        let s = ASWebAuthenticationSession(url: url, callbackURLScheme: "mdfit") { callback, _ in
            guard let callback else { return }   // closed with Done: stay where we were
            Task { @MainActor in AppModel.shared.handle(callback: callback) }
        }
        s.presentationContextProvider = anchor
        s.prefersEphemeralWebBrowserSession = true   // no "wants to use mymdfit.com to sign in" prompt; Apple Pay still works
        session = s
        s.start()
    }

    final class Anchor: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        }
    }
}
