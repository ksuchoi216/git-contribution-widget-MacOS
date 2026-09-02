import Foundation

public final class LaunchAgentManager: Sendable {
    public static let shared = LaunchAgentManager()

    private let plistLabel = "com.user.gitcontributionwidget"

    private var plistURL: URL {
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        return launchAgentsDir.appendingPathComponent("\(plistLabel).plist")
    }

    public init() {}

    public func isLaunchAtLoginEnabled() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    public func setLaunchAtLogin(enabled: Bool, executablePath: String? = nil) {
        let fileManager = FileManager.default
        let launchAgentsDir = plistURL.deletingLastPathComponent()

        if !enabled {
            if fileManager.fileExists(atPath: plistURL.path) {
                try? fileManager.removeItem(at: plistURL)
            }
            return
        }

        // Determine executable path
        let appExecPath: String
        if let path = executablePath {
            appExecPath = path
        } else {
            let defaultInstalledPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications/GitContributionWidget.app/Contents/MacOS/GitContributionWidget").path
            if fileManager.fileExists(atPath: defaultInstalledPath) {
                appExecPath = defaultInstalledPath
            } else {
                appExecPath = Bundle.main.executablePath ?? defaultInstalledPath
            }
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(plistLabel)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(appExecPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
            <key>ProcessType</key>
            <string>Interactive</string>
        </dict>
        </plist>
        """

        try? fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true, attributes: nil)
        try? plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
    }
}
