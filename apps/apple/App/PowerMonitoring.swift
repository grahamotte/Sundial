import Foundation
import IOKit
import IOKit.ps
import IOKit.pwr_mgt
import notify

struct PowerState: Equatable {
    var isAsleep: Bool
    var isOnPower: Bool

    var allowsRun: Bool { !isAsleep || isOnPower }
}

nonisolated protocol PowerMonitoring: AnyObject {
    var onSleep: (@Sendable (Bool) -> Void)? { get set }
    func state() -> PowerState
    func waitForChange()
    func keepAwake(reason: String) -> () -> Void
}

nonisolated final class SystemPowerMonitor: PowerMonitoring, @unchecked Sendable {
    static let systemPowerStateNotification = "com.apple.powermanagement.systempowerstate"
    private static let canSystemSleep: UInt32 = 0xE000_0270
    private static let systemWillSleep: UInt32 = 0xE000_0280
    private static let systemHasPoweredOn: UInt32 = 0xE000_0300

    private let queue = DispatchQueue(label: "com.grahamotte.sundial.power")
    private let changes = DispatchSemaphore(value: 0)
    private let lock = NSLock()
    private var sleepHandler: (@Sendable (Bool) -> Void)?
    private var rootPort: io_connect_t = 0
    private var notifier: io_object_t = 0
    private var notificationPort: IONotificationPortRef?
    private var tokens: [Int32] = []

    var onSleep: (@Sendable (Bool) -> Void)? {
        get { lock.withLock { sleepHandler } }
        set { lock.withLock { sleepHandler = newValue } }
    }

    init() {
        for name in [kIOPSNotifyPowerSource, SystemPowerMonitor.systemPowerStateNotification] {
            var token: Int32 = 0
            let status = notify_register_dispatch(name, &token, queue) { [weak self] _ in self?.changes.signal() }
            if status == NOTIFY_STATUS_OK { tokens.append(token) }
        }
        let callback: IOServiceInterestCallback = { refcon, _, messageType, argument in
            guard let refcon else { return }
            Unmanaged<SystemPowerMonitor>.fromOpaque(refcon).takeUnretainedValue().handle(messageType, argument)
        }
        rootPort = IORegisterForSystemPower(Unmanaged.passUnretained(self).toOpaque(), &notificationPort, callback, &notifier)
        if let notificationPort { IONotificationPortSetDispatchQueue(notificationPort, queue) }
    }

    deinit {
        tokens.forEach { notify_cancel($0) }
        if notifier != 0 { IODeregisterForSystemPower(&notifier) }
        if rootPort != 0 { IOServiceClose(rootPort) }
        if let notificationPort { IONotificationPortDestroy(notificationPort) }
    }

    func state() -> PowerState {
        PowerState(isAsleep: isAsleep(), isOnPower: isOnPower())
    }

    func waitForChange() {
        changes.wait()
    }

    func keepAwake(reason: String) -> () -> Void {
        var assertion: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(kIOPMAssertNetworkClientActive as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &assertion)
        guard result == kIOReturnSuccess else { return {} }
        return { IOPMAssertionRelease(assertion) }
    }

    private func handle(_ messageType: UInt32, _ argument: UnsafeMutableRawPointer?) {
        switch messageType {
        case SystemPowerMonitor.canSystemSleep:
            IOAllowPowerChange(rootPort, Int(bitPattern: argument))
        case SystemPowerMonitor.systemWillSleep:
            onSleep?(isOnPower())
            IOAllowPowerChange(rootPort, Int(bitPattern: argument))
            changes.signal()
        case SystemPowerMonitor.systemHasPoweredOn:
            changes.signal()
        default:
            break
        }
    }

    private func isAsleep() -> Bool {
        let root = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard root != 0 else { return false }
        defer { IOObjectRelease(root) }
        guard let value = IORegistryEntryCreateCFProperty(root, "System Capabilities" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber else { return false }
        return value.uint32Value & UInt32(kIOPMSystemCapabilityGraphics) == 0
    }

    private func isOnPower() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let source = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() else { return true }
        return (source as String) == kIOPMACPowerKey
    }
}
