import AppKit
import Combine
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = TimerModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Before the panel exists, so its checkbox reads the new state.
        LoginItem.enableOnFirstLaunch()

        statusItem = NSStatusBar.system.statusItem(withLength: PillRenderer.width + 8)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)
        statusItem.button?.setAccessibilityLabel("Pomodoro timer")

        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        // Without an explicit size the popover opens before SwiftUI reports
        // its height and clips the top of the panel.
        let host = NSHostingController(rootView: PanelView(model: model))
        host.sizingOptions = []
        let size = NSHostingView(rootView: PanelView(model: model)).fittingSize
        host.view.frame = NSRect(origin: .zero, size: size)
        host.preferredContentSize = size
        popover.contentViewController = host
        popover.contentSize = size

        model.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.refreshPill() }
            .store(in: &cancellables)
        refreshPill()

        model.onFinish = { [weak self] in self?.announceFinish() }
        if canNotify {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    private func refreshPill() {
        statusItem.button?.image = PillRenderer.image(for: model)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // UNUserNotificationCenter crashes outside an .app bundle (e.g. `swift run`).
    private var canNotify: Bool { Bundle.main.bundleIdentifier != nil }

    private func announceFinish() {
        NSSound(named: "Glass")?.play()
        guard canNotify else { return }
        let content = UNMutableNotificationContent()
        content.title = "Session done"
        content.body = "\(model.minutes) minutes of focus. Take a break."
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
