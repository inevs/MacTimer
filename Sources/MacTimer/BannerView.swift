import SwiftUI

struct BannerView: View {
    let model: TimerModel
    let onClose: () -> Void
    let onMove: () -> Void
    let onResize: () -> Void
    let onGestureEnded: () -> Void

    @State private var isHovering = false

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            ZStack {
                RoundedRectangle(cornerRadius: min(height * 0.2, 28))
                    .fill(.black.opacity(0.55))

                Text(model.state == .finished ? "Zeit ist um" : model.displayText)
                    .font(.system(size: height * 0.68, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .padding(.horizontal, height * 0.2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { _ in onMove() }
                    .onEnded { _ in onGestureEnded() }
            )
            .overlay(alignment: .topTrailing) {
                controls.padding(8)
            }
            .overlay(alignment: .bottomTrailing) {
                resizeGrip
            }
        }
        .onHover { isHovering = $0 }
    }

    private var textColor: Color {
        if model.state == .finished { return .red }
        if model.isLastMinute { return .orange }
        return .white
    }

    private var controls: some View {
        HStack(spacing: 6) {
            BannerButton(title: "−1", help: "1 Minute weniger") { model.adjust(by: -60) }
                .disabled(model.state != .running)
            BannerButton(title: "+1", help: "1 Minute mehr") { model.adjust(by: 60) }
            BannerButton(title: "✕", help: "Timer beenden", action: onClose)
        }
        .opacity(isHovering ? 1 : 0.2)
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    private var resizeGrip: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .rotationEffect(.degrees(90))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(isHovering ? 0.8 : 0))
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { _ in onResize() }
                    .onEnded { _ in onGestureEnded() }
            )
            .help("Größe ändern")
    }
}

private struct BannerButton: View {
    let title: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(minWidth: 28, minHeight: 22)
                .background(.white.opacity(0.2), in: Capsule())
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
