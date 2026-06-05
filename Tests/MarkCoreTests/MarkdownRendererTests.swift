import Foundation
import Testing
@testable import MarkCore

@Suite("Markdown renderer")
struct MarkdownRendererTests {
    @Test("renders GitHub-flavored Markdown features")
    func rendersGFMFeatures() throws {
        let source = try fixture("gfm.md")
        let renderer = MarkdownRenderer()

        let rendered = renderer.render(source: source, baseURL: URL(fileURLWithPath: "/tmp/docs/README.md"))

        #expect(rendered.html.contains(#"<article class="markdown-body">"#))
        #expect(rendered.html.contains("<del>old</del>"))
        #expect(rendered.html.contains("<table>"))
        #expect(rendered.html.contains(#"type="checkbox""#))
        #expect(rendered.html.contains(#"<code class="language-swift">"#) || rendered.html.contains(#"<code class="language-swift "#))
        #expect(rendered.html.contains(#"src="file:///tmp/docs/images/logo.png""#))
    }

    @Test("extracts stable outline from headings")
    func extractsOutline() {
        let renderer = MarkdownRenderer()

        let rendered = renderer.render(source: "# One\n\n### Three\n\n## Two", baseURL: nil)

        #expect(rendered.outline.map(\.title) == ["One", "Three", "Two"])
        #expect(rendered.outline.map(\.level) == [1, 3, 2])
        #expect(rendered.outline.map(\.anchor) == ["one", "three", "two"])
    }

    @Test("scrubs dangerous HTML and links")
    func scrubsDangerousInput() {
        let renderer = MarkdownRenderer()

        let rendered = renderer.render(
            source: """
            <script>alert(1)</script>

            [bad](javascript:alert(1))

            <img src=x onerror=alert(1)>
            """,
            baseURL: nil
        )

        #expect(!rendered.html.localizedCaseInsensitiveContains("<script"))
        #expect(!rendered.html.localizedCaseInsensitiveContains("javascript:"))
        #expect(!rendered.html.localizedCaseInsensitiveContains("onerror"))
        #expect(rendered.diagnostics.contains(.rawHTMLRemoved))
    }

    @Test("allows safe remote image HTML used by GitHub badges")
    func allowsSafeRemoteImageHTML() {
        let renderer = MarkdownRenderer()
        let source = #"""
        <p align="center">
        <img src="https://skillicons.dev/icons?i=html,css,js,ts,react,nextjs,nodejs,python" />
        </p>
        """#

        let rendered = renderer.render(source: source, baseURL: nil)

        #expect(rendered.html.contains(#"src="https://skillicons.dev/icons?i=html,css,js,ts,react,nextjs,nodejs,python""#))
        #expect(rendered.html.contains(#"align="center""#) || rendered.html.contains(#"text-align: center"#))
    }
}

private func fixture(_ name: String) throws -> String {
    let url = Bundle.module.url(forResource: name, withExtension: nil)!
    return try String(contentsOf: url, encoding: .utf8)
}
