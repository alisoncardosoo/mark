import MarkCore
import SwiftUI

struct OutlineView: View {
    let items: [MarkdownOutlineItem]
    let selectedAnchor: String?
    let onSelection: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Outline")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if items.isEmpty {
                ContentUnavailableView("No headings", systemImage: "text.alignleft")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(items, selection: .constant(selectedAnchor)) { item in
                    Button {
                        onSelection(item.anchor)
                    } label: {
                        Text(item.title)
                            .lineLimit(1)
                            .foregroundStyle(selectedAnchor == item.anchor ? Color.markLilac : Color.primary)
                            .padding(.leading, CGFloat(max(item.level - 1, 0)) * 10)
                    }
                    .buttonStyle(.plain)
                    .tag(item.anchor)
                    .help("Jump to \(item.title)")
                }
                .listStyle(.sidebar)
            }
        }
    }
}
