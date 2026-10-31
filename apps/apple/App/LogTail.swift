import Foundation

struct LogTail {
    enum Update: Equatable {
        case replace(String)
        case append(String)
    }

    let url: URL
    let limit: Int
    private var offset: UInt64 = 0
    private var shownBytes = 0
    private var pending: [UInt8] = []
    private var hasRead = false

    init(url: URL, limit: Int = RunStore.maxLogBytes) {
        self.url = url
        self.limit = limit
    }

    mutating func read() -> Update? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            guard !hasRead else { return nil }
            hasRead = true
            return .replace("")
        }
        defer { try? handle.close() }
        let size = (try? handle.seekToEnd()) ?? 0
        let isFresh = !hasRead || size < offset || Int(size - offset) + shownBytes > limit * 2
        let start: UInt64 = isFresh ? (size > UInt64(limit) ? size - UInt64(limit) : 0) : offset
        guard isFresh || size > offset else { return nil }
        try? handle.seek(toOffset: start)
        let data = (try? handle.readToEnd()) ?? Data()
        hasRead = true
        offset = start + UInt64(data.count)
        let bytes = (isFresh ? [] : pending) + [UInt8](data)
        let complete = LogTail.completeLength(bytes)
        pending = Array(bytes[complete...])
        let text = String(decoding: bytes[..<complete], as: UTF8.self)
        if isFresh {
            shownBytes = complete
            return .replace(text)
        }
        guard complete > 0 else { return nil }
        shownBytes += complete
        return .append(text)
    }

    static func completeLength(_ bytes: [UInt8]) -> Int {
        var index = bytes.count - 1
        while index >= max(0, bytes.count - 4) {
            let byte = bytes[index]
            if byte & 0xC0 != 0x80 {
                let needed = byte >= 0xF0 ? 4 : byte >= 0xE0 ? 3 : byte >= 0xC0 ? 2 : 1
                return bytes.count - index < needed ? index : bytes.count
            }
            index -= 1
        }
        return bytes.count
    }
}
