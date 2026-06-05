import AppKit
import MarkCore
import SwiftUI
import WebKit

struct MarkdownPreviewView: NSViewRepresentable {
    let html: String
    let searchTerm: String
    let scrollAnchor: String?
    let zoom: Double
    let theme: PreviewTheme
    let syncProgress: Double
    let syncSource: ScrollSyncSource?
    let isScrollSyncEnabled: Bool
    let onScrollProgressChanged: (Double) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScrollProgressChanged: onScrollProgressChanged)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(context.coordinator, name: "markScrollSync")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsBackForwardNavigationGestures = false
        context.coordinator.webView = webView
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: nil)
        }

        context.coordinator.isScrollSyncEnabled = isScrollSyncEnabled
        context.coordinator.apply(
            searchTerm: searchTerm,
            anchor: isScrollSyncEnabled ? nil : scrollAnchor,
            zoom: zoom,
            theme: theme,
            syncProgress: syncProgress,
            syncSource: syncSource
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var lastHTML = ""
        private var lastSearchTerm = ""
        private var lastAnchor: String?
        private var lastZoom = 1.0
        private var lastTheme = PreviewTheme.system
        private var lastSyncProgress = 0.0
        private var lastSyncSource: ScrollSyncSource?
        private let onScrollProgressChanged: (Double) -> Void
        var isScrollSyncEnabled = false

        init(onScrollProgressChanged: @escaping (Double) -> Void) {
            self.onScrollProgressChanged = onScrollProgressChanged
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            apply(
                searchTerm: lastSearchTerm,
                anchor: lastAnchor,
                zoom: lastZoom,
                theme: lastTheme,
                syncProgress: lastSyncProgress,
                syncSource: lastSyncSource,
                force: true
            )
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if url.scheme == "file" || url.fragment != nil {
                decisionHandler(.allow)
            } else {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        @MainActor
        func apply(
            searchTerm: String,
            anchor: String?,
            zoom: Double,
            theme: PreviewTheme,
            syncProgress: Double,
            syncSource: ScrollSyncSource?,
            force: Bool = false
        ) {
            guard let webView else {
                return
            }

            webView.evaluateJavaScript(Self.installScrollSyncScript())

            if force || lastTheme != theme {
                lastTheme = theme
                webView.evaluateJavaScript(Self.themeScript(for: theme))
            }

            if force || lastSearchTerm != searchTerm {
                lastSearchTerm = searchTerm
                webView.evaluateJavaScript(Self.highlightScript(for: searchTerm))
            }

            if force || lastAnchor != anchor {
                lastAnchor = anchor
                webView.evaluateJavaScript(Self.scrollScript(for: anchor ?? ""))
            }

            if force || abs(lastSyncProgress - syncProgress) > 0.002 || lastSyncSource != syncSource {
                lastSyncProgress = syncProgress
                lastSyncSource = syncSource
                if isScrollSyncEnabled, syncSource == .editor {
                    webView.evaluateJavaScript(Self.scrollProgressScript(for: syncProgress))
                }
            }

            if force || abs(lastZoom - zoom) > 0.001 {
                lastZoom = zoom
                webView.pageZoom = zoom
            }
        }

        @MainActor
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard isScrollSyncEnabled, message.name == "markScrollSync" else {
                return
            }

            if let progress = message.body as? Double {
                onScrollProgressChanged(progress)
            } else if let number = message.body as? NSNumber {
                onScrollProgressChanged(number.doubleValue)
            }
        }

        private static func javascriptString(_ value: String) -> String {
            let data = try? JSONSerialization.data(withJSONObject: [value])
            let array = data.flatMap { String(data: $0, encoding: .utf8) } ?? #"[""]"#
            return String(array.dropFirst().dropLast())
        }

        private static func scrollScript(for anchor: String) -> String {
            let escaped = javascriptString(anchor)
            return """
            (() => {
              const anchor = \(escaped);
              if (!anchor) return;
              const target = document.getElementById(anchor);
              if (target) target.scrollIntoView({ block: 'start', behavior: 'smooth' });
            })();
            """
        }

        private static func installScrollSyncScript() -> String {
            """
            (() => {
              if (window.__markScrollSyncInstalled) return;
              window.__markScrollSyncInstalled = true;
              window.__markApplyingExternalScroll = false;
              window.addEventListener('scroll', () => {
                if (window.__markApplyingExternalScroll) return;
                if (window.__markScrollSyncPending) return;
                window.__markScrollSyncPending = true;
                requestAnimationFrame(() => {
                  window.__markScrollSyncPending = false;
                  const maxY = Math.max(
                    document.documentElement.scrollHeight - window.innerHeight,
                    document.body.scrollHeight - window.innerHeight,
                    0
                  );
                  const progress = maxY <= 0 ? 0 : Math.min(Math.max(window.scrollY / maxY, 0), 1);
                  window.webkit.messageHandlers.markScrollSync.postMessage(progress);
                });
              }, { passive: true });
            })();
            """
        }

        private static func scrollProgressScript(for progress: Double) -> String {
            let safeProgress = min(max(progress, 0), 1)
            return """
            (() => {
              const progress = \(safeProgress);
              const maxY = Math.max(
                document.documentElement.scrollHeight - window.innerHeight,
                document.body.scrollHeight - window.innerHeight,
                0
              );
              window.__markApplyingExternalScroll = true;
              window.scrollTo({ top: maxY * progress, behavior: 'auto' });
              window.setTimeout(() => { window.__markApplyingExternalScroll = false; }, 80);
            })();
            """
        }

        private static func highlightScript(for term: String) -> String {
            let escaped = javascriptString(term)
            return """
            (() => {
              document.querySelectorAll('mark[data-mark-search]').forEach((node) => {
                const parent = node.parentNode;
                parent.replaceChild(document.createTextNode(node.textContent), node);
                parent.normalize();
              });
              const term = \(escaped);
              if (!term || term.trim().length === 0) return;
              const root = document.querySelector('.markdown-body');
              if (!root) return;
              const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
              const lower = term.toLowerCase();
              const matches = [];
              while (walker.nextNode()) {
                const node = walker.currentNode;
                const index = node.nodeValue.toLowerCase().indexOf(lower);
                if (index >= 0) matches.push({ node, index });
              }
              matches.forEach(({ node, index }) => {
                const range = document.createRange();
                range.setStart(node, index);
                range.setEnd(node, index + term.length);
                const mark = document.createElement('mark');
                mark.setAttribute('data-mark-search', 'true');
                range.surroundContents(mark);
              });
            })();
            """
        }

        private static func themeScript(for theme: PreviewTheme) -> String {
            let className: String
            switch theme {
            case .system:
                className = ""
            case .light:
                className = "mark-theme-light"
            case .dark:
                className = "mark-theme-dark"
            }

            let escaped = javascriptString(className)
            return """
            (() => {
              document.body.classList.remove('mark-theme-light', 'mark-theme-dark');
              const className = \(escaped);
              if (className) document.body.classList.add(className);
            })();
            """
        }
    }
}
