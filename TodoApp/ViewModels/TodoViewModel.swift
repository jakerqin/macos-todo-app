import Combine
import CoreData
import Foundation

@MainActor
final class TodoViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private var lastGeneratedID: Int64 = 0

    @Published private(set) var lastSaveError: Error?

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func addCategory(name: String, after lastOrder: Int16) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let category = Category(context: context)
        category.id = makeID()
        category.name = trimmedName
        category.displayOrder = lastOrder + 1
        category.createdAt = Date()

        save()
    }

    func renameCategory(_ category: Category, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        category.name = trimmedName
        save()
    }

    func deleteCategory(_ category: Category) {
        context.delete(category)
        save()
    }

    func reorderCategories(_ categories: [Category]) {
        for (index, category) in categories.enumerated() {
            category.displayOrder = Int16(index)
        }

        save()
    }

    func addTodo(title: String, priority: Int16, dueDate: Date?, to category: Category) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let item = TodoItem(context: context)
        item.id = makeID()
        item.title = trimmedTitle
        item.isCompleted = false
        item.priority = priority
        item.dueDate = dueDate
        item.createdAt = Date()
        item.category = category

        save()
    }

    func toggleComplete(_ item: TodoItem) {
        item.isCompleted.toggle()
        save()
    }

    func updateTodo(_ item: TodoItem, title: String, priority: Int16, dueDate: Date?) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        item.title = trimmedTitle
        item.priority = priority
        item.dueDate = dueDate

        save()
    }

    func deleteTodo(_ item: TodoItem) {
        context.delete(item)
        save()
    }

    private func makeID() -> Int64 {
        let currentMilliseconds = Int64(Date().timeIntervalSince1970 * 1000)
        let id = max(currentMilliseconds, lastGeneratedID + 1)
        lastGeneratedID = id
        return id
    }

    private func save() -> Bool {
        guard context.hasChanges else {
            lastSaveError = nil
            return true
        }

        do {
            try context.save()
            lastSaveError = nil
            return true
        } catch {
            lastSaveError = error
            context.rollback()
            assertionFailure("Unable to save Core Data context: \(error)")
            return false
        }
    }
}
