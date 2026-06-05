import CoreGraphics

enum EditorLayoutMetrics {
    static let splitDividerWidth: CGFloat = 8
    static let outlineDividerWidth: CGFloat = 1
    static let outlineWidth: CGFloat = 220
    static let minEditorWidth: CGFloat = 300
    static let minPreviewContentWidth: CGFloat = 320

    static func outlineReservedWidth(isVisible: Bool) -> CGFloat {
        isVisible ? outlineDividerWidth + outlineWidth : 0
    }

    static func previewPaneMinimumWidth(showOutline: Bool) -> CGFloat {
        minPreviewContentWidth + outlineReservedWidth(isVisible: showOutline)
    }
}
