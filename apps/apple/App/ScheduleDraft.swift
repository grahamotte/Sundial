import Foundation

struct ScheduleDraft: Hashable {
    enum Kind: String, CaseIterable, Identifiable {
        case interval
        case daily
        case weekly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .interval: return "Repeatedly"
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            }
        }
    }

    var kind: Kind = .interval
    var intervalMinutes = 60
    var hour = 9
    var minute = 0
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]

    init() {}

    init(_ schedule: Schedule) {
        switch schedule {
        case .interval(let minutes):
            kind = .interval
            intervalMinutes = minutes
        case .daily(let hour, let minute):
            kind = .daily
            self.hour = hour
            self.minute = minute
        case .weekly(let weekdays, let hour, let minute):
            kind = .weekly
            self.weekdays = Set(weekdays)
            self.hour = hour
            self.minute = minute
        }
    }

    var schedule: Schedule {
        switch kind {
        case .interval: return .interval(minutes: intervalMinutes)
        case .daily: return .daily(hour: hour, minute: minute)
        case .weekly: return .weekly(weekdays: weekdays.sorted(), hour: hour, minute: minute)
        }
    }

    func time(calendar: Calendar = .current, reference: Date = Date()) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference) ?? reference
    }

    mutating func setTime(_ date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        hour = components.hour ?? hour
        minute = components.minute ?? minute
    }

    mutating func toggle(weekday: Int) {
        if weekdays.contains(weekday) {
            weekdays.remove(weekday)
        } else {
            weekdays.insert(weekday)
        }
    }
}
