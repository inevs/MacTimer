// Rendert das App-Icon und erzeugt Resources/AppIcon.icns.
// Aufruf: swift scripts/make-icon.swift
import AppKit

let canvas: CGFloat = 1024
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let resources = root.appendingPathComponent("Resources")

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

func drawIcon() {
    // Grundform nach macOS-Icon-Raster: 824 × 824 auf 1024er Leinwand
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let shape = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 28
    shadow.set()
    color(0x1E2A5A).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    shape.addClip()

    // Hintergrund: "Folie" mit Verlauf Indigo → Petrol
    NSGradient(colors: [color(0x3B3F9E), color(0x2C6FB0), color(0x1FA3A8)],
               atLocations: [0, 0.55, 1], colorSpace: .sRGB)!
        .draw(in: body, angle: -60)

    // Angedeuteter Folieninhalt: Titelzeile und Stichpunkte
    color(0xFFFFFF, 0.85).setFill()
    NSBezierPath(roundedRect: NSRect(x: 190, y: 770, width: 420, height: 46), xRadius: 23, yRadius: 23).fill()
    color(0xFFFFFF, 0.35).setFill()
    for (index, width) in [560.0, 470.0].enumerated() {
        let y = 690 - CGFloat(index) * 62
        NSBezierPath(ovalIn: NSRect(x: 190, y: y + 4, width: 24, height: 24)).fill()
        NSBezierPath(roundedRect: NSRect(x: 236, y: y, width: width - 46, height: 32), xRadius: 16, yRadius: 16).fill()
    }

    // Halbtransparenter Timer-Banner
    let banner = NSRect(x: 150, y: 300, width: 724, height: 250)
    NSGraphicsContext.saveGraphicsState()
    let bannerShadow = NSShadow()
    bannerShadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    bannerShadow.shadowOffset = NSSize(width: 0, height: -10)
    bannerShadow.shadowBlurRadius = 30
    bannerShadow.set()
    color(0x0B0F1E, 0.62).setFill()
    NSBezierPath(roundedRect: banner, xRadius: 60, yRadius: 60).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Ziffern
    let font = NSFont.monospacedDigitSystemFont(ofSize: 190, weight: .bold)
    let rounded = font.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: 190) } ?? font
    let digits = NSAttributedString(string: "05:00", attributes: [
        .font: rounded,
        .foregroundColor: NSColor.white,
        .kern: 4,
    ])
    let digitsSize = digits.size()
    digits.draw(at: NSPoint(x: banner.midX - digitsSize.width / 2,
                            y: banner.midY - digitsSize.height / 2 + 18))

    // Fortschrittsbalken im Banner (Restzeit in Orange)
    let track = NSRect(x: banner.minX + 70, y: banner.minY + 38, width: banner.width - 140, height: 18)
    color(0xFFFFFF, 0.18).setFill()
    NSBezierPath(roundedRect: track, xRadius: 9, yRadius: 9).fill()
    var progress = track
    progress.size.width *= 0.62
    NSGradient(starting: color(0xFFB13B), ending: color(0xFF6A3D))!
        .draw(in: NSBezierPath(roundedRect: progress, xRadius: 9, yRadius: 9), angle: 0)

    // Gong-Scheibe mit Schallbögen links und rechts
    let gongCenter = NSPoint(x: 512, y: 190)
    NSGradient(starting: color(0xFFD27A), ending: color(0xE8902E))!
        .draw(in: NSBezierPath(ovalIn: NSRect(x: gongCenter.x - 48, y: gongCenter.y - 48, width: 96, height: 96)),
              relativeCenterPosition: NSPoint(x: -0.3, y: 0.3))
    color(0xB8641C, 0.55).setStroke()
    let boss = NSBezierPath(ovalIn: NSRect(x: gongCenter.x - 18, y: gongCenter.y - 18, width: 36, height: 36))
    boss.lineWidth = 6
    boss.stroke()
    for (index, radius) in [80.0, 112.0].enumerated() {
        color(0xFFFFFF, 0.7 - CGFloat(index) * 0.25).setStroke()
        for (start, end) in [(-35.0, 35.0), (145.0, 215.0)] {
            let arc = NSBezierPath()
            arc.appendArc(withCenter: gongCenter, radius: radius, startAngle: start, endAngle: end)
            arc.lineWidth = 13
            arc.lineCapStyle = .round
            arc.stroke()
        }
    }

    // Leichter Glanz oben
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), NSColor.white.withAlphaComponent(0)])!
        .draw(in: NSRect(x: body.minX, y: body.midY, width: body.width, height: body.height / 2), angle: -90)

    NSGraphicsContext.restoreGraphicsState()

    // Feine Kontur
    color(0xFFFFFF, 0.15).setStroke()
    shape.lineWidth = 3
    shape.stroke()
}

func render(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: canvas, height: canvas)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for base in [16, 32, 128, 256, 512] {
    try render(size: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try render(size: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try render(size: 1024).write(to: resources.appendingPathComponent("AppIcon-preview.png"))

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", resources.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "Erstellt: Resources/AppIcon.icns" : "iconutil fehlgeschlagen")
