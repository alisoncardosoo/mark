import MarkCore
import SwiftUI

struct PreviewPane: View {
    let rendered: RenderedMarkdown
    let query: String
    let currentAnchor: String?
    let showOutline: Bool
    let previewZoom: Double
    let previewTheme: PreviewTheme
    let syncProgress: Double
    let syncSource: ScrollSyncSource?
    let isScrollSyncEnabled: Bool
    let onOutlineSelection: (String) -> Void
    let onScrollProgressChanged: (Double) -> Void

    var body: some View {
        HStack(spacing: 0) {
            MarkdownPreviewView(
                html: rendered.html,
                searchTerm: query,
                scrollAnchor: currentAnchor,
                zoom: previewZoom,
                theme: previewTheme,
                syncProgress: syncProgress,
                syncSource: syncSource,
                isScrollSyncEnabled: isScrollSyncEnabled,
                onScrollProgressChanged: onScrollProgressChanged
            )
            .frame(minWidth: EditorLayoutMetrics.minPreviewContentWidth)

            if showOutline {
                Divider()
                    .frame(width: EditorLayoutMetrics.outlineDividerWidth)

                OutlineView(
                    items: rendered.outline,
                    selectedAnchor: currentAnchor,
                    onSelection: onOutlineSelection
                )
                .frame(width: EditorLayoutMetrics.outlineWidth)
            }
        }
    }
}
