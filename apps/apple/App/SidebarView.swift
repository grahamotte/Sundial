import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(selection: $model.sidebarSelection) {
            Label("All Runs", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                .badge(failureCount)
                .tag(SidebarItem.allRuns)
            Section("Jobs") {
                ForEach(model.jobs) { job in
                    JobRow(job: job)
                        .tag(SidebarItem.job(job.id))
                        .contextMenu { JobMenuItems(job: job) }
                }
                if model.jobs.isEmpty {
                    Button("Add a Job…", systemImage: "plus") { model.newJob() }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SettingsSidebarButton(isSelected: model.isShowingSettings) {
                model.isShowingSettings = true
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .toolbar {
            ToolbarSpacer(.flexible)
            ToolbarItem {
                Button("New Job", systemImage: "plus") { model.newJob() }
                    .help("New Job")
            }
        }
    }

    private var failureCount: Int {
        model.jobs.filter { job in
            guard job.isEnabled, let last = model.runs(for: job.id).first(where: { $0.status() != .running }) else { return false }
            return last.status().isFailure
        }.count
    }
}

struct SettingsSidebarButton: View {
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label("Settings", systemImage: "gearshape")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .contentShape(.rect)
                .background(background, in: .rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var background: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(.quaternary) }
        if isHovered { return AnyShapeStyle(.quinary) }
        return AnyShapeStyle(.clear)
    }
}

struct JobRow: View {
    @Environment(AppModel.self) private var model
    let job: Job

    var body: some View {
        HStack(spacing: 8) {
            StatusIcon(status: model.lastRun(for: job.id)?.status())
            VStack(alignment: .leading, spacing: 1) {
                Text(job.name)
                    .lineLimit(1)
                Text(job.isEnabled ? job.schedule.summary() : "Paused")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .opacity(job.isEnabled ? 1 : 0.55)
    }
}

struct JobMenuItems: View {
    @Environment(AppModel.self) private var model
    let job: Job

    var body: some View {
        Button("Run Now", systemImage: "play") { model.runNow(job) }
        Button("Edit…", systemImage: "pencil") { model.editingJob = job }
        Toggle("Enabled", isOn: Binding(get: { job.isEnabled }, set: { model.setEnabled(job, $0) }))
        Button("Duplicate", systemImage: "plus.square.on.square") { model.duplicate(job) }
        Button("Show Launch Agent in Finder", systemImage: "folder") { model.revealLaunchAgent(job) }
        Divider()
        Button("Delete…", systemImage: "trash", role: .destructive) { model.jobPendingDeletion = job }
    }
}
