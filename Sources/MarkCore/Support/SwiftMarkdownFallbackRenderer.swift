import Foundation

enum SwiftMarkdownFallbackRenderer {
    static func render(_ source: String) -> String {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var output: [String] = []
        var paragraph: [String] = []
        var inCode = false
        var codeLanguage = ""
        var tableBuffer: [String] = []
        var listOpen = false

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            output.append("<p>\(inline(paragraph.joined(separator: " ")))</p>")
            paragraph.removeAll()
        }

        func flushTable() {
            guard tableBuffer.count >= 2 else {
                tableBuffer.forEach { paragraph.append($0) }
                tableBuffer.removeAll()
                return
            }

            let header = cells(tableBuffer[0])
            let rows = tableBuffer.dropFirst(2).map(cells)
            output.append("<table><thead><tr>\(header.map { "<th>\(inline($0))</th>" }.joined())</tr></thead><tbody>")
            for row in rows {
                output.append("<tr>\(row.map { "<td>\(inline($0))</td>" }.joined())</tr>")
            }
            output.append("</tbody></table>")
            tableBuffer.removeAll()
        }

        func closeList() {
            if listOpen {
                output.append("</ul>")
                listOpen = false
            }
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") {
                flushParagraph()
                flushTable()
                closeList()
                if inCode {
                    output.append("</code></pre>")
                    inCode = false
                    codeLanguage = ""
                } else {
                    inCode = true
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    output.append(#"<pre><code class="language-\#(escape(codeLanguage))">"#)
                }
                continue
            }

            if inCode {
                output.append(escape(rawLine))
                continue
            }

            if line.isEmpty {
                flushParagraph()
                flushTable()
                closeList()
                continue
            }

            if let heading = heading(in: line) {
                flushParagraph()
                flushTable()
                closeList()
                output.append("<h\(heading.level)>\(inline(heading.title))</h\(heading.level)>")
                continue
            }

            if line.hasPrefix("|") && line.hasSuffix("|") {
                flushParagraph()
                closeList()
                tableBuffer.append(line)
                continue
            } else {
                flushTable()
            }

            if let list = taskListItem(in: line) {
                flushParagraph()
                if !listOpen {
                    output.append("<ul>")
                    listOpen = true
                }
                let checked = list.checked ? #" checked="""# : ""
                output.append(#"<li class="task-list-item"><input type="checkbox" disabled=""\#(checked)> \#(inline(list.text))</li>"#)
                continue
            }

            paragraph.append(line)
        }

        flushParagraph()
        flushTable()
        closeList()
        return output.joined(separator: "\n")
    }

    private static func heading(in line: String) -> (level: Int, title: String)? {
        let level = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(level), line.dropFirst(level).first == " " else {
            return nil
        }
        return (level, String(line.dropFirst(level)).trimmingCharacters(in: .whitespaces))
    }

    private static func taskListItem(in line: String) -> (checked: Bool, text: String)? {
        let patterns = [
            (#"^- \[x\]\s+(.+)$"#, true),
            (#"^- \[X\]\s+(.+)$"#, true),
            (#"^- \[ \]\s+(.+)$"#, false)
        ]

        for (pattern, checked) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                continue
            }
            let source = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: source.length))
            if let match = matches.first, match.numberOfRanges == 2 {
                return (checked, source.substring(with: match.range(at: 1)))
            }
        }

        return nil
    }

    private static func cells(_ row: String) -> [String] {
        row.trimmingCharacters(in: CharacterSet(charactersIn: "|"))
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private static func inline(_ text: String) -> String {
        var output = escape(text)
        output = output.replacingOccurrences(of: #"~~(.+?)~~"#, with: #"<del>$1</del>"#, options: .regularExpression)
        output = output.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^\)]+)\)"#, with: #"<img src="$2" alt="$1">"#, options: .regularExpression)
        output = output.replacingOccurrences(of: #"`([^`]+)`"#, with: #"<code>$1</code>"#, options: .regularExpression)
        output = output.replacingOccurrences(of: #"(?<!!)\[([^\]]+)\]\(([^\)]+)\)"#, with: #"<a href="$2">$1</a>"#, options: .regularExpression)
        return output
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
