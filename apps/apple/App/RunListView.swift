import SwiftUI

struct RunListView: View {
    @Environment(AppModel.self) private var model
    let jobID: UUID?
    @State private var filter: RunFilter = .all

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
        .background(Solar.plate)
        .ignoresSafeArea(.container, edges: .top)
        .navigationTitle(job?.name ?? "All Runs")
        .toolbar(removing: .title)
    }

    private var list: some View {
        @Bindable var model = model
        return List(selection: $model.runSelection) {
            if let job {
                Section {
                    JobSummaryView(job: job, runs: allRuns)
                        .foregroundStyle(Solar.ink)
                        .selectionDisabled()
                }
            } else if !model.runs.isEmpty {
                Section {
                    DayArcView(runs: model.runs, schedules: model.jobs.filter(\.isEnabled).map(\.schedule))
                        .padding(.vertical, 6)
                        .foregroundStyle(Solar.ink)
                        .selectionDisabled()
                }
            }
            if !allRuns.isEmpty {
                Section {
                    Picker("Show", selection: $filter) {
                        ForEach(RunFilter.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                    .help("Show all runs or only failures")
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
            if runs.isEmpty && !allRuns.isEmpty {
                Text(filter == .failed ? "No failed runs in the last 30 days." : "No runs in the last 30 days.")
                    .foregroundStyle(Solar.muted)
                    .selectionDisabled()
            }
        }
        .environment(\.defaultMinListRowHeight, RunRow.height)
        .scrollContentBackground(.hidden)
        .background(Solar.plate)
        .overlay {
            if allRuns.isEmpty && job == nil {
                ContentUnavailableView("No Runs Yet", systemImage: "sun.horizon", description: Text("Runs from the last 30 days appear here."))
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(job?.name ?? "All Runs")
                    .font(.headline)
                    .foregroundStyle(Solar.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Solar.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let job {
                Button("Run Now", systemImage: "play.fill") { model.runNow(job) }
                    .help("Run Now")
                Menu("More", systemImage: "ellipsis") { JobMenuItems(job: job) }
                    .menuIndicator(.hidden)
                    .help("More")
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .labelStyle(.iconOnly)
        .controlSize(.large)
        .padding(.horizontal, 12)
        .frame(height: 52)
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
            DayArcView(runs: runs, schedules: job.isEnabled ? [job.schedule] : [])
            Text(job.command)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(4)
                .textSelection(.enabled)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Solar.paper, in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Solar.hairline, lineWidth: 1))
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                GridRow {
                    Text("Schedule").foregroundStyle(Solar.muted)
                    Text(job.schedule.summary())
                }
                GridRow {
                    Text("Next Run").foregroundStyle(Solar.muted)
                    TimelineView(.everyMinute) { context in
                        Text(nextRun(now: context.date))
                    }
                }
                GridRow {
                    Text("Directory").foregroundStyle(Solar.muted)
                    Text(job.workingDirectory)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                GridRow {
                    Text("Last 30 Days").foregroundStyle(Solar.muted)
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
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        let status = run.status()
        let isEmphasized = prominence == .increased
        HStack(spacing: 10) {
            StatusIcon(status: status)
            VStack(alignment: .leading, spacing: 1) {
                Text(showsJobName ? run.jobName : run.startedAt.formatted(date: .omitted, time: .standard))
                    .foregroundStyle(isEmphasized ? AnyShapeStyle(.primary) : AnyShapeStyle(Solar.ink))
                    .lineLimit(1)
                Text(detail(status))
                    .font(.subheadline)
                    .foregroundStyle(isEmphasized ? AnyShapeStyle(.secondary) : status.isFailure ? AnyShapeStyle(Solar.stormText) : AnyShapeStyle(Solar.muted))
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if status == .running {
                TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
                    duration(run.durationText(status: status, now: context.date), isEmphasized: isEmphasized)
                }
            } else {
                duration(run.durationText(status: status), isEmphasized: isEmphasized)
            }
        }
        .padding(.vertical, 2)
    }

    private func detail(_ status: RunRecord.Status) -> String {
        let outcome = status == .running ? "Running" : status == .interrupted ? "Interrupted" : run.outcome ?? status.title
        guard showsJobName else { return outcome }
        return run.startedAt.formatted(date: .omitted, time: .shortened) + " · " + outcome
    }

    private func duration(_ text: String, isEmphasized: Bool) -> some View {
        Text(text)
            .font(.subheadline)
            .monospacedDigit()
            .foregroundStyle(isEmphasized ? AnyShapeStyle(.secondary) : AnyShapeStyle(Solar.muted))
    }
}
