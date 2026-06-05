import Foundation
#if canImport(cmark_gfm)
import cmark_gfm
#endif
#if canImport(cmark_gfm_extensions)
import cmark_gfm_extensions
#endif
#if os(macOS)
import Darwin
#endif

public struct MarkdownRenderer: Sendable {
    public init() {}

    public func render(source: String, baseURL: URL?) -> RenderedMarkdown {
        let outline = MarkdownOutlineExtractor.extract(from: source)
        let diagnostics = MarkdownSecurity.diagnostics(for: source)
        let fragment = renderFragment(source: source)
        var processed = MarkdownPostProcessor.addHeadingAnchors(to: fragment, outline: outline)
        processed = MarkdownPostProcessor.rewriteRelativeURLs(in: processed, baseURL: baseURL)
        processed = MarkdownSecurity.removeUnsafeRawHTML(fromHTML: processed)
        processed = MarkdownPostProcessor.removeDangerousAttributes(from: processed)
        processed = MarkdownSecurity.removeUnsafeLinks(fromHTML: processed)

        return RenderedMarkdown(
            html: MarkdownHTMLDocument.wrap(fragment: processed),
            outline: outline,
            diagnostics: diagnostics
        )
    }

    private func renderFragment(source: String) -> String {
        #if canImport(cmark_gfm) && canImport(cmark_gfm_extensions)
        if let html = CMarkGFMBridge.render(source) {
            return html
        }
        #endif

        return SwiftMarkdownFallbackRenderer.render(source)
    }
}

#if canImport(cmark_gfm) && canImport(cmark_gfm_extensions)
private enum CMarkGFMBridge {
    static func render(_ source: String) -> String? {
        cmark_gfm_core_extensions_ensure_registered()

        let options = CMARK_OPT_DEFAULT | CMARK_OPT_UNSAFE
        guard let parser = cmark_parser_new(options) else {
            return nil
        }
        defer { cmark_parser_free(parser) }

        for name in ["table", "strikethrough", "autolink", "tagfilter", "tasklist"] {
            guard let syntaxExtension = cmark_find_syntax_extension(name) else {
                continue
            }
            cmark_parser_attach_syntax_extension(parser, syntaxExtension)
        }

        source.withCString { buffer in
            cmark_parser_feed(parser, buffer, strlen(buffer))
        }

        guard let document = cmark_parser_finish(parser) else {
            return nil
        }
        defer { cmark_node_free(document) }

        guard let htmlPointer = cmark_render_html(
            document,
            options,
            cmark_parser_get_syntax_extensions(parser)
        ) else {
            return nil
        }
        defer { free(htmlPointer) }

        return String(cString: htmlPointer)
    }
}
#endif
