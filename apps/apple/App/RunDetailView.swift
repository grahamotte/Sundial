import AppKit
import SwiftUI

struct RunDetailView: View {
    @Environment(AppModel.self) private var model
    let run: RunRecord
    @State private var log = ""
    @State private var width: CGFloat = 0

    var body: some View {
        let status = run.status()
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(run.command)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(Solar.muted)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Copy Output", systemImage: "doc.on.doc") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(log, forType: .string)
                    }
                    .help("Copy Output")
                    .disabled(log.isEmpty)
                    Button("Show Log in Finder", systemImage: "folder") { model.revealLog(run) }
                        .help("Show Log in Finder")
                }
                .buttonStyle(.borderless)
                .labelStyle(.iconOnly)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 12)
            Rectangle()
                .fill(Solar.hairline)
                .frame(height: 1)
            LogTextView(text: log, documentID: run.id)
                .overlay {
                    if log.isEmpty && status != .running {
                        ContentUnavailableView("No Output", systemImage: "text.alignleft", description: Text("This run didn't print anything."))
                    }
                }
        }
        .background(Solar.paper)
        .foregroundStyle(Solar.ink)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                header(status: status)
                    .padding(.leading, 22)
                    .frame(width: max(width - 18, 0))
            }
            .sharedBackgroundVisibility(.hidden)
        }
        .task(id: run) {
            log = model.log(for: run)
            guard run.finishedAt == nil else { return }
            for await _ in FileMonitor.changes(of: model.logURL(for: run)) {
                log = model.log(for: run)
            }
        }
    }

    private func header(status: RunRecord.Status) -> some View {
        HStack(alignment: .center, spacing: 10) {
            StatusIcon(status: status)
                .font(.title2)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(status.title)
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(status.textTint)
                    .lineLimit(1)
                Text("\(run.jobName) · \(run.startedAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.subheadline)
                    .foregroundStyle(Solar.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 1) {
                GridRow {
                    Text("Duration").foregroundStyle(Solar.muted)
                    Text("Result").foregroundStyle(Solar.muted)
                }
                .font(.caption)
                GridRow {
                    TimelineView(.periodic(from: run.startedAt, by: 1)) { context in
                        Text(run.durationText(status: status, now: context.date))
                    }
                    Text(run.outcome ?? status.title)
                        .foregroundStyle(status.isFailure ? AnyShapeStyle(Solar.stormText) : AnyShapeStyle(Solar.ink))
                }
                .font(.subheadline.monospacedDigit())
            }
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
        textView.textColor = NSColor(Solar.ink)
        textView.selectedTextAttributes = [.backgroundColor: NSColor(Solar.sunlight).withAlphaComponent(0.3)]
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
