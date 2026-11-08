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

    /// APNs device token (hex). The page sends it to the server with the member's own login.
    var deviceToken: String? {
        didSet { pushDeviceTokenToPage() }
    }

    func pushDeviceTokenToPage() {
        guard let token = deviceToken, let web = webView, hasLoadedOnce, Self.isSite(web.url) else { return }
        web.evaluateJavaScript("window.MDFitNative && MDFitNative.setDeviceToken('\(token)')", completionHandler: nil)
    }

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
        // "admin" / "admin/messages": Dr. Jared's alerts open the management portal
        let page = hash.hasPrefix("admin") ? "/admin" : "/account"
        let tab = hash.hasPrefix("admin") ? String(hash.dropFirst("admin".count).drop(while: { $0 == "/" })) : hash
        if Self.isSite(web.url), web.url?.path.hasPrefix(page) == true {
            web.evaluateJavaScript("location.hash = '#\(tab)'", completionHandler: nil)
        } else if let url = URL(string: "https://www.mymdfit.com\(page)#\(tab)") {
            web.load(URLRequest(url: url))
        }
    }

    /// mdfit://checkout?to=/account?checkout=success…#premium (from /app-return after a payment, or a cancel)
    func handle(callback url: URL) {
        guard url.scheme?.lowercased() == "mdfit", url.host?.lowercased() == "checkout",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else { return }
        var to = items.first(where: { $0.name == "to" })?.value ?? "/account#premium"
        if !to.hasPrefix("/") || to.hasPrefix("//") { to = "/account#premium" }
        guard let next = URL(string: "https://www.mymdfit.com" + to) else { return }
        if let web = webView { web.load(URLRequest(url: next)) } else { pendingRoute = nil }
        if items.contains(where: { $0.name == "cancel" }) == false { Haptics.play("success") }
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
        pushDeviceTokenToPage()
        // Signed in and looking at the member app or Admin: ask once to allow notifications (visits, messages)
        if let path = webView?.url?.path, Self.isSite(webView?.url), path.hasPrefix("/account") || path.hasPrefix("/admin") {
            Task { try? await Task.sleep(for: .seconds(4)); Reminders.requestPermissionIfNeeded() }
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
