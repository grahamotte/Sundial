import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var started = false

    var body: some View {
        @Bindable var model = model
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 320)
        } content: {
            content
                .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 480)
        } detail: {
            if let run = model.run(model.runSelection) {
                RunDetailView(run: run)
            } else {
                ContentUnavailableView("No Run Selected", systemImage: "text.alignleft", description: Text("Select a run to see its output."))
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
        .onChange(of: model.sidebarSelection) {
            model.runSelection = visibleRuns.first?.id
        }
        .task {
            guard !started else { return }
            started = true
            model.start()
            model.runSelection = visibleRuns.first?.id
        }
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

    private var visibleRuns: [RunRecord] {
        switch model.sidebarSelection {
        case .allRuns?: return model.runs
        case .job(let id)?: return model.runs(for: id)
        default: return []
        }
    }
}
