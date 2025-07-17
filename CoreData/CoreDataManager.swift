import CoreData

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TrackerCatalog")
        container.loadPersistentStores { (storeDescriprion, error) in
            if let error = error {
                print("❌ Core Data error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            assertionFailure("Unresolved error \(nserror), \(nserror.userInfo)")
            context.rollback()
        }
    }
}
