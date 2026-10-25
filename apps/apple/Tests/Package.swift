// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sundial",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "SundialCore",
            path: "App",
            exclude: [
                "AppModel.swift",
                "Assets.xcassets",
                "ContentView.swift",
                "FileMonitor.swift",
                "Info.plist",
                "JobEditorView.swift",
                "RunDetailView.swift",
                "RunListView.swift",
                "SidebarView.swift",
                "StatusIcon.swift",
                "Sundial.entitlements",
                "SundialApp.swift",
                "SundialMain.swift",
            ],
            sources: [
                "CommandRunning.swift",
                "Job.swift",
                "JobRunner.swift",
                "JobStore.swift",
                "LaunchAgentManager.swift",
                "RunDay.swift",
                "RunRecord.swift",
                "RunStore.swift",
                "Schedule.swift",
                "ScheduleDraft.swift",
                "SundialPaths.swift",
            ],
            swiftSettings: [.swiftLanguageMode(.v5)],
        ),
        .testTarget(
            name: "SundialCoreTests",
            dependencies: ["SundialCore"],
            path: "Tests",
            exclude: ["Package.swift"],
            swiftSettings: [.swiftLanguageMode(.v5)],
        ),
    ]
)
