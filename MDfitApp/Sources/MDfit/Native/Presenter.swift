import SafariServices
import UIKit

/// Presents native sheets (alerts, share sheet, Safari, Calendar) over the web view.
@MainActor
enum Presenter {
    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    /// Returns false if there was nothing to present on (so callers can resolve their continuation).
    @discardableResult
    static func present(_ controller: UIViewController) -> Bool {
        guard let top = topViewController() else { return false }
        // iPad: action sheets and the share sheet need an anchor or UIKit throws
        if let pop = controller.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.maxY - 80, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        top.present(controller, animated: true)
        return true
    }

    /// Links that leave mymdfit.com open in an in-app Safari sheet, so the member stays signed in here.
    static func openOutside(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            UIApplication.shared.open(url)
            return
        }
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = UIColor(red: 10 / 255, green: 26 / 255, blue: 46 / 255, alpha: 1)
        safari.dismissButtonStyle = .done
        present(safari)
    }

    static func share(text: String, url: URL?) {
        var items: [Any] = []
        if !text.isEmpty { items.append(text) }
        if let url { items.append(url) }
        guard !items.isEmpty else { return }
        present(UIActivityViewController(activityItems: items, applicationActivities: nil))
    }
}
