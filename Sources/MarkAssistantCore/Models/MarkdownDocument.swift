import Foundation
import SwiftUI
import UniformTypeIdentifiers

public struct MarkdownDocument: FileDocument, Equatable, Sendable {
    public static var readableContentTypes: [UTType] {
        [.markAssistantMarkdown, .markAssistantMarkdownAlternate, .plainText, .text]
    }

    public static var writableContentTypes: [UTType] {
        [.markAssistantMarkdown, .markAssistantMarkdownAlternate, .plainText]
    }

    public var text: String

    public init(text: String = "# Untitled\n\nStart writing in Markdown.") {
        self.text = text
    }

    public init(fileWrapper: FileWrapper) throws {
        guard let data = fileWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        guard let decoded = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }

        self.text = decoded
    }

    public init(configuration: ReadConfiguration) throws {
        try self.init(fileWrapper: configuration.file)
    }

    public func regularFileWrapper() -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        regularFileWrapper()
    }
}
