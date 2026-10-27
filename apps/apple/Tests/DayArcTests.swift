import XCTest
@testable import SundialCore

final class DayArcTests: XCTestCase {
    private let calendar = utcCalendar()
    private let locale = Locale(identifier: "en_US")

    private func run(_ id: String, _ date: Date, exitCode: Int32? = 0, finished: Bool = true) -> RunRecord {
        RunRecord(id: id, jobID: UUID(), jobName: "Job", command: "true", startedAt: date, finishedAt: finished ? date.addingTimeInterval(5) : nil, exitCode: exitCode, processID: 7)
    }

    func testFractionWithinDay() {
        let arc = DayArc(containing: utcDate(2026, 10, 25, 15), calendar: calendar)
        XCTAssertEqual(arc.fraction(of: utcDate(2026, 10, 25)), 0)
        XCTAssertEqual(arc.fraction(of: utcDate(2026, 10, 25, 6)), 0.25)
        XCTAssertEqual(arc.fraction(of: utcDate(2026, 10, 25, 18)), 0.75)
        XCTAssertNil(arc.fraction(of: utcDate(2026, 10, 26)))
        XCTAssertNil(arc.fraction(of: utcDate(2026, 10, 24, 23, 59)))
    }

    func testFractionAcrossDaylightSavingChange() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        let arc = DayArc(containing: start, calendar: calendar)
        XCTAssertEqual(arc.interval.duration, 25 * 3600)
        XCTAssertEqual(arc.fraction(of: start.addingTimeInterval(12.5 * 3600))!, 0.5, accuracy: 1e-9)
    }

    func testRunsKeepsTheDayOldestFirst() {
        let arc = DayArc(containing: utcDate(2026, 10, 25, 12), calendar: calendar)
        let runs = [
            run("late", utcDate(2026, 10, 25, 20)),
            run("yesterday", utcDate(2026, 10, 24, 20)),
            run("early", utcDate(2026, 10, 25, 1)),
            run("tomorrow", utcDate(2026, 10, 26, 1)),
        ]
        XCTAssertEqual(arc.runs(runs).map(\.id), ["early", "late"])
    }

    func testSummaryCountsTodaysRunsAndNextRun() {
        let arc = DayArc(containing: utcDate(2026, 10, 25, 12), calendar: calendar)
        let runs = [
            run("a", utcDate(2026, 10, 25, 1)),
            run("b", utcDate(2026, 10, 25, 2)),
            run("c", utcDate(2026, 10, 25, 3), exitCode: 1),
            run("d", utcDate(2026, 10, 25, 4), exitCode: nil, finished: false),
            run("e", utcDate(2026, 10, 24, 4), exitCode: 1),
        ]
        XCTAssertEqual(
            normalized(arc.summary(runs, next: utcDate(2026, 10, 25, 18), calendar: calendar, locale: locale, isProcessAlive: { _ in true })),
            "2 passed, 1 failed, 1 running. Next run at 6:00 PM."
        )
        XCTAssertEqual(
            arc.summary(runs, next: nil, calendar: calendar, locale: locale, isProcessAlive: { _ in false }),
            "2 passed, 2 failed."
        )
    }

    func testSummaryWithoutRunsOmitsNextRunOutsideTheDay() {
        let arc = DayArc(containing: utcDate(2026, 10, 25, 12), calendar: calendar)
        XCTAssertEqual(arc.summary([], next: utcDate(2026, 10, 26, 6), calendar: calendar, locale: locale), "No runs today.")
        XCTAssertEqual(normalized(arc.summary([], next: utcDate(2026, 10, 25, 23, 30), calendar: calendar, locale: locale)), "No runs today. Next run at 11:30 PM.")
    }

    func testAltitudePeaksAtNoon() {
        XCTAssertEqual(DayArc.altitude(at: 0), -1, accuracy: 1e-9)
        XCTAssertEqual(DayArc.altitude(at: 0.25), 0, accuracy: 1e-9)
        XCTAssertEqual(DayArc.altitude(at: 0.5), 1, accuracy: 1e-9)
        XCTAssertEqual(DayArc.altitude(at: 0.75), 0, accuracy: 1e-9)
    }

    func testPointMapsTimeAcrossAndAltitudeUp() {
        let rect = CGRect(x: 10, y: 20, width: 200, height: 40)
        let midnight = DayArc.point(at: 0, in: rect)
        let sunrise = DayArc.point(at: 0.25, in: rect)
        let noon = DayArc.point(at: 0.5, in: rect)
        XCTAssertEqual(midnight.x, 10, accuracy: 1e-9)
        XCTAssertEqual(midnight.y, 60, accuracy: 1e-9)
        XCTAssertEqual(sunrise.x, 60, accuracy: 1e-9)
        XCTAssertEqual(sunrise.y, 40, accuracy: 1e-9)
        XCTAssertEqual(noon.x, 110, accuracy: 1e-9)
        XCTAssertEqual(noon.y, 20, accuracy: 1e-9)
    }

    private func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
