import Testing
@testable import MarkAssistantCore

@Suite("Editor store")
struct EditorStoreTests {
    @Test("clamps scroll sync progress and tracks source")
    func clampsScrollSyncProgress() {
        let store = EditorStore(source: "# Title", baseURL: nil)

        store.updateScrollSync(progress: 1.5, source: .editor)
        #expect(store.scrollSyncProgress == 1)
        #expect(store.scrollSyncSource == .editor)

        store.updateScrollSync(progress: -0.5, source: .preview)
        #expect(store.scrollSyncProgress == 0)
        #expect(store.scrollSyncSource == .preview)
    }

    @Test("clamps split fraction and resets to half")
    func clampsSplitFraction() {
        let store = EditorStore(source: "# Title", baseURL: nil, splitFraction: 0.9)

        #expect(store.splitFraction == 0.75)

        store.setSplitFraction(0.1)
        #expect(store.splitFraction == 0.25)

        store.resetSplitFraction()
        #expect(store.splitFraction == 0.5)
    }

    @Test("balances split against usable width")
    func balancesSplitAgainstUsableWidth() {
        let store = EditorStore(source: "# Title", baseURL: nil)

        store.resetSplitFraction(
            availableWidth: 1000,
            reservedTrailingWidth: 221,
            dividerWidth: 8
        )

        #expect(store.splitFraction == 0.3855)
    }

    @Test("tracks balanced split requests")
    func tracksBalancedSplitRequests() {
        let store = EditorStore(source: "# Title", baseURL: nil)

        store.requestBalancedSplit()
        store.requestBalancedSplit()

        #expect(store.splitBalanceRequestID == 2)
    }
}
