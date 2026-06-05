import AppKit
import MarkAssistantCore
import SwiftUI

@main
struct MarkAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(AppPreferenceKeys.appLanguage) private var appLanguage = AppLanguage.system.rawValue

    init() {
        AppPreferences.appLanguage.applyToProcessPreferences()
    }

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { configuration in
            ContentView(
                document: configuration.$document,
                fileURL: configuration.fileURL
            )
            .environment(\.appLanguage, selectedLanguage)
        }
        .commands {
            SidebarCommands()
            MarkAssistantCommands()
        }

        Settings {
            SettingsView()
                .environment(\.appLanguage, selectedLanguage)
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .system
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
