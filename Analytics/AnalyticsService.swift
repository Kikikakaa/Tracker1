import AppMetricaCore

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Public Methods

    func trackTrackerCreated(trackerTitle: String, category: String, hasSchedule: Bool) {
        let parameters: [String: Any] = [
            "tracker_title": trackerTitle,
            "category": category,
            "has_schedule": hasSchedule,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        reportEvent(name: "tracker_created", parameters: parameters)
    }
    
    func trackTrackerCompleted(trackerId: UUID, trackerTitle: String, isCompleted: Bool, completedDaysCount: Int) {
        let parameters: [String: Any] = [
            "tracker_id": trackerId.uuidString,
            "tracker_title": trackerTitle,
            "is_completed": isCompleted,
            "completed_days_count": completedDaysCount,
            "action": isCompleted ? "complete" : "uncomplete",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        reportEvent(name: "tracker_interaction", parameters: parameters)
    }

    func trackSearch(query: String) {
        let parameters: [String: Any] = [
            "search_query": query,
            "query_length": query.count,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        reportEvent(name: "tracker_search", parameters: parameters)
    }

    func trackDateChanged(selectedDate: Date) {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let isToday = calendar.isDate(selectedDate, inSameDayAs: Date())
        let isWeekend = weekday == 1 || weekday == 7 // Воскресенье или суббота
        
        let parameters: [String: Any] = [
            "selected_date": selectedDate.timeIntervalSince1970,
            "weekday": weekday,
            "is_today": isToday,
            "is_weekend": isWeekend,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        reportEvent(name: "date_changed", parameters: parameters)
    }
    // Отслеживание открытия экрана
        func trackScreenOpen(screen: AnalyticsScreen) {
            let parameters: [String: Any] = [
                Parameters.event: Events.open,
                Parameters.screen: screen.rawValue
            ]
            
            reportEvent(name: Events.screenEvent, parameters: parameters)
        }
        
        /// Отслеживание закрытия экрана
        func trackScreenClose(screen: AnalyticsScreen) {
            let parameters: [String: Any] = [
                Parameters.event: Events.close,
                Parameters.screen: screen.rawValue
            ]
            
            reportEvent(name: Events.screenEvent, parameters: parameters)
        }
        
        /// Отслеживание тапа на кнопку
        func trackButtonClick(screen: AnalyticsScreen, item: AnalyticsItem) {
            let parameters: [String: Any] = [
                Parameters.event: Events.click,
                Parameters.screen: screen.rawValue,
                Parameters.item: item.rawValue
            ]
            
            reportEvent(name: Events.screenEvent, parameters: parameters)
        }
    // MARK: - Private Methods
    
    private func reportEvent(name: String, parameters: [String: Any]) {
        #if DEBUG
        print("📊 Analytics Event: \(name)")
        print("📊 Parameters: \(parameters)")
        #endif
        
        AppMetrica.reportEvent(name: name, parameters: parameters, onFailure: { error in
            print("❌ AppMetrica error: \(error.localizedDescription)")
        })
    }
    
    private func reportEvent(name: String) {
        #if DEBUG
        print("📊 Analytics Event: \(name)")
        #endif
        
        AppMetrica.reportEvent(name: name, onFailure: { error in
            print("❌ AppMetrica error: \(error.localizedDescription)")
        })
    }
}

// MARK: - Analytics Enums

enum AnalyticsScreen: String {
    case main = "Main"
}

enum AnalyticsItem: String {
    case addTrack = "add_track"
    case track = "track"
    case filter = "filter"
    case edit = "edit"
    case delete = "delete"
}

// MARK: - Constants

extension AnalyticsService {
    private enum Events {
        static let trackerCreated = "tracker_created"
        static let trackerInteraction = "tracker_interaction"
        static let trackerSearch = "tracker_search"
        static let dateChanged = "date_changed"
        static let screenEvent = "screen_event"
        static let open = "open"
        static let close = "close"
        static let click = "click"
    }
    
    private enum Parameters {
        static let trackerTitle = "tracker_title"
        static let trackerId = "tracker_id"
        static let category = "category"
        static let hasSchedule = "has_schedule"
        static let isCompleted = "is_completed"
        static let completedDaysCount = "completed_days_count"
        static let action = "action"
        static let searchQuery = "search_query"
        static let queryLength = "query_length"
        static let selectedDate = "selected_date"
        static let weekday = "weekday"
        static let isToday = "is_today"
        static let isWeekend = "is_weekend"
        static let timestamp = "timestamp"
        static let event = "event"
        static let screen = "screen"
        static let item = "item"
    }
}
