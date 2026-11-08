import SwiftUI

/// MD Fit for iPhone: the real member app (https://www.mymdfit.com/account) in a native shell, plus iOS
/// features the website can't offer on its own: haptics, the share sheet, Calendar, streak reminders,
/// Home Screen quick actions and an offline screen.
@main
struct MDfitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        WindowGroup {
            ShellView()
                .environmentObject(model)
        }
    }
}
