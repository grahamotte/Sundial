import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var model = model
        Group {
            if model.sidebarSelection == .settings {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                } detail: {
                    SettingsView()
                }
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                } content: {
                    content
                        .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 480)
                } detail: {
                    Group {
                        if let run = model.run(model.runSelection) {
                            RunDetailView(run: run)
                        } else {
                            ContentUnavailableView("No Run Selected", systemImage: "text.alignleft", description: Text("Select a run to see its output."))
                        }
                    }
                    .toolbar { ToolbarSpacer(.flexible) }
                }
            }
        }
        .sheet(item: $model.editingJob) { job in
            JobEditorView(job: job, isNew: model.isNew(job))
        }
        .confirmationDialog(
            "Delete \(model.jobPendingDeletion?.name ?? "Job")?",
            isPresented: Binding(get: { model.jobPendingDeletion != nil }, set: { if !$0 { model.jobPendingDeletion = nil } }),
            presenting: model.jobPendingDeletion
        ) { job in
            Button("Delete", role: .destructive) { model.delete(job) }
        } message: { _ in
            Text("Its schedule and run history will be removed.")
        }
        .alert(
            "Something Went Wrong",
            isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })
        ) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onChange(of: columnVisibility) {
            columnVisibility = .all
        }
        .onChange(of: model.sidebarSelection) {
            let runs = model.visibleRuns(for: model.sidebarSelection)
            if let revealed = model.revealedRunID, runs.contains(where: { $0.id == revealed }) {
                model.runSelection = revealed
            } else {
                model.runSelection = runs.first?.id
            }
            model.revealedRunID = nil
        }
        .task {
            model.start()
            if model.runSelection == nil {
                model.runSelection = model.visibleRuns(for: model.sidebarSelection).first?.id
            }
        }
    }

    private var sidebar: some View {
        SidebarView()
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 320)
            .toolbar(removing: .sidebarToggle)
    }

    @ViewBuilder
    private var content: some View {
        switch model.sidebarSelection {
        case .allRuns?:
            RunListView(jobID: nil)
        case .job(let id)? where model.job(id) != nil:
            RunListView(jobID: id)
        default:
            ContentUnavailableView("No Job Selected", systemImage: "clock", description: Text("Select a job in the sidebar."))
        }
    }
}
