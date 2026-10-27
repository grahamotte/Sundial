import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var sidebarWidth: CGFloat?

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
                            ContentUnavailableView("No Run Selected", systemImage: "sun.dust", description: Text("Select a run to see its output."))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Solar.paper)
                        }
                    }
                    .toolbar { ToolbarSpacer(.flexible) }
                }
            }
        }
        .containerBackground(Solar.paper, for: .window)
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
        .onAppear { AppDelegate.setMainWindowOpen(true) }
        .onDisappear { AppDelegate.setMainWindowOpen(false) }
        .task {
            model.start()
            if model.runSelection == nil {
                model.runSelection = model.visibleRuns(for: model.sidebarSelection).first?.id
            }
        }
    }

    private var sidebar: some View {
        SidebarView()
            .background(SidebarWidthKeeper(width: $sidebarWidth))
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
            ContentUnavailableView("No Job Selected", systemImage: "sun.horizon", description: Text("Select a job in the sidebar."))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Solar.plate)
        }
    }
}

struct SidebarWidthKeeper: NSViewRepresentable {
    @Binding var width: CGFloat?

    func makeNSView(context: Context) -> KeeperView { KeeperView() }

    func updateNSView(_ view: KeeperView, context: Context) {
        view.width = width
        view.onResize = { width = $0 }
    }

    final class KeeperView: NSView {
        var width: CGFloat?
        var onResize: ((CGFloat) -> Void)?
        private var observer: NSObjectProtocol?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let observer { NotificationCenter.default.removeObserver(observer) }
            observer = nil
            guard window != nil, let splitView = enclosingSplitView() else { return }
            if let width { splitView.setPosition(width, ofDividerAt: 0) }
            observer = NotificationCenter.default.addObserver(forName: NSSplitView.didResizeSubviewsNotification, object: splitView, queue: .main) { [weak self] _ in
                guard let sidebar = splitView.arrangedSubviews.first else { return }
                MainActor.assumeIsolated { self?.onResize?(sidebar.frame.width) }
            }
        }

        private func enclosingSplitView() -> NSSplitView? {
            var view = superview
            while let current = view, !(current is NSSplitView) { view = current.superview }
            return view as? NSSplitView
        }
    }
}
