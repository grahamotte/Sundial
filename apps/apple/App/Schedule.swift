import Foundation

enum Schedule: Codable, Hashable {
    case interval(minutes: Int)
    case daily(hour: Int, minute: Int)
    case weekly(weekdays: [Int], hour: Int, minute: Int)

    static let intervalOptions = [1, 5, 10, 15, 30, 60, 120, 180, 240, 360, 480, 720]

    var isValid: Bool {
        switch self {
        case .interval(let minutes):
            return Schedule.intervalOptions.contains(minutes)
        case .daily(let hour, let minute):
            return Schedule.isValidTime(hour: hour, minute: minute)
        case .weekly(let weekdays, let hour, let minute):
            return !weekdays.isEmpty && weekdays.allSatisfy { (1...7).contains($0) } && Schedule.isValidTime(hour: hour, minute: minute)
        }
    }

    var calendarIntervals: [DateComponents] {
        switch self {
        case .interval(let minutes) where minutes < 60:
            if minutes == 1 { return [DateComponents()] }
            return stride(from: 0, to: 60, by: minutes).map { DateComponents(minute: $0) }
        case .interval(let minutes):
            if minutes == 60 { return [DateComponents(minute: 0)] }
            return stride(from: 0, to: 24, by: minutes / 60).map { DateComponents(hour: $0, minute: 0) }
        case .daily(let hour, let minute):
            return [DateComponents(hour: hour, minute: minute)]
        case .weekly(let weekdays, let hour, let minute):
            return weekdays.sorted().map { DateComponents(hour: hour, minute: minute, weekday: $0) }
        }
    }

    var runsPerDay: Double {
        calendarIntervals.reduce(0) { total, components in
            let minutes: Double = components.minute == nil ? 60 : 1
            let hours: Double = components.hour == nil ? 24 : 1
            let days: Double = components.weekday == nil ? 1 : 1 / 7
            return total + minutes * hours * days
        }
    }

    var launchdIntervals: [[String: Int]] {
        calendarIntervals.map { components in
            var interval: [String: Int] = [:]
            if let minute = components.minute { interval["Minute"] = minute }
            if let hour = components.hour { interval["Hour"] = hour }
            if let weekday = components.weekday { interval["Weekday"] = weekday - 1 }
            return interval
        }
    }

    func nextRun(after date: Date, calendar: Calendar = .current) -> Date? {
        calendarIntervals.compactMap { components in
            var matching = components
            matching.second = 0
            return calendar.nextDate(after: date, matching: matching, matchingPolicy: .nextTime)
        }.min()
    }

    func summary(calendar: Calendar = .current, locale: Locale = .current) -> String {
        switch self {
        case .interval(let minutes):
            return Schedule.intervalLabel(minutes)
        case .daily(let hour, let minute):
            return "Daily at \(Schedule.time(hour: hour, minute: minute, calendar: calendar, locale: locale))"
        case .weekly(let weekdays, let hour, let minute):
            let time = Schedule.time(hour: hour, minute: minute, calendar: calendar, locale: locale)
            return "\(Schedule.weekdaysLabel(weekdays, calendar: calendar, locale: locale)) at \(time)"
        }
    }

    static func intervalLabel(_ minutes: Int) -> String {
        switch minutes {
        case 1: return "Every minute"
        case ..<60: return "Every \(minutes) minutes"
        case 60: return "Every hour"
        default: return "Every \(minutes / 60) hours"
        }
    }

    static func describe(_ date: Date, now: Date = Date(), calendar: Calendar = .current, locale: Locale = .current) -> String {
        let time = Schedule.time(date, calendar: calendar, locale: locale)
        if calendar.isDate(date, inSameDayAs: now) { return "today at \(time)" }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "tomorrow at \(time)"
        }
        var style = Date.FormatStyle(locale: locale, calendar: calendar, timeZone: calendar.timeZone).weekday(.wide).month(.abbreviated).day()
        style.capitalizationContext = .middleOfSentence
        return "\(date.formatted(style)) at \(time)"
    }

    static func durationLabel(_ minutes: Int) -> String {
        switch minutes {
        case 1: return "1 minute"
        case ..<60: return "\(minutes) minutes"
        case 60: return "1 hour"
        default: return "\(minutes / 60) hours"
        }
    }

    static func weekdaysLabel(_ weekdays: [Int], calendar: Calendar, locale: Locale) -> String {
        let days = Set(weekdays)
        if days == Set(1...7) { return "Every day" }
        if days == Set(2...6) { return "Weekdays" }
        if days == [1, 7] { return "Weekends" }
        var localized = calendar
        localized.locale = locale
        let symbols = localized.shortWeekdaySymbols
        return orderedWeekdays(calendar: calendar).filter(days.contains).map { symbols[$0 - 1] }.joined(separator: ", ")
    }

    static func orderedWeekdays(calendar: Calendar) -> [Int] {
        (0..<7).map { (calendar.firstWeekday - 1 + $0) % 7 + 1 }
    }

    static func time(hour: Int, minute: Int, calendar: Calendar, locale: Locale) -> String {
        time(calendar.date(from: DateComponents(year: 2001, month: 1, day: 1, hour: hour, minute: minute)) ?? Date(), calendar: calendar, locale: locale)
    }

    static func time(_ date: Date, calendar: Calendar, locale: Locale) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, calendar: calendar, timeZone: calendar.timeZone)
        style.capitalizationContext = .middleOfSentence
        return date.formatted(style)
    }

    private static func isValidTime(hour: Int, minute: Int) -> Bool {
        (0...23).contains(hour) && (0...59).contains(minute)
    }
}
