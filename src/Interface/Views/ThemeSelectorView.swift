import SwiftUI

public struct ThemeSelectorView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Theme")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Theme.allPresets) { theme in
                        Button(action: {
                            appState.selectTheme(id: theme.id)
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 2) {
                                    ForEach(theme.levelHexes, id: \.self) { hex in
                                        RoundedRectangle(cornerRadius: 1.5)
                                            .fill(Color(hex: hex))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                Text(theme.name)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(appState.config.themeId == theme.id ? .primary : .secondary)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(appState.config.themeId == theme.id ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(
                                        appState.config.themeId == theme.id ? Color.accentColor : Color.white.opacity(0.1),
                                        lineWidth: appState.config.themeId == theme.id ? 1.5 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}
