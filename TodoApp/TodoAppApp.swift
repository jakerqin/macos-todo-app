import SwiftUI

@main
struct TodoAppApp: App {
    private let persistenceController = PersistenceController.shared

    init() {
        HotkeyManager.shared.register()
        HotkeyManager.shared.onActivate = {
            DispatchQueue.main.async {
                QuickInputPanel.shared.toggle()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
