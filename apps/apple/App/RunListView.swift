import SwiftUI

struct RunListView: View {
    @Environment(AppModel.self) private var model
    let jobID: UUID?
    @State private var filter: RunFilter = .all

    var body: some View {
        @Bindable var model = model
        List(selection: $model.runSelection) {
            if let job {
                Section {
                    JobSummaryView(job: job, runs: allRuns)
                        .selectionDisabled()
                }
            }
            ForEach(RunDay.group(runs)) { day in
                Section(day.title()) {
                    ForEach(day.runs) { run in
                        RunRow(run: run, showsJobName: jobID == nil)
                            .tag(run.id)
                    }
                }
            }
            if runs.isEmpty && job != nil {
                Text(filter == .failed ? "No failed runs in the last 30 days." : "No runs in the last 30 days.")
                    .foregroundStyle(.secondary)
                    .selectionDisabled()
            }
        }
        .environment(\.defaultMinListRowHeight, RunRow.height)
        .overlay {
            if runs.isEmpty && job == nil {
                ContentUnavailableView(
                    filter == .failed ? "No Failures" : "No Runs Yet",
                    systemImage: filter == .failed ? "checkmark.circle" : "clock",
                    description: Text(filter == .failed ? "Nothing has failed in the last 30 days." : "Runs from the last 30 days appear here.")
                )
            }
        }
        .navigationTitle(job?.name ?? "All Runs")
        .navigationSubtitle(subtitle)
        .toolbar {
            ToolbarSpacer(.flexible)
            ToolbarItem {
                Picker("Show", selection: $filter) {
                    ForEach(RunFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .help("Show all runs or only failures")
            }
            if let job {
                ToolbarItem {
                    Button("Run Now", systemImage: "play.fill") { model.runNow(job) }
                        .help("Run Now")
                }
                ToolbarItem {
                    Menu("More", systemImage: "ellipsis") { JobMenuItems(job: job) }
                        .help("More")
                }
            }
        }
    }

    private var job: Job? { jobID.flatMap(model.job) }

    private var allRuns: [RunRecord] {
        jobID.map(model.runs(for:)) ?? model.runs
    }

    private var runs: [RunRecord] {
        filter == .failed ? allRuns.filter { $0.status().isFailure } : allRuns
    }

    private var subtitle: String {
        let failed = allRuns.filter { $0.status().isFailure }.count
        let count = allRuns.count == 1 ? "1 run" : "\(allRuns.count) runs"
        return failed == 0 ? count : "\(count), \(failed) failed"
    }
}

struct JobSummaryView: View {
    @Environment(AppModel.self) private var model
    let job: Job
    let runs: [RunRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(job.command)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(4)
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 8))
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                GridRow {
                    Text("Schedule").foregroundStyle(.secondary)
                    Text(job.schedule.summary())
                }
                GridRow {
                    Text("Next Run").foregroundStyle(.secondary)
                    TimelineView(.everyMinute) { context in
                        Text(nextRun(now: context.date))
                    }
                }
                GridRow {
                    Text("Directory").foregroundStyle(.secondary)
                    Text(job.workingDirectory)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                GridRow {
                    Text("Last 30 Days").foregroundStyle(.secondary)
                    Text(history)
                }
            }
            .font(.callout)
        }
        .padding(.vertical, 6)
    }

    private func nextRun(now: Date) -> String {
        guard job.isEnabled else { return "Paused" }
        guard let date = job.schedule.nextRun(after: now) else { return "—" }
        let text = Schedule.describe(date, now: now)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private var history: String {
        let finished = runs.filter { $0.status() != .running }
        guard !finished.isEmpty else { return "No runs" }
        let failed = finished.filter { $0.status().isFailure }.count
        let passed = finished.count - failed
        return failed == 0 ? "\(passed) passed" : "\(passed) passed, \(failed) failed"
    }
}

struct RunRow: View {
    static let height: CGFloat = 40

    let run: RunRecord
    let showsJobName: Bool

    var body: some View {
        let status = run.status()
        HStack(spacing: 10) {
            StatusIcon(status: status)
            VStack(alignment: .leading, spacing: 1) {
                Text(showsJobName ? run.jobName : run.startedAt.formatted(date: .omitted, time: .standard))
                    .lineLimit(1)
                Text(detail(status))
                    .font(.subheadline)
                    .foregroundStyle(status.isFailure ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if status == .running {
                TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
                    duration(run.durationText(status: status, now: context.date))
                }
            } else {
                duration(run.durationText(status: status))
            }
        }
        .padding(.vertical, 2)
    }

    private func detail(_ status: RunRecord.Status) -> String {
        let outcome = status == .running ? "Running" : status == .interrupted ? "Interrupted" : run.outcome ?? status.title
        guard showsJobName else { return outcome }
        return run.startedAt.formatted(date: .omitted, time: .shortened) + " · " + outcome
    }

    private func duration(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(.secondary)
    }
}
