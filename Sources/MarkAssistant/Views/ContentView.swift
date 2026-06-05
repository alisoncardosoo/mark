import MarkAssistantCore
import SwiftUI

struct ContentView: View {
    @Environment(\.appLanguage) private var appLanguage
    @Binding private var document: MarkdownDocument
    private let fileURL: URL?

    @State private var store: EditorStore
    @State private var exportError: ExportError?
    @State private var exportHTMLAction: () -> Void = {}
    @State private var exportPDFAction: () -> Void = {}
    @State private var toggleOutlineAction: () -> Void = {}

    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @AppStorage("previewZoom") private var previewZoom = 1.0
    @AppStorage("previewTheme") private var previewTheme = PreviewTheme.system.rawValue

    init(document: Binding<MarkdownDocument>, fileURL: URL?) {
        self._document = document
        self.fileURL = fileURL
        self._store = State(
            initialValue: EditorStore(
                source: document.wrappedValue.text,
                baseURL: fileURL,
                displayMode: AppPreferences.displayMode,
                showOutline: AppPreferences.showOutline,
                isScrollSyncEnabled: AppPreferences.isScrollSyncEnabled,
                splitFraction: AppPreferences.splitFraction
            )
        )
    }

    var body: some View {
        configuredEditorShell
    }

    private var configuredEditorShell: some View {
        editorShell
            .tint(.markAssistantLilac)
            .background(WindowFramePersistenceView())
            .toolbar {
                markToolbar
            }
            .modifier(AppPreferencePersistenceModifier(store: store))
            .focusedSceneValue(\.markAssistantExportHTML, $exportHTMLAction)
            .focusedSceneValue(\.markAssistantExportPDF, $exportPDFAction)
            .focusedSceneValue(\.markAssistantToggleOutline, $toggleOutlineAction)
            .onAppear(perform: configureFocusedActions)
            .alert(strings.exportFailed, isPresented: exportErrorPresented) {
                Button(strings.ok, role: .cancel) {}
            } message: {
                Text(exportError?.message ?? strings.unknownError)
            }
    }

    private var editorShell: some View {
        EditorShellView(
            document: $document,
            fileURL: fileURL,
            store: store,
            editorFontSize: editorFontSize,
            previewZoom: previewZoom,
            previewTheme: PreviewTheme(rawValue: previewTheme) ?? .system
        )
    }

    @ToolbarContentBuilder
    private var markToolbar: some ToolbarContent {
        ToolbarItemGroup {
            ToolbarSearchControl(
                query: searchQuery,
                placeholder: strings.search,
                searchHelp: strings.searchHelp,
                clearHelp: strings.clearSearch
            )
            viewModePicker
            toolbarButtons
        }
    }

    private var viewModePicker: some View {
        Picker(strings.viewMode, selection: $store.displayMode) {
            ForEach(EditorDisplayMode.allCases) { mode in
                Text(strings.displayModeTitle(mode)).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
        .help(strings.viewModeHelp)
    }

    private var toolbarButtons: some View {
        HStack(spacing: 6) {
            Button {
                store.showOutline.toggle()
            } label: {
                Label(strings.outline, systemImage: "list.bullet.indent")
            }
            .buttonStyle(MarkAssistantToolbarButtonStyle(isActive: store.showOutline))
            .help(strings.outlineHelp)

            if store.displayMode == .split {
                Group {
                    Button {
                        store.requestBalancedSplit()
                    } label: {
                        Label(strings.resetSplit, systemImage: "rectangle.split.2x1")
                    }
                    .buttonStyle(MarkAssistantToolbarButtonStyle(isActive: false))
                    .help(strings.resetSplitHelp)

                    Button {
                        store.isScrollSyncEnabled.toggle()
                    } label: {
                        Label(strings.syncScroll, systemImage: "arrow.up.and.down")
                    }
                    .buttonStyle(MarkAssistantToolbarButtonStyle(isActive: store.isScrollSyncEnabled))
                    .help(strings.syncScrollHelp)
                }
            }

            Button {
                exportHTML()
            } label: {
                Label(strings.exportHTML, systemImage: "curlybraces")
            }
            .buttonStyle(MarkAssistantToolbarButtonStyle(isActive: false))
            .help(strings.exportHTMLHelp)

            Button {
                Task { await exportPDF() }
            } label: {
                Label(strings.exportPDF, systemImage: "doc.richtext")
            }
            .buttonStyle(MarkAssistantToolbarButtonStyle(isActive: false))
            .help(strings.exportPDFHelp)
        }
        .padding(.horizontal, 3)
    }

    private var strings: MarkAssistantStrings {
        MarkAssistantStrings(language: appLanguage)
    }

    private var searchQuery: Binding<String> {
        Binding(
            get: { store.query },
            set: { store.query = $0 }
        )
    }

    private var exportErrorPresented: Binding<Bool> {
        Binding(
            get: { exportError != nil },
            set: { isPresented in
                if !isPresented {
                    exportError = nil
                }
            }
        )
    }

    private func exportHTML() {
        do {
            try ExportPanel.exportHTML(source: document.text, sourceURL: fileURL)
        } catch {
            exportError = ExportError(error)
        }
    }

    private func configureFocusedActions() {
        exportHTMLAction = exportHTML
        exportPDFAction = startPDFExport
        toggleOutlineAction = toggleOutline
    }

    private func toggleOutline() {
        store.showOutline.toggle()
    }

    private func startPDFExport() {
        Task { await exportPDF() }
    }

    @MainActor
    private func exportPDF() async {
        do {
            try await ExportPanel.exportPDF(html: store.renderedMarkdown.html, sourceURL: fileURL)
        } catch {
            exportError = ExportError(error)
        }
    }
}

private struct AppPreferencePersistenceModifier: ViewModifier {
    let store: EditorStore

    func body(content: Content) -> some View {
        content
            .onChange(of: store.displayMode.rawValue) { _, rawValue in
                UserDefaults.standard.set(rawValue, forKey: AppPreferenceKeys.displayMode)
            }
            .onChange(of: store.showOutline) { _, value in
                UserDefaults.standard.set(value, forKey: AppPreferenceKeys.showOutline)
            }
            .onChange(of: store.isScrollSyncEnabled) { _, value in
                UserDefaults.standard.set(value, forKey: AppPreferenceKeys.scrollSyncEnabled)
            }
            .onChange(of: store.splitFraction) { _, value in
                UserDefaults.standard.set(value, forKey: AppPreferenceKeys.splitFraction)
            }
    }
}

private struct ExportError: Identifiable {
    let id = UUID()
    let message: String

    init(_ error: Error) {
        self.message = error.localizedDescription
    }
}
