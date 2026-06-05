import SwiftUI

struct SearchBar: View {
    @Binding var query: String
    let isRendering: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(query.isEmpty ? Color.secondary : Color.markLilac)

            TextField("Search", text: $query)
                .textFieldStyle(.plain)

            if isRendering {
                ProgressView()
                    .controlSize(.small)
            }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear search")
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(query.isEmpty ? Color.clear : .markLilac.opacity(0.45), lineWidth: 1)
        }
    }
}
