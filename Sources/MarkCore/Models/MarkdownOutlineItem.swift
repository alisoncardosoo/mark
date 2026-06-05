import Foundation

public struct MarkdownOutlineItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let level: Int
    public let anchor: String
    public let line: Int

    public init(title: String, level: Int, anchor: String, line: Int) {
        self.id = "\(line)-\(anchor)"
        self.title = title
        self.level = level
        self.anchor = anchor
        self.line = line
    }
}
