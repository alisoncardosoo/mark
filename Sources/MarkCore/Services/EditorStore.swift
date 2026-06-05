import Foundation
import Observation

@Observable
public final class EditorStore {
    public var displayMode: EditorDisplayMode
    public var renderedMarkdown: RenderedMarkdown
    public var query: String
    public var showOutline: Bool
    public var currentAnchor: String?
    public var isRendering: Bool
    public var isScrollSyncEnabled: Bool
    public var scrollSyncProgress: Double
    public var scrollSyncSource: ScrollSyncSource?
    public var splitFraction: Double
    public var splitBalanceRequestID: Int

    private let renderer: MarkdownRenderer

    public init(
        source: String,
        baseURL: URL?,
        renderer: MarkdownRenderer = MarkdownRenderer(),
        displayMode: EditorDisplayMode = .split,
        showOutline: Bool = true,
        isScrollSyncEnabled: Bool = false,
        splitFraction: Double = 0.5
    ) {
        self.renderer = renderer
        self.displayMode = displayMode
        self.renderedMarkdown = renderer.render(source: source, baseURL: baseURL)
        self.query = ""
        self.showOutline = showOutline
        self.currentAnchor = nil
        self.isRendering = false
        self.isScrollSyncEnabled = isScrollSyncEnabled
        self.scrollSyncProgress = 0
        self.scrollSyncSource = nil
        self.splitFraction = min(max(splitFraction, 0.25), 0.75)
        self.splitBalanceRequestID = 0
    }

    public func render(source: String, baseURL: URL?) {
        isRendering = true
        let next = renderer.render(source: source, baseURL: baseURL)
        renderedMarkdown = next
        isRendering = false
    }

    public func anchor(forEditorLine line: Int) -> String? {
        renderedMarkdown.outline.last(where: { $0.line <= line })?.anchor
    }

    public func updateScrollSync(progress: Double, source: ScrollSyncSource) {
        scrollSyncProgress = min(max(progress, 0), 1)
        scrollSyncSource = source
    }

    public func setSplitFraction(_ fraction: Double) {
        splitFraction = min(max(fraction, 0.25), 0.75)
    }

    public func resetSplitFraction() {
        splitFraction = 0.5
    }

    public func requestBalancedSplit() {
        splitBalanceRequestID += 1
    }

    public func resetSplitFraction(
        availableWidth: Double,
        reservedTrailingWidth: Double,
        dividerWidth: Double
    ) {
        let totalWidth = max(availableWidth, 1)
        let usableWidth = max(totalWidth - reservedTrailingWidth - dividerWidth, 1)
        setSplitFraction((usableWidth / 2) / totalWidth)
    }
}
