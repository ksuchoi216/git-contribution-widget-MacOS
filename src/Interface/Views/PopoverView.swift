import SwiftUI

public struct PopoverView: View {
    @ObservedObject var appState: AppState
    @State private var inputUsername: String = ""

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header
            HStack(spacing: 10) {
                // GitHub Logo / Octocat
                Image(systemName: "circle.grid.cross.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: appState.overview.theme.hex(for: .level3)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(appState.config.username.isEmpty ? "GitHub Widget" : "@\(appState.config.username)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if appState.overview.isCached {
                        Text("Cached • Offline")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    } else if !appState.overview.username.isEmpty {
                        Text("Updated \(formattedDate(appState.overview.lastFetched))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Profile Link Button
                if !appState.config.username.isEmpty {
                    Button(action: {
                        if let url = URL(string: "https://github.com/\(appState.config.username)?tab=overview") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Open GitHub Profile")
                }

                // Refresh Button
                Button(action: {
                    Task {
                        await appState.fetchContributions(force: true)
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .rotationEffect(.degrees(appState.isLoading ? 360 : 0))
                        .animation(appState.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: appState.isLoading)
                        .foregroundColor(appState.isLoading ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh Contributions")

                // Settings Toggle Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isSettingsOpen.toggle()
                        if appState.isSettingsOpen {
                            inputUsername = appState.config.username
                        }
                    }
                }) {
                    Image(systemName: appState.isSettingsOpen ? "xmark.circle" : "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(appState.isSettingsOpen ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Settings")
            }

            // MARK: - Error Notice
            if let error = appState.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 11))
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(8)
                .background(Color.red.opacity(0.12))
                .cornerRadius(6)
            }

            if appState.isSettingsOpen {
                // MARK: - Settings View
                settingsSection
            } else {
                // MARK: - Main Stats & Heatmap
                StatCardsView(appState: appState)

                HeatmapGridView(appState: appState)
            }
        }
        .padding(14)
        .frame(width: 740)
        .background(Color(hex: "#0d1117"))
        .onAppear {
            inputUsername = appState.config.username
        }
    }

    // MARK: - Settings Section View
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Username Field
            VStack(alignment: .leading, spacing: 4) {
                Text("GitHub Username")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack {
                    TextField("e.g. ksuchoi216", text: $inputUsername)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 12))

                    Button("Save & Fetch") {
                        appState.updateUsername(inputUsername)
                        appState.isSettingsOpen = false
                    }
                    .font(.system(size: 11, weight: .medium))
                    .disabled(inputUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Divider()
                .background(Color(hex: "#30363d"))

            // Theme Picker
            ThemeSelectorView(appState: appState)

            Divider()
                .background(Color(hex: "#30363d"))

            // Widget & Launch Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Widget & System Preferences")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Toggle("Floating Desktop HUD Widget", isOn: Binding(
                    get: { appState.config.isDesktopWidgetEnabled },
                    set: { _ in appState.toggleDesktopWidget() }
                ))
                .font(.system(size: 12))

                Toggle("Launch Automatically on macOS Login", isOn: Binding(
                    get: { appState.config.isStartAtLoginEnabled },
                    set: { _ in appState.toggleStartAtLogin() }
                ))
                .font(.system(size: 12))
            }

            Divider()
                .background(Color(hex: "#30363d"))

            // Footer Actions
            HStack {
                Spacer()

                Button("Quit Widget") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
