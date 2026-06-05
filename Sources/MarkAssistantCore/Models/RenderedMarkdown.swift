import Foundation

public struct RenderedMarkdown: Equatable, Sendable {
    public let html: String
    public let outline: [MarkdownOutlineItem]
    public let diagnostics: Set<MarkdownDiagnostic>

    public init(
        html: String,
        outline: [MarkdownOutlineItem],
        diagnostics: Set<MarkdownDiagnostic> = []
    ) {
        self.html = html
        self.outline = outline
        self.diagnostics = diagnostics
    }
}

public enum MarkdownDiagnostic: String, CaseIterable, Hashable, Sendable {
    case rawHTMLRemoved
    case unsafeLinkRemoved
}
