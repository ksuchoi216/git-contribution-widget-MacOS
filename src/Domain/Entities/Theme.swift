import Foundation

public struct Theme: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let levelHexes: [String] // Exactly 5 hex strings: [0, 1, 2, 3, 4]

    public init(id: String, name: String, levelHexes: [String]) {
        self.id = id
        self.name = name
        self.levelHexes = levelHexes
    }

    public func hex(for level: ContributionLevel) -> String {
        let index = level.rawValue
        if index >= 0 && index < levelHexes.count {
            return levelHexes[index]
        }
        return levelHexes.first ?? "#161b22"
    }

    // Built-in Presets
    public static let darkModeGreen = Theme(
        id: "dark_green",
        name: "GitHub Dark",
        levelHexes: ["#161b22", "#0e4429", "#006d32", "#26a641", "#39d353"]
    )

    public static let classicGreen = Theme(
        id: "classic_green",
        name: "GitHub Light",
        levelHexes: ["#ebedf0", "#9be9a8", "#40c463", "#30a14e", "#216e39"]
    )

    public static let dracula = Theme(
        id: "dracula",
        name: "Dracula Purple",
        levelHexes: ["#282a36", "#44475a", "#6272a4", "#bd93f9", "#ff79c6"]
    )

    public static let cyberpunk = Theme(
        id: "cyberpunk",
        name: "Cyberpunk Neon",
        levelHexes: ["#0f172a", "#0e7490", "#06b6d4", "#f43f5e", "#facc15"]
    )

    public static let sunset = Theme(
        id: "sunset",
        name: "Sunset Ember",
        levelHexes: ["#18181b", "#7c2d12", "#c2410c", "#ea580c", "#fb923c"]
    )

    public static let ocean = Theme(
        id: "ocean",
        name: "Ocean Blue",
        levelHexes: ["#0b1329", "#1e3a8a", "#2563eb", "#38bdf8", "#93c5fd"]
    )

    public static let monochrome = Theme(
        id: "monochrome",
        name: "Monochrome Slate",
        levelHexes: ["#18181b", "#3f3f46", "#71717a", "#a1a1aa", "#f4f4f5"]
    )

    public static let allPresets: [Theme] = [
        .darkModeGreen,
        .classicGreen,
        .dracula,
        .cyberpunk,
        .sunset,
        .ocean,
        .monochrome
    ]

    public static func find(id: String) -> Theme {
        allPresets.first(where: { $0.id == id }) ?? .darkModeGreen
    }
}
