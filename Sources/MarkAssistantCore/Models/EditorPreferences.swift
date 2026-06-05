import Foundation

public enum PreviewTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }
}

public struct EditorPreferences: Equatable, Sendable {
    public var theme: PreviewTheme
    public var editorFontSize: Double
    public var previewZoom: Double
    public var splitFraction: Double
    public var opensRecentDocuments: Bool

    public init(
        theme: PreviewTheme = .system,
        editorFontSize: Double = 14,
        previewZoom: Double = 1,
        splitFraction: Double = 0.5,
        opensRecentDocuments: Bool = true
    ) {
        self.theme = theme
        self.editorFontSize = editorFontSize
        self.previewZoom = previewZoom
        self.splitFraction = splitFraction
        self.opensRecentDocuments = opensRecentDocuments
    }
}
