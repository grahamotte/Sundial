import AppKit
import SwiftUI

struct SundialApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Sundial", id: "main") {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 1120, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Job…") { model.newJob() }
                    .keyboardShortcut("n")
            }
            CommandMenu("Job") {
                Button("Run Now") {
                    if let job = model.selectedJob { model.runNow(job) }
                }
                .keyboardShortcut("r")
                .disabled(model.selectedJob == nil)
                Button("Edit Job…") { model.editingJob = model.selectedJob }
                    .keyboardShortcut("e")
                    .disabled(model.selectedJob == nil)
                Divider()
                Button("Delete Job…") { model.jobPendingDeletion = model.selectedJob }
                    .keyboardShortcut(.delete)
                    .disabled(model.selectedJob == nil)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
