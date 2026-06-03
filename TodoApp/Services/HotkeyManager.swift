import AppKit
import HotKey

final class HotkeyManager {
    static let shared = HotkeyManager()

    var onActivate: (() -> Void)?

    private var hotKey: HotKey?

    private init() {}

    func register() {
        unregister()

        hotKey = HotKey(key: .t, modifiers: [.command, .shift])
        hotKey?.keyDownHandler = { [weak self] in
            self?.onActivate?()
        }
    }

    func unregister() {
        hotKey = nil
    }
}
