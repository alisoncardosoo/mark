import AppKit
import SwiftUI

struct WindowFramePersistenceView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WindowFrameHostView {
        let view = WindowFrameHostView()
        view.onWindowChanged = { window in
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: WindowFrameHostView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.attach(to: nsView.window)
        }
    }

    final class Coordinator {
        private weak var observedWindow: NSWindow?
        private var observers: [NSObjectProtocol] = []
        private var restoredWindowIdentifiers: Set<ObjectIdentifier> = []

        func attach(to window: NSWindow?) {
            guard observedWindow !== window else {
                return
            }

            removeObservers()
            observedWindow = window

            guard let window else {
                return
            }

            window.minSize = NSSize(width: 920, height: 560)
            restoreIfNeeded(window)

            let center = NotificationCenter.default
            observers = [
                center.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self, weak window] _ in
                    guard let window else { return }
                    self?.save(window)
                },
                center.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { [weak self, weak window] _ in
                    guard let window else { return }
                    self?.save(window)
                }
            ]
        }

        deinit {
            removeObservers()
        }

        private func restoreIfNeeded(_ window: NSWindow) {
            let identifier = ObjectIdentifier(window)
            guard !restoredWindowIdentifiers.contains(identifier) else {
                return
            }
            restoredWindowIdentifiers.insert(identifier)

            guard let frameString = UserDefaults.standard.string(forKey: AppPreferenceKeys.windowFrame) else {
                return
            }

            let frame = NSRectFromString(frameString)
            guard isUsable(frame: frame) else {
                return
            }

            window.setFrame(frame, display: true)
        }

        private func save(_ window: NSWindow) {
            UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: AppPreferenceKeys.windowFrame)
        }

        private func removeObservers() {
            observers.forEach(NotificationCenter.default.removeObserver)
            observers.removeAll()
        }

        private func isUsable(frame: NSRect) -> Bool {
            guard frame.width >= 720, frame.height >= 420 else {
                return false
            }

            return NSScreen.screens.contains { screen in
                frame.intersects(screen.visibleFrame)
            }
        }
    }
}

final class WindowFrameHostView: NSView {
    var onWindowChanged: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onWindowChanged?(self.window)
        }
    }
}
