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
    func addTracker(_ tracker: Tracker, category: TrackerCategoryCoreData?) throws {
        // Проверяем, не существует ли уже трекер с таким ID
        let existingRequest = TrackerCoreData.fetchRequest()
        existingRequest.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        if let existingTracker = try context.fetch(existingRequest).first {
            print("⚠️ Трекер с ID \(tracker.id) уже существует, обновляем вместо создания")
            // Обновляем существующий трекер
            existingTracker.title = tracker.title
            existingTracker.emoji = tracker.emoji
            existingTracker.colorHex = colorMarshalling.hexString(from: tracker.color)
            existingTracker.category = category
            
            if let schedule = tracker.schedule {
                let encoder = JSONEncoder()
                do {
                    let scheduleData = try encoder.encode(schedule)
                    existingTracker.schedule = scheduleData
                } catch {
                    print("Ошибка кодирования расписания: \(error)")
                }
            }
            
            try context.save()
            return
        }
        
        // Создаем новый трекер только если его еще нет
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
        
        trackerCoreData.category = category
        
        try context.save()
        print("✅ Создан новый трекер с ID \(tracker.id)")
    }
    
    func fetchTrackers() throws -> [Tracker] {
        let request = TrackerCoreData.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        let trackersCoreData = try context.fetch(request)
        
        // Убираем дубликаты на уровне загрузки как дополнительная защита
        var uniqueTrackers: [Tracker] = []
        var seenIds: Set<UUID> = []
        
        for coreData in trackersCoreData {
            guard let id = coreData.id,
                  let title = coreData.title,
                  let emoji = coreData.emoji,
                  let colorHex = coreData.colorHex else {
                continue
            }
            
            // Пропускаем дубликаты
            if seenIds.contains(id) {
                print("⚠️ Найден дублированный трекер в Core Data с ID \(id), удаляем")
                context.delete(coreData)
                continue
            }
            seenIds.insert(id)
            
            let schedule: [Weekday]?
            if let scheduleData = coreData.schedule {
                schedule = try? JSONDecoder().decode([Weekday].self, from: scheduleData)
            } else {
                schedule = nil
            }
            
            let tracker = Tracker(
                id: id,
                title: title,
                color: colorMarshalling.color(from: colorHex),
                emoji: emoji,
                schedule: schedule
            )
            uniqueTrackers.append(tracker)
        }
        
        // Сохраняем изменения если удалили дубликаты
        if context.hasChanges {
            try context.save()
        }
        
        return uniqueTrackers
    }
    
    func updateTracker(_ tracker: Tracker, in category: TrackerCategoryCoreData?) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tracker.id as CVarArg)
        
        // Проверяем, что обновляем именно один трекер
        let existingTrackers = try context.fetch(request)
        
        if existingTrackers.count > 1 {
            print("⚠️ Найдено \(existingTrackers.count) трекеров с ID \(tracker.id), удаляем дубликаты")
            // Удаляем все дубликаты кроме первого
            for i in 1..<existingTrackers.count {
                context.delete(existingTrackers[i])
            }
        }
        
        if let trackerCoreData = existingTrackers.first {
            trackerCoreData.title = tracker.title
            trackerCoreData.emoji = tracker.emoji
            trackerCoreData.colorHex = colorMarshalling.hexString(from: tracker.color)
            
            if let schedule = tracker.schedule {
                let scheduleData = try? JSONEncoder().encode(schedule)
                trackerCoreData.schedule = scheduleData ?? Data()
            } else {
                trackerCoreData.schedule = Data()
            }
            
            trackerCoreData.category = category
            
            try context.save()
            print("✅ Обновлен трекер с ID \(tracker.id)")
        } else {
            print("⚠️ Трекер с ID \(tracker.id) не найден для обновления")
        }
    }
    
    func deleteTracker(_ id: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let trackers = try context.fetch(request)
        
        if trackers.count > 1 {
            print("⚠️ Найдено \(trackers.count) трекеров с ID \(id) для удаления")
        }
        
        // Удаляем все найденные трекеры с этим ID
        for tracker in trackers {
            context.delete(tracker)
        }
        
        if !trackers.isEmpty {
            try context.save()
            print("✅ Удалено \(trackers.count) трекеров с ID \(id)")
        }
    }
    
    func cleanupDuplicates() throws {
        let request = TrackerCoreData.fetchRequest()
        let allTrackers = try context.fetch(request)
        
        var seenIds: Set<UUID> = []
        var duplicates: [TrackerCoreData] = []
        
        for tracker in allTrackers {
            guard let id = tracker.id else { continue }
            
            if seenIds.contains(id) {
                duplicates.append(tracker)
            } else {
                seenIds.insert(id)
            }
        }
        
        if !duplicates.isEmpty {
            print("🧹 Очистка \(duplicates.count) дубликатов трекеров")
            for duplicate in duplicates {
                context.delete(duplicate)
            }
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
