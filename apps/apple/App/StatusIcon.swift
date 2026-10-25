import SwiftUI

struct StatusIcon: View {
    let status: RunRecord.Status?

    var body: some View {
        Group {
            switch status {
            case .running:
                ProgressView()
                    .controlSize(.small)
            case .succeeded:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .interrupted:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            case nil:
                Image(systemName: "circle.dashed")
                    .foregroundStyle(.tertiary)
            }
        }
        .symbolRenderingMode(.hierarchical)
        .frame(width: 18, height: 18)
        .accessibilityLabel(status?.title ?? "Never run")
    }
}
