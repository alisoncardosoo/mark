import SwiftUI

struct MarkAssistantCommands: Commands {
    @FocusedBinding(\.markAssistantExportHTML) private var exportHTML
    @FocusedBinding(\.markAssistantExportPDF) private var exportPDF
    @FocusedBinding(\.markAssistantToggleOutline) private var toggleOutline
    @AppStorage(AppPreferenceKeys.appLanguage) private var appLanguage = AppLanguage.system.rawValue

    var body: some Commands {
        CommandMenu(strings.markdownMenu) {
            Button(strings.exportHTML) {
                exportHTML?()
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
            .disabled(exportHTML == nil)

            Button(strings.exportPDF) {
                exportPDF?()
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
            .disabled(exportPDF == nil)

            Divider()

            Button(strings.toggleOutline) {
                toggleOutline?()
            }
            .keyboardShortcut("o", modifiers: [.command, .option])
            .disabled(toggleOutline == nil)
        }
    }

    private var strings: MarkAssistantStrings {
        MarkAssistantStrings(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }
}

private struct MarkAssistantExportHTMLKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

private struct MarkAssistantExportPDFKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

private struct MarkAssistantToggleOutlineKey: FocusedValueKey {
    typealias Value = Binding<() -> Void>
}

extension FocusedValues {
    var markAssistantExportHTML: Binding<() -> Void>? {
        get { self[MarkAssistantExportHTMLKey.self] }
        set { self[MarkAssistantExportHTMLKey.self] = newValue }
    }

    var markAssistantExportPDF: Binding<() -> Void>? {
        get { self[MarkAssistantExportPDFKey.self] }
        set { self[MarkAssistantExportPDFKey.self] = newValue }
    }

    var markAssistantToggleOutline: Binding<() -> Void>? {
        get { self[MarkAssistantToggleOutlineKey.self] }
        set { self[MarkAssistantToggleOutlineKey.self] = newValue }
    }
}
