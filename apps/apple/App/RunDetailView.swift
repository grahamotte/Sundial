import AppKit
import SwiftUI

struct RunDetailView: View {
    @Environment(AppModel.self) private var model
    let run: RunRecord
    @State private var log = ""
    @State private var monitor: FileMonitor?

    var body: some View {
        let status = run.status()
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    StatusIcon(status: status)
                        .font(.title)
                        .frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(status.title)
                            .font(.title2.weight(.semibold))
                        Text("\(run.jobName) · \(run.startedAt.formatted(date: .abbreviated, time: .standard))")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Grid(alignment: .trailing, horizontalSpacing: 20, verticalSpacing: 2) {
                        GridRow {
                            Text("Duration").foregroundStyle(.secondary)
                            Text("Result").foregroundStyle(.secondary)
                        }
                        .font(.caption)
                        GridRow {
                            TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
                                Text(run.durationText(status: status, now: context.date))
                            }
                            Text(run.outcome ?? status.title)
                                .foregroundStyle(status.isFailure ? .red : .primary)
                        }
                        .font(.body.monospacedDigit())
                    }
                }
                Text(run.command)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            Divider()
            LogTextView(text: log, documentID: run.id)
                .overlay {
                    if log.isEmpty && status != .running {
                        ContentUnavailableView("No Output", systemImage: "text.alignleft", description: Text("This run didn't print anything."))
                    }
                }
        }
        .toolbar {
            ToolbarItem {
                Button("Copy Output", systemImage: "doc.on.doc") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(log, forType: .string)
                }
                .help("Copy Output")
                .disabled(log.isEmpty)
            }
            ToolbarItem {
                Button("Show Log in Finder", systemImage: "folder") { model.revealLog(run) }
                    .help("Show Log in Finder")
            }
        }
        .task(id: run) {
            log = model.log(for: run)
            monitor = run.finishedAt == nil
                ? FileMonitor(url: model.logURL(for: run)) { log = model.log(for: run) }
                : nil
        }
    }
}

struct LogTextView: NSViewRepresentable {
    let text: String
    let documentID: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 14, height: 12)
        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text || context.coordinator.documentID != documentID else { return }
        let isNewDocument = context.coordinator.documentID != documentID
        let visible = scrollView.documentVisibleRect
        let wasAtBottom = visible.maxY >= textView.bounds.maxY - 4
        textView.string = text
        context.coordinator.documentID = documentID
        if isNewDocument {
            textView.scroll(.zero)
        } else if wasAtBottom {
            textView.scrollToEndOfDocument(nil)
        }
    }

    final class Coordinator {
        var documentID: String?
    }
}
