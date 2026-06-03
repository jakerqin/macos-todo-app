import SwiftUI
import CoreData

@MainActor
struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.displayOrder)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    @StateObject private var vm: TodoViewModel
    @State private var selectedCategory: Category?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _vm = StateObject(wrappedValue: TodoViewModel(context: context))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(vm: vm, selectedCategory: $selectedCategory)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            if let category = selectedCategory {
                TodoListView(category: category, vm: vm)
            } else {
                ContentUnavailableView("选择一个分类", systemImage: "list.bullet")
            }
        }
        .frame(minWidth: 720, minHeight: 480)
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = categories.first
            }
        }
    }
}
