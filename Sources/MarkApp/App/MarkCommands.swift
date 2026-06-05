import SwiftUI

struct MarkCommands: Commands {
    @FocusedBinding(\.markExportHTML) private var exportHTML
    @FocusedBinding(\.markExportPDF) private var exportPDF
    @FocusedBinding(\.markToggleOutline) private var toggleOutline

    var body: some Commands {
        CommandMenu("Markdown") {
            Button("Export HTML") {
                exportHTML?()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(exportHTML == nil)

            Button("Export PDF") {
                exportPDF?()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(exportPDF == nil)

            Divider()

            Button("Toggle Outline") {
                toggleOutline?()
            }
            .keyboardShortcut("o", modifiers: [.command, .option])
            .disabled(toggleOutline == nil)
        }
    }
}

private struct MarkExportHTMLKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

private struct MarkExportPDFKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

private struct MarkToggleOutlineKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

extension FocusedValues {
    var markExportHTML: Binding<() -> Void>? {
        get { self[MarkExportHTMLKey.self] }
        set { self[MarkExportHTMLKey.self] = newValue }
    }

    var markExportPDF: Binding<() -> Void>? {
        get { self[MarkExportPDFKey.self] }
        set { self[MarkExportPDFKey.self] = newValue }
    }

    var markToggleOutline: Binding<() -> Void>? {
        get { self[MarkToggleOutlineKey.self] }
        set { self[MarkToggleOutlineKey.self] = newValue }
    }
}
