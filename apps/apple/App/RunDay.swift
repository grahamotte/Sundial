import Foundation

struct RunDay: Identifiable, Hashable {
    var day: Date
    var runs: [RunRecord]

    var id: Date { day }

    func title(now: Date = Date(), calendar: Calendar = .current, locale: Locale = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(day, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide).month(.abbreviated).day()
        style.capitalizationContext = .standalone
        return day.formatted(style)
    }

    static func group(_ runs: [RunRecord], calendar: Calendar = .current) -> [RunDay] {
        Dictionary(grouping: runs) { calendar.startOfDay(for: $0.startedAt) }
            .map { RunDay(day: $0.key, runs: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { $0.day > $1.day }
    }
}
