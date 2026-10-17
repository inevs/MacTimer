import Carbon.HIToolbox

/// Globales Tastenkürzel über Carbon. Benötigt keine Bedienungshilfen-Berechtigung.
@MainActor
final class HotKey {
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    init(keyCode: Int, modifiers: Int, action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            // Carbon liefert Hotkey-Events auf dem Main Thread aus.
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &eventType, userData, &handlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D54_4D52), id: 1) // "MTMR"
        let registerStatus = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), hotKeyID,
                                                 GetApplicationEventTarget(), 0, &hotKeyRef)

        if handlerStatus != noErr || registerStatus != noErr {
            NSLog("MacTimer: Hotkey konnte nicht registriert werden (%d/%d)", handlerStatus, registerStatus)
        }
    }
}
