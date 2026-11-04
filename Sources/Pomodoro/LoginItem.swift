import Foundation
import ServiceManagement

/// Open-at-login via the macOS 13 login item API. Turned on once on first
/// launch; after that the user's choice in the panel (or System Settings) wins.
enum LoginItem {
    private static let setupKey = "loginItemSetUp"

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Pomodoro: login item update failed: \(error)")
        }
    }

    static func enableOnFirstLaunch() {
        guard Bundle.main.bundleIdentifier != nil,
              !UserDefaults.standard.bool(forKey: setupKey) else { return }
        UserDefaults.standard.set(true, forKey: setupKey)
        set(true)
    }
}
