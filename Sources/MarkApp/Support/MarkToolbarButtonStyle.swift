import SwiftUI

struct MarkToolbarButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(isActive ? Color.white : Color.markLilac)
            .frame(width: 30, height: 30)
            .background(backgroundColor(isPressed: configuration.isPressed), in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.markLilac.opacity(isActive ? 0 : 0.18), lineWidth: 1)
            }
            .contentShape(Circle())
            .padding(.horizontal, 1)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isActive {
            return isPressed ? Color.markLilac.opacity(0.82) : Color.markLilac
        }

        return isPressed ? Color.markLilac.opacity(0.22) : Color.markLilacSurface
    }
}
