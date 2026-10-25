import Foundation
@testable import SundialCore

func makeTemporaryDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "SundialTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

func utcCalendar(firstWeekday: Int = 1) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    calendar.locale = Locale(identifier: "en_US")
    calendar.firstWeekday = firstWeekday
    return calendar
}

func utcDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
    utcCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}

final class RecordingCommandRunner: CommandRunning {
    var calls: [[String]] = []
    var spawned: [[String]] = []
    var results: [String: Int32] = [:]

    func run(_ executable: String, _ arguments: [String]) -> Int32 {
        calls.append([executable] + arguments)
        return results[arguments.first ?? ""] ?? 0
    }

    func spawn(_ executable: String, _ arguments: [String]) throws {
        spawned.append([executable] + arguments)
    }
}
