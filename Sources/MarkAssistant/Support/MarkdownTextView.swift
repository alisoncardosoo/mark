import AppKit
import MarkAssistantCore
import SwiftUI

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: Double
    let searchTerm: String
    let syncProgress: Double
    let syncSource: ScrollSyncSource?
    let isScrollSyncEnabled: Bool
    let onSelectionLineChanged: (Int) -> Void
    let onScrollProgressChanged: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            onSelectionLineChanged: onSelectionLineChanged,
            onScrollProgressChanged: onScrollProgressChanged
        )
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 18, height: 18)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        scrollView.contentView.postsBoundsChangedNotifications = true
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        if textView.string != text {
            textView.string = text
        }

        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        context.coordinator.isScrollSyncEnabled = isScrollSyncEnabled
        if isScrollSyncEnabled, syncSource == .preview {
            context.coordinator.scroll(to: syncProgress)
        }
        context.coordinator.highlight(searchTerm: searchTerm)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding private var text: String
        private let onSelectionLineChanged: (Int) -> Void
        private let onScrollProgressChanged: (Double) -> Void
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isScrollSyncEnabled = false
        private var isApplyingExternalScroll = false

        init(
            text: Binding<String>,
            onSelectionLineChanged: @escaping (Int) -> Void,
            onScrollProgressChanged: @escaping (Double) -> Void
        ) {
            self._text = text
            self.onSelectionLineChanged = onSelectionLineChanged
            self.onScrollProgressChanged = onScrollProgressChanged
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            text = textView.string
            publishSelectionLine(from: textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            publishSelectionLine(from: textView)
        }

        @MainActor
        func highlight(searchTerm: String) {
            guard let textView else {
                return
            }

            let storage = textView.textStorage
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            storage?.removeAttribute(.backgroundColor, range: fullRange)

            guard !searchTerm.isEmpty else {
                return
            }

            let source = textView.string as NSString
            var searchRange = fullRange
            while searchRange.location < source.length {
                let found = source.range(of: searchTerm, options: [.caseInsensitive], range: searchRange)
                guard found.location != NSNotFound else {
                    break
                }
                storage?.addAttribute(
                    .backgroundColor,
                    value: NSColor(calibratedRed: 0.48, green: 0.35, blue: 0.86, alpha: 0.22),
                    range: found
                )
                let nextLocation = found.location + max(found.length, 1)
                searchRange = NSRange(location: nextLocation, length: source.length - nextLocation)
            }
        }

        @MainActor
        private func publishSelectionLine(from textView: NSTextView) {
            let selection = textView.selectedRange()
            let prefix = (textView.string as NSString).substring(to: min(selection.location, (textView.string as NSString).length))
            let line = prefix.reduce(0) { count, character in
                character == "\n" ? count + 1 : count
            }
            onSelectionLineChanged(line)
        }

        @MainActor
        func scroll(to progress: Double) {
            guard let scrollView, let documentView = scrollView.documentView else {
                return
            }

            let maxY = max(documentView.bounds.height - scrollView.contentView.bounds.height, 0)
            let y = maxY * min(max(progress, 0), 1)
            isApplyingExternalScroll = true
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: y))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.isApplyingExternalScroll = false
            }
        }

        @objc
        @MainActor
        func boundsDidChange(_ notification: Notification) {
            guard isScrollSyncEnabled, !isApplyingExternalScroll,
                  let scrollView,
                  let documentView = scrollView.documentView else {
                return
            }

            let maxY = max(documentView.bounds.height - scrollView.contentView.bounds.height, 0)
            guard maxY > 0 else {
                onScrollProgressChanged(0)
                return
            }

            let progress = scrollView.contentView.bounds.origin.y / maxY
            onScrollProgressChanged(min(max(progress, 0), 1))
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}
