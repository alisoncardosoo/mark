import Foundation

enum MarkdownSecurity {
    static func diagnostics(for source: String) -> Set<MarkdownDiagnostic> {
        var diagnostics: Set<MarkdownDiagnostic> = []

        if source.range(of: #"<\s*/?\s*[a-zA-Z][^>]*>"#, options: .regularExpression) != nil {
            diagnostics.insert(.rawHTMLRemoved)
        }

        if containsUnsafeLink(in: source) {
            diagnostics.insert(.unsafeLinkRemoved)
        }

        return diagnostics
    }

    static func containsUnsafeLink(in value: String) -> Bool {
        value.range(of: #"(?i)(javascript|vbscript|data)\s*:"#, options: .regularExpression) != nil
    }

    static func removeUnsafeLinks(fromHTML html: String) -> String {
        var output = html.replacingOccurrences(
            of: #"(href|src)=\s*"\s*(?i:(javascript|vbscript|data):)[^"]*""#,
            with: #"$1="""#,
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(href|src)=\s*'\s*(?i:(javascript|vbscript|data):)[^']*'"#,
            with: #"$1="""#,
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"(href|src)=\s*(?i:(javascript|vbscript|data):)[^\s>]*"#,
            with: #"$1="""#,
            options: .regularExpression
        )
        return output
    }

    static func removeUnsafeRawHTML(fromHTML html: String) -> String {
        var output = html
        let blockedTags = [
            "script",
            "iframe",
            "object",
            "embed",
            "style",
            "link",
            "meta",
            "base",
            "form",
            "button",
            "textarea",
            "select"
        ]

        for tag in blockedTags {
            output = output.replacingOccurrences(
                of: #"(?is)<\#(tag)\b[^>]*>.*?</\#(tag)\s*>"#,
                with: "",
                options: .regularExpression
            )
            output = output.replacingOccurrences(
                of: #"(?is)<\#(tag)\b[^>]*?/?>"#,
                with: "",
                options: .regularExpression
            )
        }

        return output
    }
}
