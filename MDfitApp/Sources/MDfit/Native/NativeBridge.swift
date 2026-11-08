import UIKit
import WebKit

/// Receives `window.webkit.messageHandlers.mdfit.postMessage({ action, ... })` from BridgeScript and runs
/// the native side: haptics, share sheet, Calendar, streak reminders.
@MainActor
final class NativeBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Only the member app itself may drive native features (never an embedded third-party frame)
        guard message.frameInfo.isMainFrame,
              AppModel.siteHosts.contains(message.frameInfo.securityOrigin.host.lowercased()),
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "haptic":
            Haptics.play(body["style"] as? String ?? "light")

        case "sound":
            Sounds.play(body["name"] as? String ?? "")

        case "share":
            let text = [body["title"] as? String, body["text"] as? String]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
            let url = (body["url"] as? String).flatMap { $0.isEmpty ? nil : URL(string: $0) }
            Presenter.share(text: text, url: url)

        case "calendar":
            if let ics = body["ics"] as? String { CalendarAdder.present(ics: ics) }

        case "askNotifications":
            Reminders.requestPermissionIfNeeded()

        case "streak":
            Reminders.updateStreakReminder(
                qualifying: body["qualifying"] as? Bool ?? true,
                remaining: (body["remaining"] as? NSNumber)?.intValue ?? 0,
                streak: (body["streak"] as? NSNumber)?.intValue ?? 0
            )

        case "open":
            if let s = body["url"] as? String, let url = URL(string: s) { Presenter.openOutside(url) }

        default:
            break
        }
    }
}

enum Haptics {
    @MainActor
    static func play(_ style: String) {
        switch style {
        case "success", "warning", "error":
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(style == "success" ? .success : style == "warning" ? .warning : .error)
        case "selection":
            UISelectionFeedbackGenerator().selectionChanged()
        case "medium":
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case "heavy":
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
