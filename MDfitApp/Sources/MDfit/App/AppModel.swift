import Foundation
import WebKit

/// App-wide state: the one web view, whether the member app has loaded, and routing to its tabs.
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    /// The member app. Signed-out visitors are sent to /login by the site itself.
    static let home = URL(string: "https://www.mymdfit.com/account")!
    static let siteHosts: Set<String> = ["www.mymdfit.com", "mymdfit.com"]

    @Published var hasLoadedOnce = false
    @Published var loadError: String?

    weak var webView: WKWebView?
    private var pendingRoute: String?

    static func isSite(_ url: URL?) -> Bool {
        guard let host = url?.host?.lowercased() else { return false }
        return siteHosts.contains(host)
    }

    /// Opens a tab of the member app, e.g. "generate", "pain", "progress", "messages/dr".
    func open(route: String) {
        let hash = String(route.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "/" || $0 == "-" })
        guard let web = webView, hasLoadedOnce else {
            pendingRoute = hash
            return
        }
        if Self.isSite(web.url), web.url?.path.hasPrefix("/account") == true {
            web.evaluateJavaScript("location.hash = '#\(hash)'", completionHandler: nil)
        } else if let url = URL(string: "https://www.mymdfit.com/account#\(hash)") {
            web.load(URLRequest(url: url))
        }
    }

    /// Quick action types look like "com.mdfitsrq.MDfit.generate"; the last part is the tab.
    func handleShortcut(_ type: String) {
        open(route: type.components(separatedBy: ".").last ?? "home")
    }

    func didFinishLoad() {
        hasLoadedOnce = true
        loadError = nil
        if let route = pendingRoute {
            pendingRoute = nil
            open(route: route)
        }
    }

    func didFailLoad(_ error: Error) {
        let ns = error as NSError
        // Cancelled navigations and links we handed to Safari aren't failures
        if ns.code == NSURLErrorCancelled || (ns.domain == "WebKitErrorDomain" && ns.code == 102) { return }
        if ns.domain == NSURLErrorDomain,
           [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut,
            NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDataNotAllowed].contains(ns.code) {
            loadError = "You're offline. Check your connection and try again."
        } else {
            loadError = "MD Fit couldn't load right now. Please try again."
        }
    }

    func retry() {
        loadError = nil
        guard let web = webView else { return }
        if web.url == nil { web.load(URLRequest(url: Self.home)) } else { web.reload() }
    }
}
