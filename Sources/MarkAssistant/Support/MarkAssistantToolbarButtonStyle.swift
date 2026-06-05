import SwiftUI

struct MarkAssistantToolbarButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? Color.white : Color.markAssistantLilac)
            .frame(width: 30, height: 30)
            .background(backgroundColor(isPressed: configuration.isPressed), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.markAssistantLilac.opacity(isActive ? 0 : 0.18), lineWidth: 1)
            }
            .contentShape(Circle())
            .padding(.horizontal, 1)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isActive {
            return isPressed ? Color.markAssistantLilac.opacity(0.82) : Color.markAssistantLilac
        }

        return isPressed ? Color.markAssistantLilac.opacity(0.22) : Color.markAssistantLilacSurface
    }
}
