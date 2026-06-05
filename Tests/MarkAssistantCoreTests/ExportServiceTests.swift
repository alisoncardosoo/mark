import Foundation
import Testing
@testable import MarkAssistantCore

@Suite("Export service")
struct ExportServiceTests {
    @Test("writes an HTML document with rendered Markdown")
    func writesHTMLDocument() throws {
        let service = ExportService(renderer: MarkdownRenderer())
        let html = service.htmlDocument(for: "# Title", baseURL: nil)

        #expect(html.hasPrefix("<!doctype html>"))
        #expect(html.contains("<h1"))
        #expect(html.contains("Title"))
        #expect(html.contains("github-markdown"))
    }

    @Test("creates deterministic export file names")
    func deterministicExportFileNames() {
        let service = ExportService(renderer: MarkdownRenderer())

        #expect(service.defaultExportName(for: URL(fileURLWithPath: "/tmp/README.md"), extension: "html") == "README.html")
        #expect(service.defaultExportName(for: nil, extension: "pdf") == "Untitled.pdf")
    }
}
