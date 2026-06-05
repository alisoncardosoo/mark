import SwiftUI

struct ToolbarSearchControl: View {
    @Binding var query: String
    let placeholder: String
    let searchHelp: String
    let clearHelp: String

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(query.isEmpty ? Color.secondary : Color.markAssistantLilac)

            TextField(placeholder, text: $query)
                .textFieldStyle(.plain)
                .focused($isFieldFocused)

            if !query.isEmpty {
                Button {
                    query = ""
                    isFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(clearHelp)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, query.isEmpty ? 12 : 8)
        .frame(width: Self.fieldWidth, height: 32)
        .background(Color.markAssistantLilacSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.markAssistantLilac.opacity(isFieldFocused ? 0.55 : 0.18), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            isFieldFocused = true
        }
        .help(searchHelp)
    }

    private static let fieldWidth: CGFloat = 228
}
