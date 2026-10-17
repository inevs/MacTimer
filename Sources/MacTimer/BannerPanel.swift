import AppKit
import SwiftUI

/// Rahmenloses, halbtransparentes Overlay, das auch über Vollbild-Präsentationen liegt
/// und PowerPoint nicht den Fokus nimmt.
final class BannerPanel: NSPanel {
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 560, height: 150),
                   styleMask: [.borderless, .nonactivatingPanel, .resizable],
                   backing: .buffered,
                   defer: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        minSize = NSSize(width: 220, height: 70)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Reagiert schon auf den ersten Klick, obwohl das Panel nie aktiv wird.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
final class BannerController {
    private static let autosaveName = "MacTimerBanner"

    var onClose: (() -> Void)?

    private let panel = BannerPanel()
    private var moveStart: (mouse: NSPoint, origin: NSPoint)?
    private var resizeStart: (mouse: NSPoint, frame: NSRect)?

    init(model: TimerModel) {
        let view = BannerView(
            model: model,
            onClose: { [weak self] in self?.onClose?() },
            onMove: { [weak self] in self?.move() },
            onResize: { [weak self] in self?.resize() },
            onGestureEnded: { [weak self] in self?.endGesture() }
        )
        panel.contentView = FirstMouseHostingView(rootView: view)

        let restored = panel.setFrameUsingName(Self.autosaveName)
        panel.setFrameAutosaveName(Self.autosaveName)
        if !restored { resetPosition() }
    }

    func show() {
        if !isOnScreen { resetPosition() }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    /// Breiter Banner oben mittig auf dem Hauptbildschirm.
    func resetPosition() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let size = NSSize(width: min(560, visible.width - 40), height: 150)
        let origin = NSPoint(x: visible.midX - size.width / 2, y: visible.maxY - size.height - 20)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private var isOnScreen: Bool {
        NSScreen.screens.contains { $0.visibleFrame.intersects(panel.frame) }
    }

    // Verschieben und Skalieren über die absolute Mausposition, da sich das Fenster
    // unter dem Cursor mitbewegt und lokale Koordinaten dadurch unbrauchbar sind.

    private func move() {
        let mouse = NSEvent.mouseLocation
        let start = moveStart ?? (mouse, panel.frame.origin)
        moveStart = start
        panel.setFrameOrigin(NSPoint(x: start.origin.x + mouse.x - start.mouse.x,
                                     y: start.origin.y + mouse.y - start.mouse.y))
    }

    /// Griff unten rechts: die linke obere Ecke bleibt fix.
    private func resize() {
        let mouse = NSEvent.mouseLocation
        let start = resizeStart ?? (mouse, panel.frame)
        resizeStart = start
        let width = max(panel.minSize.width, start.frame.width + mouse.x - start.mouse.x)
        let height = max(panel.minSize.height, start.frame.height - (mouse.y - start.mouse.y))
        panel.setFrame(NSRect(x: start.frame.minX, y: start.frame.maxY - height, width: width, height: height),
                       display: true)
    }

    private func endGesture() {
        moveStart = nil
        resizeStart = nil
    }
}
