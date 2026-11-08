import XCTest
@testable import SundialCore

final class PowerMonitoringTests: XCTestCase {
    func testJobsRunWhenAwakeOrOnPowerAndWaitOnlyWhileAsleepOnBattery() {
        XCTAssertTrue(PowerState(isAsleep: false, isOnPower: false).allowsRun)
        XCTAssertTrue(PowerState(isAsleep: false, isOnPower: true).allowsRun)
        XCTAssertTrue(PowerState(isAsleep: true, isOnPower: true).allowsRun)
        XCTAssertFalse(PowerState(isAsleep: true, isOnPower: false).allowsRun)
    }
}
