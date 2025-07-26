import Foundation

struct StatisticsCalculator {
    static func calculate(
        groupedRecords: [Date: [TrackerRecord]],
        allTrackers: [Tracker]
    ) -> (bestStreak: Int, perfectDays: Int, totalCompleted: Int, averagePerDay: Int) {
        
        var bestStreak = 0
        var currentStreak = 0
        var lastDate: Date?

        let sortedDates = groupedRecords.keys.sorted()
        
        for date in sortedDates {
            if let prev = lastDate,
               Calendar.current.date(byAdding: .day, value: 1, to: prev) == date {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            bestStreak = max(bestStreak, currentStreak)
            lastDate = date
        }

        var perfectDays = 0
        
        for (date, dayRecords) in groupedRecords {
            guard let weekday = Weekday(rawValue: Calendar.current.component(.weekday, from: date)) else { continue }
            
            let expectedTrackers = allTrackers.filter { tracker in
                
                guard let schedule = tracker.schedule, !schedule.isEmpty else {
                   
                    return true
                }
                return schedule.contains(weekday)
            }

            let completedIDs = Set(dayRecords.map(\.trackerId))
            let expectedIDs = Set(expectedTrackers.map(\.id))
            
            if !expectedIDs.isEmpty && expectedIDs.isSubset(of: completedIDs) {
                perfectDays += 1
            }
        }

        let totalCompleted = groupedRecords.values.reduce(0) { $0 + $1.count }
        let averagePerDay = groupedRecords.isEmpty ? 0 : totalCompleted / groupedRecords.count

        return (bestStreak, perfectDays, totalCompleted, averagePerDay)
    }
}
