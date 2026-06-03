import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TodoApp")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)

        category.setValue(Int64(Date().timeIntervalSince1970 * 1000), forKey: "id")
        category.setValue("工作", forKey: "name")
        category.setValue(Int16(0), forKey: "displayOrder")
        category.setValue(Date(), forKey: "createdAt")

        do {
            try context.save()
        } catch {
            fatalError("Unable to create preview Core Data sample: \(error)")
        }

        return controller
    }()
}
