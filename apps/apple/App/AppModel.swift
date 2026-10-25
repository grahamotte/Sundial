import AppKit
import Foundation
import Observation

enum SidebarItem: Hashable {
    case allRuns
    case job(UUID)
}

enum RunFilter: String, CaseIterable, Identifiable {
    case all
    case failed

    var id: String { rawValue }
    var title: String { self == .all ? "All" : "Failed" }
}

@Observable
final class AppModel {
    var jobs: [Job] = []
    var runs: [RunRecord] = []
    var sidebarSelection: SidebarItem? = .allRuns
    var runSelection: RunRecord.ID?
    var editingJob: Job?
    var jobPendingDeletion: Job?
    var errorMessage: String?
    var revealedRunID: RunRecord.ID?

    private let paths: SundialPaths
    private let jobStore: JobStore
    private let runStore: RunStore
    private let launchAgents: LaunchAgentManager
    @ObservationIgnored private var monitor: FileMonitor?

    init(paths: SundialPaths = .standard) {
        self.paths = paths
        jobStore = JobStore(url: paths.jobsFile)
        runStore = RunStore(directory: paths.runsDirectory)
        launchAgents = LaunchAgentManager(
            directory: paths.launchAgentsDirectory,
            executablePath: Bundle.main.executablePath ?? "",
            userID: getuid(),
            commands: SystemCommandRunner()
        )
    }

    @ObservationIgnored private var started = false

    func start() {
        guard !started else { return }
        started = true
        do {
            jobs = try jobStore.load()
        } catch {
            errorMessage = "Sundial could not read its jobs: \(error.localizedDescription)"
        }
        try? FileManager.default.createDirectory(at: paths.runsDirectory, withIntermediateDirectories: true)
        runStore.prune()
        syncLaunchAgents()
        reloadRuns()
        monitor = FileMonitor(url: paths.runsDirectory) { [weak self] in self?.reloadRuns() }
        if let first = jobs.first, sidebarSelection == .allRuns, runs.isEmpty {
            sidebarSelection = .job(first.id)
        }
    }

    var selectedJob: Job? {
        guard case .job(let id) = sidebarSelection else { return nil }
        return job(id)
    }

    func job(_ id: UUID) -> Job? {
        jobs.first { $0.id == id }
    }

    func runs(for jobID: UUID) -> [RunRecord] {
        runs.filter { $0.jobID == jobID }
    }

    func lastRun(for jobID: UUID) -> RunRecord? {
        runs.first { $0.jobID == jobID }
    }

    func run(_ id: RunRecord.ID?) -> RunRecord? {
        guard let id else { return nil }
        return runs.first { $0.id == id }
    }

    func log(for record: RunRecord) -> String {
        runStore.log(for: record.id)
    }

    func logURL(for record: RunRecord) -> URL {
        runStore.logURL(record.id)
    }

    func reloadRuns() {
        runs = runStore.records()
    }

    func reveal(_ run: RunRecord) {
        let item: SidebarItem = job(run.jobID) == nil ? .allRuns : .job(run.jobID)
        revealedRunID = run.id
        if sidebarSelection == item {
            runSelection = run.id
            revealedRunID = nil
        } else {
            sidebarSelection = item
        }
    }

    func visibleRuns(for item: SidebarItem?) -> [RunRecord] {
        switch item {
        case .allRuns?: return runs
        case .job(let id)?: return runs(for: id)
        default: return []
        }
    }

    func newJob() {
        editingJob = Job()
    }

    func save(_ job: Job) {
        var updated = jobs.filter { $0.id != job.id }
        updated.append(job)
        persist(updated)
        sidebarSelection = .job(job.id)
    }

    func setEnabled(_ job: Job, _ isEnabled: Bool) {
        var changed = job
        changed.isEnabled = isEnabled
        persist(jobs.map { $0.id == job.id ? changed : $0 })
    }

    func duplicate(_ job: Job) {
        let copy = job.duplicated()
        persist(jobs + [copy])
        sidebarSelection = .job(copy.id)
    }

    func delete(_ job: Job) {
        persist(jobs.filter { $0.id != job.id })
        runStore.delete(jobID: job.id)
        reloadRuns()
        if sidebarSelection == .job(job.id) { sidebarSelection = .allRuns }
    }

    func runNow(_ job: Job) {
        do {
            try launchAgents.runNow(job)
        } catch {
            errorMessage = "Sundial could not start \(job.name): \(error.localizedDescription)"
        }
    }

    func revealLaunchAgent(_ job: Job) {
        let url = launchAgents.plistURL(for: job)
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([paths.launchAgentsDirectory])
        }
    }

    func revealLog(_ record: RunRecord) {
        NSWorkspace.shared.activateFileViewerSelecting([runStore.logURL(record.id)])
    }

    func isNew(_ job: Job) -> Bool {
        self.job(job.id) == nil
    }

    var home: URL { paths.home }

    private func persist(_ updated: [Job]) {
        let sorted = JobStore.sorted(updated)
        do {
            try jobStore.save(sorted)
            jobs = sorted
        } catch {
            errorMessage = "Sundial could not save its jobs: \(error.localizedDescription)"
            return
        }
        syncLaunchAgents()
    }

    private func syncLaunchAgents() {
        do {
            let failures = try launchAgents.sync(jobs)
            if !failures.isEmpty {
                errorMessage = "launchd did not accept the schedule for \(failures.joined(separator: ", "))."
            }
        } catch {
            errorMessage = "Sundial could not update its launch agents: \(error.localizedDescription)"
        }
    }
}
