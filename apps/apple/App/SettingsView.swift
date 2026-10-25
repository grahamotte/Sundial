import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage(Preferences.showsMenuBarExtraKey) private var showsMenuBarExtra = true
    @State private var loginItem = LoginItem()

    var body: some View {
        Form {
            Section {
                Toggle("Show in menu bar", isOn: $showsMenuBarExtra)
                Toggle("Open at login", isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) }))
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    if loginItem.requiresApproval {
                        Text("Allow Sundial in System Settings → General → Login Items & Extensions.")
                        Button("Open Login Items Settings") { SMAppService.openSystemSettingsLoginItems() }
                            .buttonStyle(.link)
                    }
                    if let message = loginItem.errorMessage {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                    Text("Jobs run on schedule whether or not Sundial is open.")
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { loginItem.refresh() }
    }
}
