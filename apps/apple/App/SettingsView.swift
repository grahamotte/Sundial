import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Preferences.showsMenuBarExtraKey) private var showsMenuBarExtra = true
    @State private var loginItem = LoginItem()

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sundial")
                            .font(.title2.weight(.semibold))
                            .fontDesign(.rounded)
                        Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                            .foregroundStyle(Solar.muted)
                    }
                }
                .padding(.vertical, 4)
            }
            Section {
                Toggle("Show in menu bar", isOn: $showsMenuBarExtra)
                Toggle("Open at login", isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) }))
            } footer: {
                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 6) {
                        if loginItem.requiresApproval {
                            Text("Allow Sundial in System Settings → General → Login Items & Extensions.")
                            Button("Open Login Items Settings") { SMAppService.openSystemSettingsLoginItems() }
                                .buttonStyle(.link)
                        }
                        if let message = loginItem.errorMessage {
                            Text(message)
                                .foregroundStyle(Solar.stormText)
                        }
                        Text("Jobs run on schedule whether or not Sundial is open.")
                    }
                    .foregroundStyle(Solar.muted)
                    Spacer()
                    Button("Done") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(width: 460)
        .background(Solar.paper)
        .navigationTitle("Settings")
        .onExitCommand { dismiss() }
        .onAppear { loginItem.refresh() }
    }
}
