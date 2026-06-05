import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MarkCore

@Suite("Markdown document")
struct MarkdownDocumentTests {
    @Test("registers the same Markdown UTI macOS reports for md files")
    func registersMarkdownUTType() {
        #expect(UTType.markMarkdown.identifier == "net.daringfireball.markdown")
        #expect(UTType(filenameExtension: "md")?.identifier == UTType.markMarkdown.identifier)
        #expect(UTType(filenameExtension: "markdown")?.identifier == UTType.markMarkdown.identifier)
        #expect(MarkdownDocument.readableContentTypes.contains(.markMarkdown))
    }

    @Test("round-trips UTF-8 Markdown without altering content")
    func roundTripsUTF8Markdown() throws {
        let original = "# Olá\n\nTexto com acento, emoji opcional removido, e BRL R$ 10,00."
        let wrapper = FileWrapper(regularFileWithContents: Data(original.utf8))
        let document = try MarkdownDocument(fileWrapper: wrapper)

        let written = document.regularFileWrapper()
        let saved = String(decoding: written.regularFileContents ?? Data(), as: UTF8.self)

        #expect(document.text == original)
        #expect(saved == original)
    }

    @Test("uses a useful new document template")
    func newDocumentTemplate() {
        let document = MarkdownDocument()

        #expect(document.text.contains("# Untitled"))
    }
}
