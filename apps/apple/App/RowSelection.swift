import AppKit
import SwiftUI

struct RowSelectionBackground: View {
    let isSelected: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? Solar.selection : .clear)
            .padding(.horizontal, 10)
            .background(NativeSelectionHider())
    }
}

struct NativeSelectionHider: NSViewRepresentable {
    func makeNSView(context: Context) -> HiderView { HiderView() }

    func updateNSView(_ view: HiderView, context: Context) {}

    final class HiderView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            var view = superview
            while let current = view, !(current is NSTableView) { view = current.superview }
            (view as? NSTableView)?.selectionHighlightStyle = .none
        }
    }
}
