import SwiftUI
import UIKit
import WebKit

/// The member app in a WKWebView, configured to behave like a native app:
/// inline video, swipe-back, pull to refresh, native dialogs, links outside mymdfit.com in Safari.
struct WebContainer: UIViewRepresentable {
    private var model: AppModel { AppModel.shared }

    func makeCoordinator() -> Coordinator { Coordinator(model: AppModel.shared) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true                  // exercise videos play in place, like Safari
        config.mediaTypesRequiringUserActionForPlayback = []     // the workout player auto-advances to the next clip
        config.websiteDataStore = .default()                     // keeps the login across launches
        // A normal Safari user agent (the site's bot filter blocks unknown clients) plus an app marker
        config.applicationNameForUserAgent = "Version/18.0 Mobile/15E148 Safari/604.1 MDFitApp-iOS/1.0"

        let content = WKUserContentController()
        content.addUserScript(WKUserScript(source: BridgeScript.source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        content.add(context.coordinator.bridge, name: "mdfit")
        config.userContentController = content

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.allowsBackForwardNavigationGestures = true
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 10 / 255, green: 26 / 255, blue: 46 / 255, alpha: 1)
        web.scrollView.backgroundColor = web.backgroundColor
        web.scrollView.contentInsetAdjustmentBehavior = .never   // the page pads for the notch/home bar itself
        web.scrollView.keyboardDismissMode = .interactive

        let refresh = UIRefreshControl()
        refresh.tintColor = .white
        refresh.addTarget(context.coordinator, action: #selector(Coordinator.pullToRefresh(_:)), for: .valueChanged)
        web.scrollView.refreshControl = refresh

        #if DEBUG
        if #available(iOS 16.4, *) { web.isInspectable = true }
        #endif

        model.webView = web
        context.coordinator.bridge.webView = web
        web.load(URLRequest(url: AppModel.home))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let model: AppModel
        let bridge = NativeBridge()

        init(model: AppModel) { self.model = model }

        @objc func pullToRefresh(_ sender: UIRefreshControl) {
            if let web = model.webView {
                if web.url == nil { web.load(URLRequest(url: AppModel.home)) } else { web.reload() }
            }
        }

        private func endRefreshing(_ webView: WKWebView) {
            webView.scrollView.refreshControl?.endRefreshing()
        }

        // MARK: Navigation

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else { return .cancel }

            // Phone, email, text and maps links go to the system apps
            if ["tel", "mailto", "sms", "maps", "facetime"].contains(scheme) {
                await UIApplication.shared.open(url)
                return .cancel
            }
            if ["blob", "data", "about", "javascript"].contains(scheme) { return .allow }

            // target=_blank / window.open: handled in createWebViewWith
            guard let frame = navigationAction.targetFrame else { return .allow }

            // Embedded frames (Stripe checkout, Cal.com, video players) load inside the page as on the site
            if !frame.isMainFrame { return .allow }

            if AppModel.isSite(url) { return .allow }

            // Anything else (Google Maps, Stripe billing portal, Instagram...) opens in an in-app Safari sheet
            Presenter.openOutside(url)
            return .cancel
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            endRefreshing(webView)
            model.didFinishLoad()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            endRefreshing(webView)
            model.didFailLoad(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            endRefreshing(webView)
            model.didFailLoad(error)
        }

        // iOS can kill the web process in the background; come back to where the member was
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        // MARK: New windows (target=_blank, window.open)

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                if AppModel.isSite(url) { webView.load(navigationAction.request) } else { Presenter.openOutside(url) }
            }
            return nil
        }

        // MARK: alert / confirm / prompt as native dialogs (the site uses confirm() before deleting things)

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in done.resume() })
                if !Presenter.present(alert) { done.resume() }
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo) async -> Bool {
            await withCheckedContinuation { (done: CheckedContinuation<Bool, Never>) in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in done.resume(returning: false) })
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in done.resume(returning: true) })
                if !Presenter.present(alert) { done.resume(returning: false) }
            }
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt prompt: String,
            defaultText: String?,
            initiatedByFrame frame: WKFrameInfo
        ) async -> String? {
            await withCheckedContinuation { (done: CheckedContinuation<String?, Never>) in
                let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
                alert.addTextField { $0.text = defaultText }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in done.resume(returning: nil) })
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    done.resume(returning: alert.textFields?.first?.text ?? "")
                })
                if !Presenter.present(alert) { done.resume(returning: nil) }
            }
        }
    }
}
