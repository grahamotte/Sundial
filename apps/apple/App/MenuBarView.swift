import AppKit
import SwiftUI

struct MenuBarView: View {
    static let runLimit = 10

    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let recent = RunRecord.recent(model.runs, limit: MenuBarView.runLimit)
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Runs")
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 6)
            if recent.isEmpty {
                Text("No runs yet.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(recent) { run in
                        MenuRow(action: { show(run) }) { MenuRunRow(run: run) }
                    }
                }
                .padding(.horizontal, 5)
            }
            Divider()
                .padding(.vertical, 5)
            VStack(spacing: 0) {
                MenuRow(action: showAllRuns) { Text("View All Runs…") }
                MenuRow(action: showSettings) { Text("Settings…") }
                MenuRow(action: { NSApp.terminate(nil) }) { Text("Quit Sundial") }
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 5)
        }
        .frame(width: 320)
    }

    private func show(_ run: RunRecord) {
        model.reveal(run)
        openMainWindow()
    }

    private func showAllRuns() {
        model.sidebarSelection = .allRuns
        openMainWindow()
    }

    private func showSettings() {
        model.sidebarSelection = .settings
        openMainWindow()
    }

    private func openMainWindow() {
        openWindow(id: SundialApp.mainWindowID)
        NSApp.activate()
    }
}

struct MenuRunRow: View {
    let run: RunRecord

    var body: some View {
        let status = run.status()
        HStack(spacing: 8) {
            StatusIcon(status: status)
            Text(run.jobName)
                .lineLimit(1)
            Spacer(minLength: 8)
            TimelineView(.everyMinute) { context in
                Text(status == .running ? "Running" : run.startedAt.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
    }
}

struct MenuRow<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .contentShape(.rect)
                .foregroundStyle(isHovered ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background(isHovered ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear), in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
