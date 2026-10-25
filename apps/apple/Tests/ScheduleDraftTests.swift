import XCTest
@testable import SundialCore

final class ScheduleDraftTests: XCTestCase {
    func testDefaults() {
        let draft = ScheduleDraft()
        XCTAssertEqual(draft.schedule, .interval(minutes: 60))
    }

    func testRoundTripsEverySchedule() {
        let schedules: [Schedule] = [.interval(minutes: 15), .daily(hour: 6, minute: 45), .weekly(weekdays: [1, 4], hour: 22, minute: 10)]
        for schedule in schedules {
            XCTAssertEqual(ScheduleDraft(schedule).schedule, schedule)
        }
    }

    func testSwitchingKindKeepsOtherSettings() {
        var draft = ScheduleDraft(.daily(hour: 6, minute: 45))
        draft.kind = .weekly
        XCTAssertEqual(draft.schedule, .weekly(weekdays: [2, 3, 4, 5, 6], hour: 6, minute: 45))
        draft.kind = .interval
        XCTAssertEqual(draft.schedule, .interval(minutes: 60))
    }

    func testTime() {
        let calendar = utcCalendar()
        var draft = ScheduleDraft(.daily(hour: 6, minute: 45))
        let reference = utcDate(2026, 10, 25, 12, 0)
        XCTAssertEqual(draft.time(calendar: calendar, reference: reference), utcDate(2026, 10, 25, 6, 45))
        draft.setTime(utcDate(2026, 1, 1, 18, 20), calendar: calendar)
        XCTAssertEqual(draft.schedule, .daily(hour: 18, minute: 20))
    }

    func testToggleWeekday() {
        var draft = ScheduleDraft(.weekly(weekdays: [2], hour: 9, minute: 0))
        draft.toggle(weekday: 3)
        draft.toggle(weekday: 2)
        XCTAssertEqual(draft.schedule, .weekly(weekdays: [3], hour: 9, minute: 0))
        draft.toggle(weekday: 3)
        XCTAssertFalse(draft.schedule.isValid)
    }
}
