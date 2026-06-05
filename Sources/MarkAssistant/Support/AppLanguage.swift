import Foundation
import MarkAssistantCore
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case portuguese

    var id: String { rawValue }

    var resolvedLanguage: ResolvedAppLanguage {
        switch self {
        case .system:
            return Locale.preferredLanguages.first?.lowercased().hasPrefix("pt") == true ? .portuguese : .english
        case .english:
            return .english
        case .portuguese:
            return .portuguese
        }
    }

    func applyToProcessPreferences() {
        let defaults = UserDefaults.standard
        switch self {
        case .system:
            defaults.removeObject(forKey: "AppleLanguages")
        case .english:
            defaults.set(["en"], forKey: "AppleLanguages")
        case .portuguese:
            defaults.set(["pt-BR", "pt", "en"], forKey: "AppleLanguages")
        }
        defaults.synchronize()
    }
}

enum ResolvedAppLanguage {
    case english
    case portuguese
}

struct MarkAssistantStrings {
    let language: AppLanguage

    private var isPortuguese: Bool {
        language.resolvedLanguage == .portuguese
    }

    func text(en: String, pt: String) -> String {
        isPortuguese ? pt : en
    }

    var viewMode: String { text(en: "View Mode", pt: "Modo de visualização") }
    var viewModeHelp: String { text(en: "Choose editor, split, or preview-only mode", pt: "Escolha editor, dividido ou somente preview") }
    var outline: String { text(en: "Outline", pt: "Outline") }
    var toggleOutline: String { text(en: "Toggle Outline", pt: "Alternar outline") }
    var outlineHelp: String { text(en: "Show or hide the document outline", pt: "Mostrar ou ocultar o outline do documento") }
    var resetSplit: String { text(en: "Reset Split", pt: "Dividir 50/50") }
    var resetSplitHelp: String { text(en: "Make editor and preview content 50/50, excluding the outline", pt: "Divide editor e preview em 50/50 sem contar o outline") }
    var syncScroll: String { text(en: "Sync Scroll", pt: "Sincronizar rolagem") }
    var syncScrollHelp: String { text(en: "Synchronize code and preview scrolling in split mode", pt: "Sincroniza a rolagem do código e do preview no modo dividido") }
    var exportHTML: String { text(en: "Export HTML", pt: "Exportar HTML") }
    var exportHTMLHelp: String { text(en: "Export this Markdown document as HTML", pt: "Exporta este documento Markdown como HTML") }
    var exportPDF: String { text(en: "Export PDF", pt: "Exportar PDF") }
    var exportPDFHelp: String { text(en: "Export this Markdown document as PDF", pt: "Exporta este documento Markdown como PDF") }
    var exportFailed: String { text(en: "Export failed", pt: "Falha ao exportar") }
    var ok: String { text(en: "OK", pt: "OK") }
    var unknownError: String { text(en: "Unknown error", pt: "Erro desconhecido") }
    var markdownMenu: String { "Markdown" }

    var search: String { text(en: "Search", pt: "Buscar") }
    var searchHelp: String { text(en: "Search in editor and preview", pt: "Buscar no editor e no preview") }
    var clearSearch: String { text(en: "Clear search", pt: "Limpar busca") }
    var noHeadings: String { text(en: "No headings", pt: "Sem títulos") }
    var dragSplitDivider: String { text(en: "Drag to resize editor and preview", pt: "Arraste para redimensionar editor e preview") }

    var settingsEditorPreview: String { text(en: "Editor and Preview", pt: "Editor e Preview") }
    var settingsLanguage: String { text(en: "Language", pt: "Idioma") }
    var appLanguage: String { text(en: "App language", pt: "Idioma do app") }
    var appLanguageRestartNote: String { text(en: "macOS menus and document popups update after reopening Mark Assistant.", pt: "Menus do macOS e popups de documento atualizam depois de reabrir o Mark Assistant.") }
    var languageRestartTitle: String { text(en: "Reopen Mark Assistant to finish changing language?", pt: "Reabrir o Mark Assistant para concluir a troca de idioma?") }
    var languageRestartMessage: String { text(en: "The app content updates now. Native macOS menus and document popups need Mark Assistant to reopen.", pt: "O conteudo do app atualiza agora. Menus nativos do macOS e popups de documento precisam que o Mark Assistant reabra.") }
    var reopenNow: String { text(en: "Reopen Now", pt: "Reabrir agora") }
    var later: String { text(en: "Later", pt: "Depois") }
    var previewTheme: String { text(en: "Preview theme", pt: "Tema do preview") }
    var previewThemeHelp: String { text(en: "Choose the preview color theme", pt: "Escolha o tema de cor do preview") }
    var editorFont: String { text(en: "Editor font", pt: "Fonte do editor") }
    var previewZoom: String { text(en: "Preview zoom", pt: "Zoom do preview") }
    var settingsApp: String { text(en: "App", pt: "App") }
    var version: String { text(en: "Version", pt: "Versão") }
    var format: String { text(en: "Format", pt: "Formato") }
    var minimumMacOS: String { text(en: "Minimum macOS", pt: "macOS mínimo") }
    var bundleID: String { text(en: "Bundle ID", pt: "Bundle ID") }
    var creator: String { text(en: "Creator", pt: "Criador") }
    var nativeMacOS: String { text(en: "Native macOS", pt: "macOS nativo") }
    var heroSubtitle: String { text(en: "Fast Markdown editing with a GitHub-style preview.", pt: "Edição Markdown rápida com preview estilo GitHub.") }
    var creatorRole: String { text(en: "Creator and owner", pt: "Criador e proprietário") }

    func displayModeTitle(_ mode: EditorDisplayMode) -> String {
        switch mode {
        case .editor:
            text(en: "Editor", pt: "Editor")
        case .split:
            text(en: "Split", pt: "Dividido")
        case .preview:
            text(en: "Preview", pt: "Preview")
        }
    }

    func previewThemeTitle(_ theme: PreviewTheme) -> String {
        switch theme {
        case .system:
            text(en: "System", pt: "Sistema")
        case .light:
            text(en: "Light", pt: "Claro")
        case .dark:
            text(en: "Dark", pt: "Escuro")
        }
    }

    func appLanguageTitle(_ appLanguage: AppLanguage) -> String {
        switch appLanguage {
        case .system:
            text(en: "System", pt: "Sistema")
        case .english:
            text(en: "English", pt: "Inglês")
        case .portuguese:
            "Português"
        }
    }

    func jumpTo(_ title: String) -> String {
        text(en: "Jump to \(title)", pt: "Ir para \(title)")
    }
}

private struct AppLanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .system
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageEnvironmentKey.self] }
        set { self[AppLanguageEnvironmentKey.self] = newValue }
    }
}
