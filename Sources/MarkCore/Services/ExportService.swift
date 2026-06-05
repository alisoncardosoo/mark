import Foundation

public struct ExportService: Sendable {
    private let renderer: MarkdownRenderer

    public init(renderer: MarkdownRenderer = MarkdownRenderer()) {
        self.renderer = renderer
    }

    public func htmlDocument(for source: String, baseURL: URL?) -> String {
        renderer.render(source: source, baseURL: baseURL).html
    }

    public func htmlData(for source: String, baseURL: URL?) -> Data {
        Data(htmlDocument(for: source, baseURL: baseURL).utf8)
    }

    public func defaultExportName(for sourceURL: URL?, extension fileExtension: String) -> String {
        let candidate = sourceURL?.deletingPathExtension().lastPathComponent
        let stem = candidate?.isEmpty == false ? candidate! : "Untitled"
        return "\(stem).\(fileExtension)"
    }
}
