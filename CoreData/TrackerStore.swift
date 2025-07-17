import CoreData

protocol TrackerStoreDelegate: AnyObject {
    func didUpdateTrackers()
}

final class TrackerStore: NSObject {
    private let context: NSManagedObjectContext
    private let colorMarshalling = UIColorMarshalling()
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let request = TrackerCoreData.fetchRequest()
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
    
    weak var delegate: TrackerStoreDelegate?
    
    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        try? fetchedResultsController.performFetch()
    }
    
    // MARK: - CRUD
    func addTracker(_ tracker: Tracker) throws {
        let trackerCoreData = TrackerCoreData(context: context)
        trackerCoreData.id = tracker.id
        trackerCoreData.title = tracker.title
        trackerCoreData.emoji = tracker.emoji
        trackerCoreData.colorHex = colorMarshalling.hexString(from: tracker.color)
        trackerCoreData.createdAt = Date()
        trackerCoreData.isPinned = false
        
        // Явное преобразование расписания
        if let schedule = tracker.schedule {
            let encoder = JSONEncoder()
            do {
                let scheduleData = try encoder.encode(schedule)
                trackerCoreData.schedule = scheduleData
            } catch {
                print("Ошибка кодирования расписания: \(error)")
            }
        }
        
        // Создаем или находим категорию
        let categoryRequest: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "title == %@", "Мои трекеры")
        
        if let existingCategory = try? context.fetch(categoryRequest).first {
            trackerCoreData.category = existingCategory
        } else {
            let newCategory = TrackerCategoryCoreData(context: context)
            newCategory.id = UUID()
            newCategory.title = "Мои трекеры"
            trackerCoreData.category = newCategory
        }
        
        try context.save()
    }
    
    func fetchTrackers() throws -> [Tracker] {
        let request = TrackerCoreData.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        let trackersCoreData = try context.fetch(request)
        
        return trackersCoreData.compactMap { coreData in
            guard let id = coreData.id,
                  let title = coreData.title,
                  let emoji = coreData.emoji,
                  let colorHex = coreData.colorHex else {
                return nil
            }
            
            let schedule: [Weekday]?
            if let scheduleData = coreData.schedule {
                schedule = try? JSONDecoder().decode([Weekday].self, from: scheduleData)
            } else {
                schedule = nil
            }
            
            return Tracker(
                id: id,
                title: title,
                color: colorMarshalling.color(from: colorHex),
                emoji: emoji,
                schedule: schedule
            )
        }
    }
    
    func updateTracker(_ tracker: Tracker) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        if let trackerCoreData = try context.fetch(request).first {
            trackerCoreData.title = tracker.title
            trackerCoreData.emoji = tracker.emoji
            trackerCoreData.colorHex = colorMarshalling.hexString(from: tracker.color)
            
            if let schedule = tracker.schedule {
                let scheduleData = try? JSONEncoder().encode(schedule)
                trackerCoreData.schedule = scheduleData ?? Data()
            } else {
                trackerCoreData.schedule = Data()
            }
            
            try context.save()
        }
    }
    
    func deleteTracker(_ id: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let tracker = try context.fetch(request).first {
            context.delete(tracker)
            try context.save()
        }
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdateTrackers()
    }
}

extension TrackerCoreData {
    func toTracker() -> Tracker? {
        guard let id = id,
              let title = title,
              let emoji = emoji,
              let colorHex = colorHex else {
            return nil
        }
        
        let schedule: [Weekday]?
        if let scheduleData = self.schedule as? Data {
            schedule = try? JSONDecoder().decode([Weekday].self, from: scheduleData)
        } else {
            schedule = nil
        }
        
        return Tracker(
            id: id,
            title: title,
            color: UIColorMarshalling().color(from: colorHex),
            emoji: emoji,
            schedule: schedule
        )
    }
}
