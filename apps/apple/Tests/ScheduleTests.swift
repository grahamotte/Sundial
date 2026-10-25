import XCTest
@testable import SundialCore

final class ScheduleTests: XCTestCase {
    private let calendar = utcCalendar()
    private let locale = Locale(identifier: "en_US")

    func testValidity() {
        XCTAssertTrue(Schedule.interval(minutes: 15).isValid)
        XCTAssertFalse(Schedule.interval(minutes: 7).isValid)
        XCTAssertTrue(Schedule.daily(hour: 23, minute: 59).isValid)
        XCTAssertFalse(Schedule.daily(hour: 24, minute: 0).isValid)
        XCTAssertFalse(Schedule.daily(hour: 9, minute: 60).isValid)
        XCTAssertTrue(Schedule.weekly(weekdays: [2], hour: 9, minute: 0).isValid)
        XCTAssertFalse(Schedule.weekly(weekdays: [], hour: 9, minute: 0).isValid)
        XCTAssertFalse(Schedule.weekly(weekdays: [8], hour: 9, minute: 0).isValid)
    }

    func testEveryIntervalOptionDividesEvenly() {
        for minutes in Schedule.intervalOptions {
            if minutes < 60 {
                XCTAssertEqual(60 % minutes, 0)
            } else {
                XCTAssertEqual(minutes % 60, 0)
                XCTAssertEqual(24 % (minutes / 60), 0)
            }
        }
    }

    func testLaunchdIntervals() {
        XCTAssertEqual(Schedule.interval(minutes: 1).launchdIntervals, [[:]])
        XCTAssertEqual(Schedule.interval(minutes: 15).launchdIntervals, [["Minute": 0], ["Minute": 15], ["Minute": 30], ["Minute": 45]])
        XCTAssertEqual(Schedule.interval(minutes: 60).launchdIntervals, [["Minute": 0]])
        XCTAssertEqual(
            Schedule.interval(minutes: 360).launchdIntervals,
            [["Hour": 0, "Minute": 0], ["Hour": 6, "Minute": 0], ["Hour": 12, "Minute": 0], ["Hour": 18, "Minute": 0]]
        )
        XCTAssertEqual(Schedule.daily(hour: 7, minute: 30).launchdIntervals, [["Hour": 7, "Minute": 30]])
        XCTAssertEqual(
            Schedule.weekly(weekdays: [7, 1], hour: 9, minute: 5).launchdIntervals,
            [["Weekday": 0, "Hour": 9, "Minute": 5], ["Weekday": 6, "Hour": 9, "Minute": 5]]
        )
    }

    func testNextRun() {
        let now = utcDate(2026, 10, 25, 12, 7, 30)
        XCTAssertEqual(Schedule.interval(minutes: 1).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 25, 12, 8))
        XCTAssertEqual(Schedule.interval(minutes: 15).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 25, 12, 15))
        XCTAssertEqual(Schedule.interval(minutes: 60).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 25, 13, 0))
        XCTAssertEqual(Schedule.interval(minutes: 480).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 25, 16, 0))
        XCTAssertEqual(Schedule.daily(hour: 9, minute: 0).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 26, 9, 0))
        XCTAssertEqual(Schedule.daily(hour: 12, minute: 30).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 25, 12, 30))
        XCTAssertEqual(Schedule.weekly(weekdays: [2, 4], hour: 8, minute: 0).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 26, 8, 0))
        XCTAssertEqual(Schedule.weekly(weekdays: [4], hour: 8, minute: 0).nextRun(after: now, calendar: calendar), utcDate(2026, 10, 28, 8, 0))
    }

    func testSummaries() {
        XCTAssertEqual(Schedule.interval(minutes: 1).summary(calendar: calendar, locale: locale), "Every minute")
        XCTAssertEqual(Schedule.interval(minutes: 30).summary(calendar: calendar, locale: locale), "Every 30 minutes")
        XCTAssertEqual(Schedule.interval(minutes: 60).summary(calendar: calendar, locale: locale), "Every hour")
        XCTAssertEqual(Schedule.interval(minutes: 120).summary(calendar: calendar, locale: locale), "Every 2 hours")
        XCTAssertEqual(normalized(Schedule.daily(hour: 9, minute: 5).summary(calendar: calendar, locale: locale)), "Daily at 9:05 AM")
        XCTAssertEqual(normalized(Schedule.weekly(weekdays: [2, 3, 4, 5, 6], hour: 17, minute: 0).summary(calendar: calendar, locale: locale)), "Weekdays at 5:00 PM")
        XCTAssertEqual(normalized(Schedule.weekly(weekdays: [1, 7], hour: 8, minute: 0).summary(calendar: calendar, locale: locale)), "Weekends at 8:00 AM")
        XCTAssertEqual(normalized(Schedule.weekly(weekdays: Array(1...7), hour: 8, minute: 0).summary(calendar: calendar, locale: locale)), "Every day at 8:00 AM")
        XCTAssertEqual(normalized(Schedule.weekly(weekdays: [6, 2, 4], hour: 8, minute: 0).summary(calendar: calendar, locale: locale)), "Mon, Wed, Fri at 8:00 AM")
    }

    func testWeekdayOrderingFollowsCalendar() {
        XCTAssertEqual(Schedule.orderedWeekdays(calendar: utcCalendar(firstWeekday: 1)), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(Schedule.orderedWeekdays(calendar: utcCalendar(firstWeekday: 2)), [2, 3, 4, 5, 6, 7, 1])
        XCTAssertEqual(Schedule.weekdaysLabel([1, 3], calendar: utcCalendar(firstWeekday: 2), locale: locale), "Tue, Sun")
    }

    func testDescribe() {
        let now = utcDate(2026, 10, 25, 12)
        XCTAssertEqual(normalized(Schedule.describe(utcDate(2026, 10, 25, 15), now: now, calendar: calendar, locale: locale)), "today at 3:00 PM")
        XCTAssertEqual(normalized(Schedule.describe(utcDate(2026, 10, 26, 9, 30), now: now, calendar: calendar, locale: locale)), "tomorrow at 9:30 AM")
        XCTAssertEqual(normalized(Schedule.describe(utcDate(2026, 10, 28, 8), now: now, calendar: calendar, locale: locale)), "Wednesday, Oct 28 at 8:00 AM")
    }

    func testDurationLabels() {
        XCTAssertEqual(Schedule.durationLabel(1), "1 minute")
        XCTAssertEqual(Schedule.durationLabel(5), "5 minutes")
        XCTAssertEqual(Schedule.durationLabel(60), "1 hour")
        XCTAssertEqual(Schedule.durationLabel(720), "12 hours")
    }

    func testCodableRoundTrip() throws {
        let schedules: [Schedule] = [.interval(minutes: 5), .daily(hour: 1, minute: 2), .weekly(weekdays: [2, 3], hour: 4, minute: 5)]
        let decoded = try JSONDecoder().decode([Schedule].self, from: JSONEncoder().encode(schedules))
        XCTAssertEqual(decoded, schedules)
    }

    private func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
