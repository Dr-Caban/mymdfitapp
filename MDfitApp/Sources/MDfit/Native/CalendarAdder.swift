import EventKit
import EventKitUI
import UIKit

/// Turns the site's "Add to calendar" .ics into the native Add Event sheet. On iOS 17+ this sheet doesn't need
/// calendar permission: the member reviews the event and taps Add.
@MainActor
enum CalendarAdder {
    private static let store = EKEventStore()
    private static let delegate = EditDelegate()

    static func present(ics: String) {
        let fields = parse(ics)
        guard let start = fields["DTSTART"].flatMap(date) else { return }

        let event = EKEvent(eventStore: store)
        event.title = fields["SUMMARY"].map(unescape) ?? "MD Fit"
        event.startDate = start
        event.endDate = fields["DTEND"].flatMap(date) ?? start.addingTimeInterval(3600)
        event.location = fields["LOCATION"].map(unescape)
        event.notes = fields["DESCRIPTION"].map(unescape)
        if let s = fields["URL"], let url = URL(string: s) { event.url = url }
        event.addAlarm(EKAlarm(relativeOffset: -3600))   // remind an hour before

        let editor = EKEventEditViewController()
        editor.eventStore = store
        editor.event = event
        editor.editViewDelegate = delegate
        Presenter.present(editor)
    }

    /// First VEVENT's properties, with folded lines joined and parameters (";TZID=...") dropped from keys.
    private static func parse(_ ics: String) -> [String: String] {
        let unfolded = ics.replacingOccurrences(of: "\r\n ", with: "").replacingOccurrences(of: "\n ", with: "")
        var out: [String: String] = [:]
        var inEvent = false
        for raw in unfolded.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line == "BEGIN:VEVENT" { inEvent = true; continue }
            if line == "END:VEVENT" { break }
            guard inEvent, let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).components(separatedBy: ";")[0].uppercased()
            if out[key] == nil { out[key] = String(line[line.index(after: colon)...]) }
        }
        return out
    }

    private static func date(_ value: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        if value.hasSuffix("Z") {
            f.timeZone = TimeZone(identifier: "UTC")
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        } else if value.count == 8 {
            f.timeZone = TimeZone(identifier: "America/New_York")
            f.dateFormat = "yyyyMMdd"
        } else {
            f.timeZone = TimeZone(identifier: "America/New_York")   // the clinic's time zone
            f.dateFormat = "yyyyMMdd'T'HHmmss"
        }
        return f.date(from: value)
    }

    private static func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    final class EditDelegate: NSObject, EKEventEditViewDelegate {
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
            if action == .saved {
                Task { @MainActor in Haptics.play("success") }
            }
        }
    }
}
