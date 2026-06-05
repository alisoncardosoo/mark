import Foundation

public enum EditorDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case editor
    case split
    case preview

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .editor:
            "Editor"
        case .split:
            "Split"
        case .preview:
            "Preview"
        }
    }
}
