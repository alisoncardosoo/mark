import CoreServices
import Foundation

enum DefaultMarkdownAppResult: Equatable {
    case success
    case missingBundleIdentifier
    case failed(OSStatus)
}

enum DefaultMarkdownAppService {
    private static let markdownContentTypeIdentifier = "net.daringfireball.markdown"

    static var currentBundleIdentifier: String? {
        Bundle.main.bundleIdentifier
    }

    static var isCurrentAppDefault: Bool {
        guard let bundleIdentifier = currentBundleIdentifier else {
            return false
        }

        return defaultBundleIdentifier == bundleIdentifier
    }

    static var defaultBundleIdentifier: String? {
        LSCopyDefaultRoleHandlerForContentType(markdownContentTypeIdentifier as CFString, .all)?
            .takeRetainedValue() as String?
    }

    @discardableResult
    static func makeCurrentAppDefault() -> DefaultMarkdownAppResult {
        guard let bundleIdentifier = currentBundleIdentifier else {
            return .missingBundleIdentifier
        }

        let status = LSSetDefaultRoleHandlerForContentType(
            markdownContentTypeIdentifier as CFString,
            .all,
            bundleIdentifier as CFString
        )

        guard status == noErr else {
            return .failed(status)
        }

        return .success
    }
}
