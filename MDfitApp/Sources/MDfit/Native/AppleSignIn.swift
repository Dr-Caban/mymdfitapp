import AuthenticationServices
import UIKit
import WebKit

/// Sign in with Apple, started from the app's login page. Apple returns an identity token; the page sends it to
/// the server (/api/clients/apple), which signs the member in. Apple shares the name only on the first sign-in.
@MainActor
final class AppleSignIn: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AppleSignIn()
    private weak var webView: WKWebView?

    func start(webView: WKWebView?) {
        self.webView = webView
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential,
              let data = cred.identityToken, let token = String(data: data, encoding: .utf8) else { return }
        let payload: [String: String] = [
            "identityToken": token,
            "firstName": cred.fullName?.givenName ?? "",
            "lastName": cred.fullName?.familyName ?? ""
        ]
        guard let json = try? JSONSerialization.data(withJSONObject: payload), let text = String(data: json, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("window.MDFitNative && MDFitNative.appleSignedIn(\(text))", completionHandler: nil)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let code = (error as? ASAuthorizationError)?.code
        if code == .canceled { return }   // the member closed the sheet
        webView?.evaluateJavaScript("window.MDFitNative && MDFitNative.appleSignInFailed()", completionHandler: nil)
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first ?? ASPresentationAnchor()
    }
}
