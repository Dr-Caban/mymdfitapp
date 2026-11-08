import AuthenticationServices
import UIKit
import WebKit

/// Google refuses to sign in inside an app's web view, so "Continue with Google" opens the login page in a Safari
/// sheet that shares the phone's Google session. The page signs in, asks the server for a one-time code and
/// returns to mdfit://auth?code=…; the app then loads /login?handoff=<code>, which turns it into the session.
@MainActor
enum BrowserSignIn {
    private static var session: ASWebAuthenticationSession?
    private static let anchor = Anchor()

    static func start(webView: WKWebView?) {
        guard let url = URL(string: "https://www.mymdfit.com/login?app=1&google=1") else { return }
        session?.cancel()
        let s = ASWebAuthenticationSession(url: url, callbackURLScheme: "mdfit") { callback, _ in
            guard let callback,
                  let code = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value,
                  var parts = URLComponents(string: "https://www.mymdfit.com/login") else { return }
            parts.queryItems = [URLQueryItem(name: "handoff", value: code)]
            if let next = parts.url { Task { @MainActor in webView?.load(URLRequest(url: next)) } }
        }
        s.presentationContextProvider = anchor
        s.prefersEphemeralWebBrowserSession = false   // reuse the phone's Google login
        session = s
        s.start()
    }

    final class Anchor: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
        }
    }
}
