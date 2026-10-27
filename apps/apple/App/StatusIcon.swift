import SwiftUI

struct StatusIcon: View {
    let status: RunRecord.Status?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Group {
            switch status {
            case .running:
                Image(systemName: "rays")
                    .symbolEffect(.rotate, options: .repeat(.continuous), isActive: !reduceMotion)
            case .succeeded:
                Image(systemName: "sun.max.fill")
            case .failed:
                Image(systemName: "cloud.bolt.rain.fill")
            case .interrupted:
                Image(systemName: "cloud.fill")
            case nil:
                Image(systemName: "sun.horizon")
            }
        }
        .foregroundStyle(prominence == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(status?.tint ?? Solar.dusk))
        .symbolRenderingMode(.hierarchical)
        .frame(width: 18, height: 18)
        .accessibilityLabel(status?.title ?? "Never run")
    }
}
