import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct MacTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuContent(controller: appDelegate.controller)
        } label: {
            MenuBarLabel(model: appDelegate.controller.model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller.registerHotKey()
    }
}

/// Verbindet Timer, Banner, Schnellstart, Hotkey und Gong.
@MainActor
final class AppController {
    let model = TimerModel()
    let gong = GongPlayer()

    private let banner: BannerController
    private let quickStart = QuickStartController()
    private var hotKey: HotKey?

    init() {
        banner = BannerController(model: model)
        banner.onClose = { [weak self] in self?.stop() }
        quickStart.onStart = { [weak self] duration in self?.start(duration: duration) }
        model.onFinish = { [weak self] in self?.gong.play() }
    }

    /// ⌃⌥T öffnet das Eingabefenster.
    func registerHotKey() {
        hotKey = HotKey(keyCode: kVK_ANSI_T, modifiers: controlKey | optionKey) { [weak self] in
            self?.quickStart.toggle()
        }
    }

    func start(duration: TimeInterval) {
        model.start(duration: duration)
        banner.show()
    }

    func stop() {
        model.stop()
        banner.hide()
    }

    func showQuickStart() {
        quickStart.show()
    }

    func resetBannerPosition() {
        banner.resetPosition()
    }
}

private struct MenuBarLabel: View {
    let model: TimerModel

    var body: some View {
        if model.state == .running {
            Text(model.displayText).monospacedDigit()
        } else {
            Image(systemName: "timer")
        }
    }
}

private struct MenuContent: View {
    let controller: AppController

    private static let presets = [5, 10, 15, 20, 30]

    var body: some View {
        ForEach(Self.presets, id: \.self) { minutes in
            Button("\(minutes) Minuten") { controller.start(duration: TimeInterval(minutes * 60)) }
        }
        Button("Eigene Dauer …  (⌃⌥T)") { controller.showQuickStart() }

        if controller.model.state != .idle {
            Divider()
            Button("+1 Minute") { controller.model.adjust(by: 60) }
            Button("−1 Minute") { controller.model.adjust(by: -60) }
                .disabled(controller.model.state != .running)
            Button("Timer beenden") { controller.stop() }
        }

        Divider()
        Button("Banner-Position zurücksetzen") { controller.resetBannerPosition() }
        Button("Gong-Datei wählen …") { controller.gong.chooseFile() }
        Button("Gong testen") { controller.gong.play() }

        Divider()
        Button("MacTimer beenden") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}
