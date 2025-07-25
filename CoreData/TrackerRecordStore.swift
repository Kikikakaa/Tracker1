import CoreData

final class TrackerRecordStore {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    func addRecord(trackerId: UUID, date: Date) throws {
        // Сначала найдем TrackerCoreData по trackerId
        let trackerRequest = TrackerCoreData.fetchRequest()
        trackerRequest.predicate = NSPredicate(format: "id == %@", trackerId as CVarArg)
        
        guard let tracker = try context.fetch(trackerRequest).first else {
            throw NSError(domain: "TrackerRecordStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Tracker not found"])
        }
        
        // Проверим, что запись для этого трекера и даты еще не существует
        let existingRecordRequest = TrackerRecordCoreData.fetchRequest()
        existingRecordRequest.predicate = NSPredicate(format: "trackerId == %@ AND date == %@", trackerId as CVarArg, date as CVarArg)
        
        if let existingRecord = try context.fetch(existingRecordRequest).first {
            print("⚠️ Запись для трекера \(trackerId) на дату \(date) уже существует")
            return
        }
        
        // Создаем новую запись
        let record = TrackerRecordCoreData(context: context)
        record.id = UUID()
        record.trackerId = trackerId
        record.date = date
        record.tracker = tracker  // Устанавливаем связь с TrackerCoreData
        
        try context.save()
        print("✅ Запись успешно сохранена для трекера \(trackerId)")
    }
    
    func fetchRecords(for trackerId: UUID) throws -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
        let records = try context.fetch(request)
        return records.compactMap { record in
            guard let date = record.date else { return nil }
            return TrackerRecord(id: record.id ?? UUID(), trackerId: record.trackerId ?? UUID(), date: date)
        }
    }
    
    func fetchAllRecords() throws -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        let records = try context.fetch(request)
        return records.compactMap { record in
            guard let id = record.id,
                  let trackerId = record.trackerId,
                  let date = record.date else {
                return nil
            }
            return TrackerRecord(id: id, trackerId: trackerId, date: date)
        }
    }
    
    func deleteRecord(trackerId: UUID, date: Date) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@ AND date >= %@ AND date < %@",
                                        trackerId as CVarArg,
                                        startOfDay as CVarArg,
                                        endOfDay as CVarArg)
        
        let records = try context.fetch(request)
        for record in records {
            context.delete(record)
        }
        
        if !records.isEmpty {
            try context.save()
            print("✅ Удалено \(records.count) записей для трекера \(trackerId) на дату \(date)")
        } else {
            print("⚠️ Записи для трекера \(trackerId) на дату \(date) не найдены")
        }
    }
    
    func deleteAllRecords(for trackerId: UUID) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
        
        let records = try context.fetch(request)
        for record in records {
            context.delete(record)
        }
        
        if !records.isEmpty {
            try context.save()
            print("✅ Удалено \(records.count) записей для трекера \(trackerId)")
        }
    }
    
    func countRecords(for trackerId: UUID) throws -> Int {
        let request = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "trackerId == %@", trackerId as CVarArg)
        return try context.count(for: request)
    }
}
