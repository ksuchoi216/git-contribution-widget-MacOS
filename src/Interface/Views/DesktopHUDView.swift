import SwiftUI

public struct DesktopHUDView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 13))

                Text("github.com/\(appState.config.username)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text("\(appState.overview.stats.currentStreak)d streak")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)

                    Button(action: {
                        appState.toggleDesktopWidget()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Heatmap Grid
            HeatmapGridView(appState: appState)
        }
        .padding(14)
        .frame(width: 760)
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .cornerRadius(12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 6)
    }
}

// AppKit VisualEffectView wrapper for translucent glassmorphism
public struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
