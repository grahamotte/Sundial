import CoreGraphics
import Foundation

struct DayArc {
    let interval: DateInterval

    init(containing date: Date, calendar: Calendar = .current) {
        interval = calendar.dateInterval(of: .day, for: date) ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
    }

    func fraction(of date: Date) -> Double? {
        guard interval.contains(date), date < interval.end else { return nil }
        return date.timeIntervalSince(interval.start) / interval.duration
    }

    func runs(_ runs: [RunRecord]) -> [RunRecord] {
        runs.filter { fraction(of: $0.startedAt) != nil }.sorted { $0.startedAt < $1.startedAt }
    }

    func summary(
        _ runs: [RunRecord],
        next: Date?,
        calendar: Calendar = .current,
        locale: Locale = .current,
        isProcessAlive: (Int32) -> Bool = RunRecord.isProcessAlive
    ) -> String {
        let statuses = self.runs(runs).map { $0.status(isProcessAlive: isProcessAlive) }
        let failed = statuses.filter(\.isFailure).count
        let passed = statuses.filter { $0 == .succeeded }.count
        let running = statuses.filter { $0 == .running }.count
        var parts: [String] = []
        if passed > 0 { parts.append("\(passed) passed") }
        if failed > 0 { parts.append("\(failed) failed") }
        if running > 0 { parts.append("\(running) running") }
        var text = parts.isEmpty ? "No runs today" : parts.joined(separator: ", ")
        if let next, fraction(of: next) != nil {
            text += ". Next run at \(Schedule.time(next, calendar: calendar, locale: locale))"
        }
        return text + "."
    }

    static func altitude(at fraction: Double) -> Double {
        -cos(2 * .pi * fraction)
    }

    static func point(at fraction: Double, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * fraction, y: rect.midY - rect.height / 2 * altitude(at: fraction))
    }
}
