import XCTest
@testable import SundialCore

final class LogTailTests: XCTestCase {
    private var url: URL!

    override func setUp() {
        url = makeTemporaryDirectory().appending(path: "run.log")
    }

    private func write(_ bytes: [UInt8]) throws {
        try Data(bytes).write(to: url)
    }

    private func append(_ bytes: [UInt8]) throws {
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data(bytes))
    }

    func testMissingFileReadsEmptyOnce() {
        var tail = LogTail(url: url)
        XCTAssertEqual(tail.read(), .replace(""))
        XCTAssertNil(tail.read())
    }

    func testFirstReadReplacesThenAppendsOnlyNewOutput() throws {
        try write(Array("hello\n".utf8))
        var tail = LogTail(url: url)
        XCTAssertEqual(tail.read(), .replace("hello\n"))
        XCTAssertNil(tail.read())
        try append(Array("world\n".utf8))
        XCTAssertEqual(tail.read(), .append("world\n"))
        XCTAssertNil(tail.read())
    }

    func testFirstReadKeepsOnlyTheTail() throws {
        try write(Array("hello world".utf8))
        var tail = LogTail(url: url, limit: 5)
        XCTAssertEqual(tail.read(), .replace("world"))
    }

    func testHoldsSplitCharactersUntilComplete() throws {
        let sun = Array("☀".utf8)
        try write(Array("a".utf8) + sun.prefix(1))
        var tail = LogTail(url: url)
        XCTAssertEqual(tail.read(), .replace("a"))
        try append(Array(sun[1..<2]))
        XCTAssertNil(tail.read())
        try append(Array(sun[2...]) + Array("b".utf8))
        XCTAssertEqual(tail.read(), .append("☀b"))
    }

    func testTruncatedFileIsReadAgain() throws {
        try write(Array("first run output".utf8))
        var tail = LogTail(url: url)
        _ = tail.read()
        try write(Array("new".utf8))
        XCTAssertEqual(tail.read(), .replace("new"))
    }

    func testOutputPastTwiceTheLimitReplacesWithTheTail() throws {
        try write(Array("abcd".utf8))
        var tail = LogTail(url: url, limit: 4)
        XCTAssertEqual(tail.read(), .replace("abcd"))
        try append(Array("efgh".utf8))
        XCTAssertEqual(tail.read(), .append("efgh"))
        try append(Array("i".utf8))
        XCTAssertEqual(tail.read(), .replace("fghi"))
        try append(Array("j".utf8))
        XCTAssertEqual(tail.read(), .append("j"))
    }

    func testCompleteLength() {
        XCTAssertEqual(LogTail.completeLength([]), 0)
        XCTAssertEqual(LogTail.completeLength(Array("ab".utf8)), 2)
        XCTAssertEqual(LogTail.completeLength(Array("é".utf8)), 2)
        XCTAssertEqual(LogTail.completeLength(Array("aé".utf8).dropLast()), 1)
        XCTAssertEqual(LogTail.completeLength(Array("a😀".utf8).dropLast()), 1)
        XCTAssertEqual(LogTail.completeLength(Array("a😀".utf8)), 5)
        XCTAssertEqual(LogTail.completeLength([0x80, 0x80, 0x80, 0x80, 0x80]), 5)
    }
}
