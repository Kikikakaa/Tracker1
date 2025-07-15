import Foundation

final class WeekdayArrayTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let weekdays = value as? [Weekday] else { return nil }
        return try? JSONEncoder().encode(weekdays)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([Weekday].self, from: data)
    }
    
    static func register() {
        ValueTransformer.setValueTransformer(
            WeekdayArrayTransformer(),
            forName: NSValueTransformerName(rawValue: "WeekdayArrayTransformer")
        )
    }
}
