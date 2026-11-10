import XCTest
@testable import SundialCore

final class JobTests: XCTestCase {
    private let home = URL(filePath: "/Users/tester", directoryHint: .isDirectory)

    func testLabelUsesLowercasedID() {
        let job = Job(id: UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001")!)
        XCTAssertEqual(job.label, "com.grahamotte.sundial.job.a1b2c3d4-0000-0000-0000-000000000001")
    }

    func testValidity() {
        XCTAssertFalse(Job().isValid)
        XCTAssertFalse(Job(name: "  ", command: "echo hi").isValid)
        XCTAssertFalse(Job(name: "Hi", command: "\n").isValid)
        XCTAssertFalse(Job(name: "Hi", command: "echo hi", schedule: .interval(minutes: 7)).isValid)
        XCTAssertTrue(Job(name: "Hi", command: "echo hi").isValid)
        XCTAssertTrue(Job(name: "Hi", command: "echo hi", startWithinHours: 2).isValid)
        XCTAssertTrue(Job(name: "Hi", command: "echo hi", startWithinHours: 12).isValid)
        XCTAssertFalse(Job(name: "Hi", command: "echo hi", startWithinHours: 5).isValid)
        XCTAssertFalse(Job(name: "Hi", command: "echo hi", startWithinHours: 0).isValid)
    }

    func testDecodesJobsSavedWithoutStartWithin() throws {
        let job = Job(name: "Backup", command: "echo", schedule: .daily(hour: 20, minute: 0))
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(job)) as! [String: Any]
        XCTAssertNil(object["startWithinHours"])
        object.removeValue(forKey: "startWithinHours")
        let decoded = try JSONDecoder().decode(Job.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(decoded, job)
        XCTAssertNil(decoded.startWithinHours)
    }

    func testStartWithinRoundTrips() throws {
        let job = Job(name: "Backup", command: "echo", startWithinHours: 3)
        XCTAssertEqual(try JSONDecoder().decode(Job.self, from: JSONEncoder().encode(job)).startWithinHours, 3)
    }

    func testWorkingDirectoryURL() {
        XCTAssertEqual(Job(workingDirectory: "~").workingDirectoryURL(home: home).path, "/Users/tester")
        XCTAssertEqual(Job(workingDirectory: "").workingDirectoryURL(home: home).path, "/Users/tester")
        XCTAssertEqual(Job(workingDirectory: "~/Code/App").workingDirectoryURL(home: home).path, "/Users/tester/Code/App")
        XCTAssertEqual(Job(workingDirectory: "/tmp").workingDirectoryURL(home: home).path, "/tmp")
    }

    func testAbbreviatedPath() {
        XCTAssertEqual(Job.abbreviatedPath("/Users/tester", home: home), "~")
        XCTAssertEqual(Job.abbreviatedPath("/Users/tester/Code", home: home), "~/Code")
        XCTAssertEqual(Job.abbreviatedPath("/Users/testerx/Code", home: home), "/Users/testerx/Code")
        XCTAssertEqual(Job.abbreviatedPath("/tmp", home: home), "/tmp")
    }

    func testDuplicatedHasNewIdentity() {
        let job = Job(name: "Backup", command: "echo", workingDirectory: "/tmp", schedule: .daily(hour: 1, minute: 2), isEnabled: false, startWithinHours: 4)
        let copy = job.duplicated()
        XCTAssertNotEqual(copy.id, job.id)
        XCTAssertEqual(copy.name, "Backup Copy")
        XCTAssertEqual(copy.command, job.command)
        XCTAssertEqual(copy.workingDirectory, job.workingDirectory)
        XCTAssertEqual(copy.schedule, job.schedule)
        XCTAssertEqual(copy.isEnabled, job.isEnabled)
        XCTAssertEqual(copy.startWithinHours, 4)
    }
}
