import MarkCore
import SwiftUI

struct ContentView: View {
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
            .tint(.markLilac)
            .background(WindowFramePersistenceView())
            .toolbar {
                markToolbar
            }
            .modifier(AppPreferencePersistenceModifier(store: store))
            .focusedSceneValue(\.markExportHTML, $exportHTMLAction)
            .focusedSceneValue(\.markExportPDF, $exportPDFAction)
            .focusedSceneValue(\.markToggleOutline, $toggleOutlineAction)
            .onAppear(perform: configureFocusedActions)
            .alert("Export failed", isPresented: exportErrorPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError?.message ?? "Unknown error")
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
            viewModePicker
            toolbarButtons
        }
    }

    private var viewModePicker: some View {
        Picker("View Mode", selection: $store.displayMode) {
            ForEach(EditorDisplayMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 220)
        .help("Choose editor, split, or preview-only mode")
    }

    private var toolbarButtons: some View {
        HStack(spacing: 6) {
            Button {
                store.showOutline.toggle()
            } label: {
                Label("Outline", systemImage: "list.bullet.indent")
            }
            .buttonStyle(MarkToolbarButtonStyle(isActive: store.showOutline))
            .help("Show or hide the document outline")

            if store.displayMode == .split {
                Group {
                    Button {
                        store.requestBalancedSplit()
                    } label: {
                        Label("Reset Split", systemImage: "rectangle.split.2x1")
                    }
                    .buttonStyle(MarkToolbarButtonStyle(isActive: false))
                    .help("Make editor and preview content 50/50, excluding the outline")

                    Button {
                        store.isScrollSyncEnabled.toggle()
                    } label: {
                        Label("Sync Scroll", systemImage: "arrow.up.and.down")
                    }
                    .buttonStyle(MarkToolbarButtonStyle(isActive: store.isScrollSyncEnabled))
                    .help("Synchronize code and preview scrolling in split mode")
                }
            }

            Button {
                exportHTML()
            } label: {
                Label("Export HTML", systemImage: "curlybraces")
            }
            .buttonStyle(MarkToolbarButtonStyle(isActive: false))
            .help("Export this Markdown document as HTML")

            Button {
                Task { await exportPDF() }
            } label: {
                Label("Export PDF", systemImage: "doc.richtext")
            }
            .buttonStyle(MarkToolbarButtonStyle(isActive: false))
            .help("Export this Markdown document as PDF")
        }
        .padding(.horizontal, 3)
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
