import AppKit
import SwiftUI

struct SundialApp: App {
    static let mainWindowID = "main"

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(Preferences.showsMenuBarExtraKey) private var showsMenuBarExtra = true
    @State private var model: AppModel = {
        let model = AppModel()
        model.start()
        return model
    }()

    var body: some Scene {
        Window("Sundial", id: SundialApp.mainWindowID) {
            ContentView()
                .environment(model)
        }
        .defaultSize(width: 1120, height: 700)
        .onChange(of: showsMenuBarExtra) {
            AppDelegate.applyActivationPolicy()
            NSApp.activate()
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsCommand(model: model)
            }
            CommandGroup(replacing: .help) {
                Link("Sundial Help", destination: AppDelegate.helpURL)
            }
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

        MenuBarExtra(isInserted: $showsMenuBarExtra) {
            MenuBarView()
                .environment(model)
        } label: {
            Image(nsImage: SundialGlyph.menuBarImage)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let helpURL = URL(string: "https://github.com/grahamotte/Sundial")!

    static var isMainWindowOpen = false

    static func applyActivationPolicy() {
        NSApp.setActivationPolicy(Preferences.showsMenuBarExtra && !isMainWindowOpen ? .accessory : .regular)
    }

    static func setMainWindowOpen(_ isOpen: Bool) {
        isMainWindowOpen = isOpen
        applyActivationPolicy()
        if isOpen { NSApp.activate() }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        AppDelegate.applyActivationPolicy()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !Preferences.showsMenuBarExtra
    }
}

struct SettingsCommand: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings…") {
            model.isShowingSettings = true
            openWindow(id: SundialApp.mainWindowID)
        }
        .keyboardShortcut(",")
    }
}
