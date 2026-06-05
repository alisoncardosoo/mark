import Foundation

enum MarkdownHTMLDocument {
    static func wrap(fragment: String) -> String {
        let css = (try? String(contentsOf: Bundle.module.url(forResource: "github-markdown", withExtension: "css") ?? URL(fileURLWithPath: ""), encoding: .utf8)) ?? fallbackCSS
        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
        \(css)
          </style>
        </head>
        <body>
          <article class="markdown-body">
        \(fragment)
          </article>
        </body>
        </html>
        """
    }

    private static let fallbackCSS = """
        body { margin: 0; font: 16px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
        .markdown-body { box-sizing: border-box; max-width: 980px; margin: 0 auto; padding: 36px 45px; line-height: 1.55; color: #1f2328; }
        @media (prefers-color-scheme: dark) { body { background: #0d1117; } .markdown-body { color: #e6edf3; } }
        """
}
