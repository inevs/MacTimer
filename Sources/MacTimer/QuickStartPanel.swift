import AppKit
import SwiftUI

/// Eingabefenster für die Dauer. Es kann Tastatureingaben empfangen, ohne die App zu aktivieren,
/// sodass die laufende Präsentation im Vordergrund bleibt.
final class QuickStartPanel: NSPanel {
    var onCancel: (() -> Void)?

    init() {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

@MainActor
final class QuickStartController: NSObject, NSWindowDelegate {
    var onStart: ((TimeInterval) -> Void)?

    private var panel: QuickStartPanel?
    private var previousApp: NSRunningApplication?

    func toggle() {
        if panel != nil {
            close()
        } else {
            show()
        }
    }

    func show() {
        guard panel == nil else { return }
        previousApp = NSWorkspace.shared.frontmostApplication

        let panel = QuickStartPanel()
        let view = QuickStartView(
            onSubmit: { [weak self] duration in
                self?.close()
                self?.onStart?(duration)
            },
            onCancel: { [weak self] in self?.close() }
        )
        let hostingView = FirstMouseHostingView(rootView: view)
        panel.contentView = hostingView
        panel.setContentSize(hostingView.fittingSize)
        panel.onCancel = { [weak self] in self?.close() }
        panel.delegate = self

        // Auf dem Bildschirm zentrieren, auf dem sich die Maus befindet.
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2,
                                         y: frame.midY - panel.frame.height / 2))
        }

        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        guard let panel else { return }
        self.panel = nil
        panel.delegate = nil
        panel.orderOut(nil)
        if let previousApp, previousApp != NSRunningApplication.current {
            previousApp.activate()
        }
        previousApp = nil
    }

    func windowDidResignKey(_ notification: Notification) {
        close()
    }
}

struct QuickStartView: View {
    let onSubmit: (TimeInterval) -> Void
    let onCancel: () -> Void

    @State private var input = ""
    @State private var isInvalid = false
    @FocusState private var isFocused: Bool

    private static let presets = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 14) {
            Text("Übungs-Timer starten")
                .font(.headline)

            TextField("Minuten, z. B. 10 oder 7:30", text: $input)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .focused($isFocused)
                .onSubmit(submit)
                .onChange(of: input) { isInvalid = false }

            HStack(spacing: 8) {
                ForEach(Self.presets, id: \.self) { minutes in
                    Button("\(minutes) Min.") { onSubmit(TimeInterval(minutes * 60)) }
                }
            }

            Text(isInvalid ? "Bitte eine gültige Dauer eingeben" : "Enter startet · Esc bricht ab")
                .font(.caption)
                .foregroundStyle(isInvalid ? .red : .secondary)
        }
        .padding(20)
        .frame(width: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onExitCommand(perform: onCancel)
        .onAppear { isFocused = true }
    }

    private func submit() {
        if let duration = TimerModel.parseDuration(input) {
            onSubmit(duration)
        } else {
            isInvalid = true
        }
    }
}
