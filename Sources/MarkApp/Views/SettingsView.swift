import AppKit
import MarkCore
import SwiftUI

struct SettingsView: View {
    @AppStorage("editorFontSize") private var editorFontSize = 14.0
    @AppStorage("previewZoom") private var previewZoom = 1.0
    @AppStorage("previewTheme") private var previewTheme = PreviewTheme.system.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsHero()

                SettingsPanel("Editor and Preview", systemImage: "slider.horizontal.3") {
                    PreviewThemeRow(previewTheme: $previewTheme)
                    SettingsDivider()
                    SliderSettingsRow(
                        title: "Editor font",
                        value: $editorFontSize,
                        range: 11...22,
                        step: 1,
                        valueText: "\(Int(editorFontSize)) pt"
                    )
                    SettingsDivider()
                    SliderSettingsRow(
                        title: "Preview zoom",
                        value: $previewZoom,
                        range: 0.75...1.5,
                        step: 0.05,
                        valueText: "\(Int(previewZoom * 100))%"
                    )
                }

                SettingsPanel("App", systemImage: "info.circle") {
                    SettingsInfoRow(title: "Version", value: AppInfo.versionDisplay)
                    SettingsDivider()
                    SettingsInfoRow(title: "Format", value: "GitHub-Flavored Markdown")
                    SettingsDivider()
                    SettingsInfoRow(title: "Minimum macOS", value: AppInfo.minimumSystemVersion)
                    SettingsDivider()
                    SettingsInfoRow(title: "Bundle ID", value: AppInfo.bundleIdentifier)
                }

                SettingsPanel("Creator", systemImage: "person.crop.circle") {
                    CreatorRow()
                }
            }
            .padding(24)
        }
        .scrollIndicators(.hidden)
        .tint(.markLilac)
        .background(SettingsBackground())
        .frame(width: 560, height: 640)
    }
}

private struct SettingsHero: View {
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

                    Text("Native macOS")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.markLilac)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.markLilacSurface, in: Capsule())
                }

                Text("Fast Markdown editing with a GitHub-style preview.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.markLilac.opacity(0.16), lineWidth: 1)
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
                    .foregroundStyle(Color.markLilac)
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

    var body: some View {
        HStack(spacing: 18) {
            Text("Preview theme")
                .font(.callout.weight(.medium))

            Spacer()

            Picker("Preview theme", selection: $previewTheme) {
                ForEach(PreviewTheme.allCases) { theme in
                    Text(theme.settingsTitle).tag(theme.rawValue)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 238)
            .help("Choose the preview color theme")
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
                .tint(.markLilac)
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
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.markLilac)

                Text("AC")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Alison Cardoso")
                    .font(.callout.weight(.semibold))

                Text("Creator and owner")
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

private struct SettingsBackground: View {
    var body: some View {
        Color(nsColor: .windowBackgroundColor)
    }
}

private enum AppInfo {
    static var displayName: String {
        bundleString("CFBundleDisplayName")
            ?? bundleString("CFBundleName")
            ?? "Mark"
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
        Bundle.main.bundleIdentifier ?? "com.alisoncardoso.Mark"
    }

    private static func bundleString(_ key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}

private extension PreviewTheme {
    var settingsTitle: String {
        switch self {
        case .system:
            "System"
        case .light:
            "Light"
        case .dark:
            "Dark"
        }
    }
}
