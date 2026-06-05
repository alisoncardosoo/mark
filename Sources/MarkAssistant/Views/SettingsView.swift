import AppKit
import MarkAssistantCore
import SwiftUI

struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @AppStorage("previewZoom") private var previewZoom = 1.0
    @AppStorage("previewTheme") private var previewTheme = PreviewTheme.system.rawValue
    @AppStorage(AppPreferenceKeys.appLanguage) private var appLanguage = AppLanguage.system.rawValue
    @State private var isShowingLanguageRestartAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsHero(strings: strings)

                SettingsPanel(strings.settingsLanguage, systemImage: "globe") {
                    AppLanguageRow(
                        appLanguage: $appLanguage,
                        strings: strings
                    )
                    SettingsDivider()
                    SettingsFootnote(text: strings.appLanguageRestartNote)
                }

                SettingsPanel(strings.settingsEditorPreview, systemImage: "slider.horizontal.3") {
                    PreviewThemeRow(previewTheme: $previewTheme, strings: strings)
                    SettingsDivider()
                    SliderSettingsRow(
                        title: strings.editorFont,
                        value: $editorFontSize,
                        range: 11...22,
                        step: 1,
                        valueText: "\(Int(editorFontSize)) pt"
                    )
                    SettingsDivider()
                    SliderSettingsRow(
                        title: strings.previewZoom,
                        value: $previewZoom,
                        range: 0.75...1.5,
                        step: 0.05,
                        valueText: "\(Int(previewZoom * 100))%"
                    )
                }

                SettingsPanel(strings.settingsApp, systemImage: "info.circle") {
                    SettingsInfoRow(title: strings.version, value: AppInfo.versionDisplay)
                    SettingsDivider()
                    SettingsInfoRow(title: strings.format, value: "GitHub-Flavored Markdown")
                    SettingsDivider()
                    SettingsInfoRow(title: strings.minimumMacOS, value: AppInfo.minimumSystemVersion)
                    SettingsDivider()
                    SettingsInfoRow(title: strings.bundleID, value: AppInfo.bundleIdentifier)
                }

                SettingsPanel(strings.creator, systemImage: "person.crop.circle") {
                    CreatorRow(strings: strings)
                }
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .tint(.markAssistantLilac)
        .background(SettingsBackground())
        .frame(width: 560, height: 640)
        .onChange(of: appLanguage) { _, rawValue in
            (AppLanguage(rawValue: rawValue) ?? .system).applyToProcessPreferences()
            isShowingLanguageRestartAlert = true
        }
        .alert(strings.languageRestartTitle, isPresented: $isShowingLanguageRestartAlert) {
            Button(strings.reopenNow) {
                AppRelauncher.relaunch()
            }
            Button(strings.later, role: .cancel) {}
        } message: {
            Text(strings.languageRestartMessage)
        }
    }

    private var strings: MarkAssistantStrings {
        MarkAssistantStrings(language: AppLanguage(rawValue: appLanguage) ?? .system)
    }
}

private struct SettingsHero: View {
    let strings: MarkAssistantStrings

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: .black.opacity(0.14), radius: 12, y: 5)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(AppInfo.displayName)
                        .font(.system(size: 22, weight: .semibold))

                    Text(strings.nativeMacOS)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.markAssistantLilac)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.markAssistantLilacSurface, in: Capsule())
                }

                Text(strings.heroSubtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.markAssistantLilac.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct SettingsPanel<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.markAssistantLilac)
                    .frame(width: 18)

                Text(title)
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()
                .opacity(0.7)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.55), lineWidth: 1)
        }
    }
}

private struct PreviewThemeRow: View {
    @Binding var previewTheme: String
    let strings: MarkAssistantStrings

    var body: some View {
        HStack(spacing: 18) {
            Text(strings.previewTheme)
                .font(.callout.weight(.medium))

            Spacer()

            Picker(strings.previewTheme, selection: $previewTheme) {
                ForEach(PreviewTheme.allCases) { theme in
                    Text(strings.previewThemeTitle(theme)).tag(theme.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 238)
            .help(strings.previewThemeHelp)
        }
        .frame(height: 46)
    }
}

private struct AppLanguageRow: View {
    @Binding var appLanguage: String
    let strings: MarkAssistantStrings

    var body: some View {
        HStack(spacing: 18) {
            Text(strings.appLanguage)
                .font(.callout.weight(.medium))

            Spacer()

            Picker(strings.appLanguage, selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(strings.appLanguageTitle(language)).tag(language.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 238)
        }
        .frame(height: 46)
    }
}

private struct SliderSettingsRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueText: String

    var body: some View {
        HStack(spacing: 18) {
            Text(title)
                .font(.callout.weight(.medium))

            Spacer()

            Slider(value: $value, in: range, step: step)
                .tint(.markAssistantLilac)
                .frame(width: 220)

            Text(valueText)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 58, alignment: .trailing)
        }
        .frame(height: 46)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 18) {
            Text(title)
                .font(.callout.weight(.medium))

            Spacer()

            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .frame(height: 42)
    }
}

private struct CreatorRow: View {
    let strings: MarkAssistantStrings

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.markAssistantLilac)

                Text("AC")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Alison Cardoso")
                    .font(.callout.weight(.semibold))

                Text(strings.creatorRole)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(height: 54)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 0)
            .opacity(0.55)
    }
}

private struct SettingsFootnote: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 9)
    }
}

private struct SettingsBackground: View {
    var body: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

private enum AppInfo {
    static var displayName: String {
        bundleString("CFBundleDisplayName")
            ?? bundleString("CFBundleName")
            ?? "Mark Assistant"
    }

    static var versionDisplay: String {
        let version = bundleString("CFBundleShortVersionString") ?? "0.1.0"
        let build = bundleString("CFBundleVersion") ?? "1"
        return "\(version) (\(build))"
    }

    static var minimumSystemVersion: String {
        bundleString("LSMinimumSystemVersion") ?? "14.0"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.alisoncardoso.MarkAssistant"
    }

    private static func bundleString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}
