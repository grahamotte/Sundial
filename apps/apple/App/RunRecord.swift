import Darwin
import Foundation

struct RunRecord: Codable, Identifiable, Hashable {
    enum Status: Hashable {
        case running
        case succeeded
        case failed
        case interrupted

        var title: String {
            switch self {
            case .running: return "Running"
            case .succeeded: return "Succeeded"
            case .failed: return "Failed"
            case .interrupted: return "Interrupted"
            }
        }

        var isFailure: Bool { self == .failed || self == .interrupted }
    }

    var id: String
    var jobID: UUID
    var jobName: String
    var command: String
    var startedAt: Date
    var finishedAt: Date?
    var exitCode: Int32?
    var signal: Int32?
    var processID: Int32

    func status(isProcessAlive: (Int32) -> Bool = RunRecord.isProcessAlive) -> Status {
        guard finishedAt != nil else { return isProcessAlive(processID) ? .running : .interrupted }
        return exitCode == 0 && signal == nil ? .succeeded : .failed
    }

    func duration(now: Date = Date()) -> TimeInterval {
        max(0, (finishedAt ?? now).timeIntervalSince(startedAt))
    }

    func durationText(status: Status, now: Date = Date()) -> String {
        status == .interrupted ? "—" : RunRecord.formatDuration(duration(now: now))
    }

    var outcome: String? {
        if let signal { return "Signal \(signal)" }
        if let exitCode { return "Exit \(exitCode)" }
        return nil
    }

    nonisolated static func isProcessAlive(_ processID: Int32) -> Bool {
        guard processID > 0 else { return false }
        return kill(processID, 0) == 0 || errno == EPERM
    }

    static func latestPerJob(_ runs: [RunRecord], limit: Int) -> [RunRecord] {
        let latest = Dictionary(grouping: runs, by: \.jobID).compactMap { $0.value.max { $0.startedAt < $1.startedAt } }
        return Array(latest.sorted { $0.startedAt > $1.startedAt }.prefix(max(0, limit)))
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        if interval < 1 { return "<1s" }
        let seconds = Int(interval.rounded(.down))
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(seconds % 60)s" }
        return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
    }
}
