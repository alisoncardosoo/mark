import MarkCore
import SwiftUI

struct EditorShellView: View {
    @Binding var document: MarkdownDocument
    let fileURL: URL?
    let store: EditorStore
    let editorFontSize: Double
    let previewZoom: Double
    let previewTheme: PreviewTheme

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                query: Binding(
                    get: { store.query },
                    set: { store.query = $0 }
                ),
                isRendering: store.isRendering
            )
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            Divider()

            workArea
        }
        .task(id: document.text) {
            store.isRendering = true
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            store.render(source: document.text, baseURL: fileURL)
        }
    }

    @ViewBuilder
    private var workArea: some View {
        switch store.displayMode {
        case .editor:
            editorPane
        case .preview:
            previewPane
        case .split:
            splitPane
        }
    }

    private var splitPane: some View {
        GeometryReader { proxy in
            let dividerWidth = EditorLayoutMetrics.splitDividerWidth
            let availableWidth = max(proxy.size.width, 1)
            let minEditorWidth = EditorLayoutMetrics.minEditorWidth
            let minPreviewWidth = EditorLayoutMetrics.previewPaneMinimumWidth(showOutline: store.showOutline)
            let proposedEditorWidth = availableWidth * store.splitFraction
            let editorWidth = min(
                max(proposedEditorWidth, minEditorWidth),
                max(availableWidth - minPreviewWidth - dividerWidth, minEditorWidth)
            )
            let previewWidth = max(availableWidth - editorWidth - dividerWidth, minPreviewWidth)

            HStack(spacing: 0) {
                editorPane
                    .frame(width: editorWidth)

                SplitDivider()
                    .frame(width: dividerWidth)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let nextWidth = editorWidth + value.translation.width
                                store.setSplitFraction(nextWidth / max(availableWidth, 1))
                            }
                    )

                previewPane
                    .frame(width: previewWidth)
            }
            .onChange(of: store.splitBalanceRequestID) { _, _ in
                balanceSplit(availableWidth: availableWidth)
            }
        }
    }

    private var editorPane: some View {
        MarkdownTextView(
            text: $document.text,
            fontSize: editorFontSize,
            searchTerm: store.query,
            syncProgress: store.scrollSyncProgress,
            syncSource: store.scrollSyncSource,
            isScrollSyncEnabled: store.isScrollSyncEnabled && store.displayMode == .split,
            onSelectionLineChanged: { line in
                store.currentAnchor = store.anchor(forEditorLine: line)
            },
            onScrollProgressChanged: { progress in
                guard store.isScrollSyncEnabled, store.displayMode == .split else {
                    return
                }
                store.updateScrollSync(progress: progress, source: .editor)
            }
        )
        .frame(minWidth: EditorLayoutMetrics.minEditorWidth)
    }

    private var previewPane: some View {
        PreviewPane(
            rendered: store.renderedMarkdown,
            query: store.query,
            currentAnchor: store.currentAnchor,
            showOutline: store.showOutline,
            previewZoom: previewZoom,
            previewTheme: previewTheme,
            syncProgress: store.scrollSyncProgress,
            syncSource: store.scrollSyncSource,
            isScrollSyncEnabled: store.isScrollSyncEnabled && store.displayMode == .split,
            onOutlineSelection: { anchor in
                store.currentAnchor = anchor
            },
            onScrollProgressChanged: { progress in
                guard store.isScrollSyncEnabled, store.displayMode == .split else {
                    return
                }
                store.updateScrollSync(progress: progress, source: .preview)
            }
        )
        .frame(minWidth: EditorLayoutMetrics.previewPaneMinimumWidth(showOutline: store.showOutline))
    }

    private func balanceSplit(availableWidth: CGFloat) {
        let outlineWidth = EditorLayoutMetrics.outlineReservedWidth(isVisible: store.showOutline)
        store.resetSplitFraction(
            availableWidth: Double(availableWidth),
            reservedTrailingWidth: Double(outlineWidth),
            dividerWidth: Double(EditorLayoutMetrics.splitDividerWidth)
        )
    }
}

private struct SplitDivider: View {
    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isHovering ? Color.markLilac.opacity(0.75) : Color.secondary.opacity(0.2))
                    .frame(width: isHovering ? 4 : 1)
            }
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .help("Drag to resize editor and preview")
    }
}
