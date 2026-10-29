import Foundation

final class FileMonitor {
    private var source: DispatchSourceFileSystemObject?

    init?(url: URL, onChange: @escaping () -> Void) {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .delete, .rename],
            queue: .main
        )
        source.setEventHandler(handler: onChange)
        source.setCancelHandler { close(descriptor) }
        source.resume()
        self.source = source
    }

    static func changes(of url: URL) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let monitor = FileMonitor(url: url) { continuation.yield() }
            continuation.onTermination = { _ in withExtendedLifetime(monitor) {} }
        }
    }

    deinit {
        source?.cancel()
    }
}
