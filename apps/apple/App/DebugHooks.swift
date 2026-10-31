#if SUNDIAL_DEV && os(macOS)
import AppKit

enum DebugHooks {
    static func install(custom: @escaping @MainActor (String, [String]) -> Void = { _, _ in }) {
        let name = Notification.Name("\(Bundle.main.bundleIdentifier ?? "app").debug")
        DistributedNotificationCenter.default().addObserver(forName: name, object: nil, queue: .main) { note in
            let command = note.object as? String ?? ""
            MainActor.assumeIsolated { run(command, custom: custom) }
        }
    }

    static func run(_ command: String, custom: (String, [String]) -> Void) {
        guard let command = DebugCommand(command) else { return }
        switch command {
        case .snap(let path, let title):
            snap(window(titled: title), to: path)
        case .frame(let width, let height):
            guard let window = window(titled: nil) else { return }
            let frame = window.frame
            window.setFrame(NSRect(x: frame.minX, y: frame.maxY - height, width: width, height: height), display: true)
        case .action(let name):
            if !NSApp.sendAction(Selector(name), to: nil, from: nil) {
                _ = window(titled: nil)?.firstResponder?.tryToPerform(Selector(name), with: nil)
            }
        case .key(let code, let modifiers, let characters):
            guard let window = window(titled: nil) else { return }
            let flags = modifiers.reduce(into: NSEvent.ModifierFlags()) { $0.insert(flag(for: $1)) }
            for type in [NSEvent.EventType.keyDown, .keyUp] {
                guard let event = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code) else { continue }
                if type == .keyDown, NSApp.mainMenu?.performKeyEquivalent(with: event) == true || window.performKeyEquivalent(with: event) { continue }
                window.sendEvent(event)
            }
        case .type(let text):
            (window(titled: nil)?.firstResponder as? NSTextInputClient)?.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        case .custom(let name, let arguments):
            custom(name, arguments)
        }
    }

    static func snap(_ window: NSWindow?, to path: String) {
        guard let window, let root = window.contentView?.superview, let layer = root.layer,
              let context = CGContext(data: nil, width: Int(root.bounds.width * window.backingScaleFactor), height: Int(root.bounds.height * window.backingScaleFactor), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        context.scaleBy(x: window.backingScaleFactor, y: window.backingScaleFactor)
        context.setFillColor(window.backgroundColor.cgColor)
        context.fill(root.bounds)
        layer.render(in: context)
        glassContents(in: root).compactMap(\.layer).forEach { render($0, in: context, root: layer) }
        guard let image = context.makeImage() else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: URL(filePath: path))
    }

    private static func glassContents(in view: NSView) -> [NSView] {
        if let glass = view as? NSGlassEffectView {
            return glass.contentView.map { [$0] } ?? []
        }
        return view.subviews.flatMap(glassContents)
    }

    private static func render(_ layer: CALayer, in context: CGContext, root: CALayer) {
        guard !layer.isHidden, layer.opacity > 0, !isBackdrop(layer) else { return }
        guard containsBackdrop(layer) else {
            let origin = layer.convert(layer.bounds.origin, to: root)
            let next = layer.convert(CGPoint(x: layer.bounds.minX, y: layer.bounds.minY + 1), to: root)
            context.saveGState()
            context.translateBy(x: origin.x, y: origin.y)
            context.scaleBy(x: 1, y: next.y < origin.y ? -1 : 1)
            context.translateBy(x: -layer.bounds.minX, y: -layer.bounds.minY)
            layer.render(in: context)
            context.restoreGState()
            return
        }
        layer.sublayers?.forEach { render($0, in: context, root: root) }
    }

    private static func isBackdrop(_ layer: CALayer) -> Bool {
        String(describing: type(of: layer)).contains("Backdrop")
    }

    private static func containsBackdrop(_ layer: CALayer) -> Bool {
        isBackdrop(layer) || layer.sublayers?.contains(where: containsBackdrop) == true
    }

    static func window(titled title: String?) -> NSWindow? {
        if let title {
            return NSApp.windows.first { $0.title == title }
        }
        return NSApp.mainWindow ?? NSApp.orderedWindows.first { $0.isVisible && $0.canBecomeMain }
    }

    private static func flag(for modifier: DebugCommand.Modifier) -> NSEvent.ModifierFlags {
        switch modifier {
        case .command: .command
        case .shift: .shift
        case .option: .option
        case .control: .control
        case .function: .function
        case .numericPad: .numericPad
        }
    }
}
#endif
