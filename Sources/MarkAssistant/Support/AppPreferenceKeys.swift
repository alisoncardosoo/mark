import Foundation
import MarkAssistantCore

enum AppPreferenceKeys {
    static let displayMode = "displayMode"
    static let showOutline = "showOutline"
    static let scrollSyncEnabled = "scrollSyncEnabled"
    static let splitFraction = "splitFraction"
    static let windowFrame = "windowFrame"
    static let appLanguage = "appLanguage"
    static let defaultMarkdownAppPromptAnswered = "defaultMarkdownAppPromptAnswered"
}

enum AppPreferences {
    static var displayMode: EditorDisplayMode {
        let rawValue = UserDefaults.standard.string(forKey: AppPreferenceKeys.displayMode)
        return rawValue.flatMap(EditorDisplayMode.init(rawValue:)) ?? .split
    }

    static var showOutline: Bool {
        bool(forKey: AppPreferenceKeys.showOutline, defaultValue: true)
    }

    static var isScrollSyncEnabled: Bool {
        bool(forKey: AppPreferenceKeys.scrollSyncEnabled, defaultValue: false)
    }

    static var splitFraction: Double {
        let value = UserDefaults.standard.double(forKey: AppPreferenceKeys.splitFraction)
        guard value > 0 else {
            return 0.5
        }
        return min(max(value, 0.25), 0.75)
    }

    static var appLanguage: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: AppPreferenceKeys.appLanguage)
        return rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    private static func bool(forKey key: String, defaultValue: Bool) -> Bool {
        guard UserDefaults.standard.object(forKey: key) != nil else {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
}
