import Foundation

enum MarkdownOutlineExtractor {
    static func extract(from source: String) -> [MarkdownOutlineItem] {
        var inFence = false
        var usedAnchors: [String: Int] = [:]

        return source
            .split(separator: "\n", omittingEmptySubsequences: false)
            .enumerated()
            .compactMap { index, rawLine in
                let line = String(rawLine)
                if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    inFence.toggle()
                    return nil
                }

                guard !inFence else {
                    return nil
                }

                guard let match = headingMatch(in: line) else {
                    return nil
                }

                let baseAnchor = slug(match.title)
                let count = usedAnchors[baseAnchor, default: 0]
                usedAnchors[baseAnchor] = count + 1
                let anchor = count == 0 ? baseAnchor : "\(baseAnchor)-\(count)"

                return MarkdownOutlineItem(
                    title: match.title,
                    level: match.level,
                    anchor: anchor,
                    line: index
                )
            }
    }

    private static func headingMatch(in line: String) -> (level: Int, title: String)? {
        guard line.hasPrefix("#") else {
            return nil
        }

        let hashes = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(hashes) else {
            return nil
        }

        let remainder = line.dropFirst(hashes)
        guard remainder.first == " " || remainder.first == "\t" else {
            return nil
        }

        let cleaned = remainder
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: #"#+\s*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        guard !cleaned.isEmpty else {
            return nil
        }

        return (hashes, cleaned)
    }

    private static func slug(_ title: String) -> String {
        var slug = ""
        var previousWasDash = false

        for scalar in title.lowercased().unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                slug.unicodeScalars.append(scalar)
                previousWasDash = false
            } else if !previousWasDash {
                slug.append("-")
                previousWasDash = true
            }
        }

        return slug.trimmingCharacters(in: CharacterSet(charactersIn: "-")).nilIfEmpty ?? "section"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
