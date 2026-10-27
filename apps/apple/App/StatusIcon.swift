import SwiftUI

struct StatusIcon: View {
    let status: RunRecord.Status?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch status {
            case .running:
                Image(systemName: "rays")
                    .symbolEffect(.rotate, options: .repeat(.continuous), isActive: !reduceMotion)
                    .foregroundStyle(Solar.sky)
            case .succeeded:
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(Solar.sun)
            case .failed:
                Image(systemName: "cloud.bolt.rain.fill")
                    .foregroundStyle(Solar.storm)
            case .interrupted:
                Image(systemName: "cloud.fill")
                    .foregroundStyle(Solar.storm)
            case nil:
                Image(systemName: "sun.horizon")
                    .foregroundStyle(Solar.dusk)
            }
        }
        .symbolRenderingMode(.hierarchical)
        .frame(width: 18, height: 18)
        .accessibilityLabel(status?.title ?? "Never run")
    }
}
