import XCTest
@testable import SundialCore

final class RunDayTests: XCTestCase {
    private let calendar = utcCalendar()

    private func run(_ id: String, _ date: Date) -> RunRecord {
        RunRecord(id: id, jobID: UUID(), jobName: "Job", command: "true", startedAt: date, processID: 1)
    }

    func testGroupsByDayNewestFirst() {
        let days = RunDay.group([
            run("a", utcDate(2026, 10, 24, 8)),
            run("b", utcDate(2026, 10, 25, 1)),
            run("c", utcDate(2026, 10, 25, 23)),
        ], calendar: calendar)
        XCTAssertEqual(days.map(\.day), [utcDate(2026, 10, 25), utcDate(2026, 10, 24)])
        XCTAssertEqual(days.map { $0.runs.map(\.id) }, [["c", "b"], ["a"]])
    }

    func testTitles() {
        let now = utcDate(2026, 10, 25, 12)
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(RunDay(day: utcDate(2026, 10, 25), runs: []).title(now: now, calendar: calendar, locale: locale), "Today")
        XCTAssertEqual(RunDay(day: utcDate(2026, 10, 24), runs: []).title(now: now, calendar: calendar, locale: locale), "Yesterday")
        XCTAssertEqual(RunDay(day: utcDate(2026, 10, 20), runs: []).title(now: now, calendar: calendar, locale: locale), "Tuesday, Oct 20")
    }
}
