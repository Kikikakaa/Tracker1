import Foundation

func daysWord(for count: Int) -> String {
    let format = NSLocalizedString("day_count", comment: "")
    return String.localizedStringWithFormat(format, count)
}
