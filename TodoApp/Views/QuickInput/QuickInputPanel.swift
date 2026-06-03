import AppKit
import SwiftUI

@MainActor
final class QuickInputPanel: NSPanel {
    static let shared = QuickInputPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        hasShadow = true
        backgroundColor = .clear
        hidesOnDeactivate = true

        let context = PersistenceController.shared.container.viewContext
        let rootView = QuickInputView { [weak self] in
            self?.close()
        }
        .environment(\.managedObjectContext, context)

        contentView = NSHostingView(rootView: rootView)
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    func toggle() {
        if isVisible {
            close()
        } else {
            positionNearTop()
            NSApp.activate(ignoringOtherApps: true)
            makeKeyAndOrderFront(nil)
        }
    }

    private func positionNearTop() {
        guard let screen = screen ?? NSScreen.main ?? NSScreen.screens.first else {
            center()
            return
        }

        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.midX - frame.width / 2
        let y = visibleFrame.minY + visibleFrame.height * 0.65
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
