import AppKit

@MainActor
enum DefaultMarkdownAppPromptCoordinator {
    static func presentIfNeeded(language: AppLanguage) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: AppPreferenceKeys.defaultMarkdownAppPromptAnswered),
              !DefaultMarkdownAppService.isCurrentAppDefault else {
            return
        }

        let strings = MarkAssistantStrings(language: language)
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.icon = NSApp.applicationIconImage
        alert.messageText = strings.defaultMarkdownAppPromptTitle
        alert.informativeText = strings.defaultMarkdownAppPromptMessage
        alert.addButton(withTitle: strings.makeDefaultMarkdownApp)
        alert.addButton(withTitle: strings.notNow)

        let response = alert.runModal()
        defaults.set(true, forKey: AppPreferenceKeys.defaultMarkdownAppPromptAnswered)

        guard response == .alertFirstButtonReturn else {
            return
        }

        showResultAlert(for: DefaultMarkdownAppService.makeCurrentAppDefault(), strings: strings)
    }

    private static func showResultAlert(
        for result: DefaultMarkdownAppResult,
        strings: MarkAssistantStrings
    ) {
        let alert = NSAlert()
        alert.icon = NSApp.applicationIconImage

        switch result {
        case .success:
            alert.alertStyle = .informational
            alert.messageText = strings.defaultMarkdownAppSuccessTitle
            alert.informativeText = strings.defaultMarkdownAppSuccessMessage
        case .missingBundleIdentifier:
            alert.alertStyle = .warning
            alert.messageText = strings.defaultMarkdownAppFailureTitle
            alert.informativeText = strings.defaultMarkdownAppMissingBundleMessage
        case .failed(let status):
            alert.alertStyle = .warning
            alert.messageText = strings.defaultMarkdownAppFailureTitle
            alert.informativeText = strings.defaultMarkdownAppFailureMessage(status: status)
        }

        alert.addButton(withTitle: strings.ok)
        alert.runModal()
    }
}
