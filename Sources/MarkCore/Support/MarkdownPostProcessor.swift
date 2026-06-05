import Foundation

enum MarkdownPostProcessor {
    static func addHeadingAnchors(to html: String, outline: [MarkdownOutlineItem]) -> String {
        var output = html

        for item in outline {
            let openingTag = "<h\(item.level)>"
            guard let range = output.range(of: openingTag) else {
                continue
            }
            output.replaceSubrange(range, with: #"<h\#(item.level) id="\#(item.anchor)">"#)
        }

        return output
    }

    static func rewriteRelativeURLs(in html: String, baseURL: URL?) -> String {
        guard let baseDirectory = baseURL?.deletingLastPathComponent() else {
            return html
        }

        var output = html
        output = rewriteAttribute("src", in: output, baseDirectory: baseDirectory)
        output = rewriteAttribute("href", in: output, baseDirectory: baseDirectory)
        return output
    }

    static func removeDangerousAttributes(from html: String) -> String {
        html.replacingOccurrences(
            of: #"\s+on[a-zA-Z]+\s*=\s*("[^"]*"|'[^']*'|[^\s>]+)"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func rewriteAttribute(_ attribute: String, in html: String, baseDirectory: URL) -> String {
        let pattern = #"\#(attribute)="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return html
        }

        let source = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: source.length)).reversed()
        var output = html

        for match in matches {
            guard match.numberOfRanges == 2 else {
                continue
            }

            let value = source.substring(with: match.range(at: 1))
            guard shouldRewrite(value) else {
                continue
            }

            let absolute = baseDirectory.appendingPathComponent(value).absoluteString
            if let range = Range(match.range(at: 1), in: output) {
                output.replaceSubrange(range, with: absolute)
            }
        }

        return output
    }

    private static func shouldRewrite(_ value: String) -> Bool {
        if value.hasPrefix("#") || value.hasPrefix("/") {
            return false
        }

        if let scheme = URL(string: value)?.scheme, !scheme.isEmpty {
            return false
        }

        return true
    }
}
