import AppKit
import MarkCore
import WebKit

@MainActor
enum ExportPanel {
    static func exportHTML(source: String, sourceURL: URL?) throws {
        let service = ExportService()
        guard let destination = saveURL(
            defaultName: service.defaultExportName(for: sourceURL, extension: "html"),
            allowedExtensions: ["html"]
        ) else {
            return
        }

        try service.htmlData(for: source, baseURL: sourceURL).write(to: destination, options: .atomic)
    }

    static func exportPDF(html: String, sourceURL: URL?) async throws {
        let service = ExportService()
        guard let destination = saveURL(
            defaultName: service.defaultExportName(for: sourceURL, extension: "pdf"),
            allowedExtensions: ["pdf"]
        ) else {
            return
        }

        let data = try await PDFRenderer.render(html: html)
        try data.write(to: destination, options: .atomic)
    }

    private static func saveURL(defaultName: String, allowedExtensions: [String]) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = allowedExtensions.compactMap { .init(filenameExtension: $0) }
        panel.canCreateDirectories = true
        return panel.runModal() == .OK ? panel.url : nil
    }
}

@MainActor
private final class PDFRenderer: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Never>?

    static func render(html: String) async throws -> Data {
        let renderer = PDFRenderer()
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 980, height: 1200), configuration: configuration)
        webView.navigationDelegate = renderer
        webView.loadHTMLString(html, baseURL: nil)
        await renderer.waitForLoad()

        let pdfConfiguration = WKPDFConfiguration()
        let contentHeight = try await webView.contentHeight()
        pdfConfiguration.rect = CGRect(x: 0, y: 0, width: 980, height: max(contentHeight, 1200))

        return try await withCheckedThrowingContinuation { continuation in
            webView.createPDF(configuration: pdfConfiguration) { result in
                continuation.resume(with: result)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func waitForLoad() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

private extension WKWebView {
    @MainActor
    func contentHeight() async throws -> CGFloat {
        let value: CGFloat = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGFloat, Error>) in
            evaluateJavaScript("Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)") { value, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                if let number = value as? NSNumber {
                    continuation.resume(returning: CGFloat(truncating: number))
                } else {
                    continuation.resume(returning: CGFloat(1200))
                }
            }
        }

        return value
    }
}
