import AppKit
import AVFoundation
import UniformTypeIdentifiers

/// Spielt den Gong. Reihenfolge: vom Nutzer gewählte Datei, `gong.*` im App-Bundle, Systemsound „Glass".
@MainActor
final class GongPlayer {
    private static let customPathKey = "gongFilePath"
    private static let bundledExtensions = ["mp3", "wav", "m4a", "aiff", "caf"]

    private var player: AVAudioPlayer?

    var soundURL: URL? {
        if let path = UserDefaults.standard.string(forKey: Self.customPathKey),
           FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return Self.bundledExtensions.lazy
            .compactMap { Bundle.main.url(forResource: "gong", withExtension: $0) }
            .first
    }

    func play() {
        if let url = soundURL, let player = try? AVAudioPlayer(contentsOf: url) {
            self.player = player
            player.play()
        } else {
            NSSound(named: "Glass")?.play()
        }
    }

    func chooseFile() {
        let panel = NSOpenPanel()
        panel.title = "Gong-Datei wählen"
        panel.allowedContentTypes = [.audio]
        panel.allowsMultipleSelection = false
        NSApp.activate()
        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: Self.customPathKey)
        }
    }
}
