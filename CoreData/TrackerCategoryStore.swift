import CoreData

protocol TrackerCategoryStoreDelegate: AnyObject {
    func didUpdateCategories()
}

final class TrackerCategoryStore: NSObject {
    private let context: NSManagedObjectContext
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()
    
    weak var delegate: TrackerCategoryStoreDelegate?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        try? fetchedResultsController.performFetch()
    }
    
    func addCategory(_ title: String) throws -> TrackerCategoryCoreData {
        let category = TrackerCategoryCoreData(context: context)
        category.id = UUID()
        category.title = title
        try context.save()
        return category
    }
    
    func fetchCategory(for trackerId: UUID) throws -> TrackerCategoryCoreData? {
        let request = TrackerCategoryCoreData.fetchRequest()
        let categories = try context.fetch(request)
        
        for category in categories {
            if let trackers = category.trackers?.allObjects as? [TrackerCoreData],
               trackers.contains(where: { $0.id == trackerId }) {
                return category
            }
        }
        return nil
    }
    
    func fetchAllCategories() throws -> [TrackerCategory] {
          let request = TrackerCategoryCoreData.fetchRequest()
          let categories = try context.fetch(request)
          return categories.compactMap { category in
              guard let id = category.id, let title = category.title else { return nil }
              let trackers = (category.trackers?.allObjects as? [TrackerCoreData])?.compactMap { $0.toTracker() } ?? []
              return TrackerCategory(id: id, title: title, trackers: trackers)
          }
      }
      
      func deleteCategory(_ id: UUID) throws {
          let request = TrackerCategoryCoreData.fetchRequest()
          request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
          
          if let category = try context.fetch(request).first {
              context.delete(category)
              try context.save()
          }
      }
  }

  extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
      func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
          delegate?.didUpdateCategories()
      }
  }
