# GitHub Contribution Widget for macOS - Clean Architecture Design Document

## 1. Overview
The GitHub Contribution Widget is a lightweight, high-performance native macOS menu bar and desktop widget built in Swift & SwiftUI. It visualizes GitHub contribution activity for any given GitHub username (e.g. `ksuchoi216`), displaying daily streaks, annual totals, today's commit count, and an interactive 52-week contribution heatmap matrix with selectable color themes and a floating desktop HUD.

The codebase strictly follows **Clean Architecture** principles to separate domain logic, use cases, interfaces/presentation, and infrastructure/external integrations.

---

## 2. Clean Architecture Layer Specifications

### Layer Hierarchy & Dependency Rule
Dependencies strictly point inward: `Interface` & `Infrastructure` $\to$ `Application` $\to$ `Domain`.

```
                  +----------------------------------------------+
                  |            Interface (Presentation)          |
                  |  - SwiftUI Views (Popover, Heatmap, HUD)     |
                  |  - Controllers (StatusItem, Popover, Window) |
                  |  - AppState (ViewModel / Observable)         |
                  +----------------------+-----------------------+
                                         |
                                         v
                  +----------------------------------------------+
                  |               Application                    |
                  |  - GetContributionsUseCase                   |
                  |  - UpdateConfigUseCase                       |
                  |  - ToggleDesktopWidgetUseCase                |
                  |  - DTOs & Service Protocols                  |
                  +----------------------+-----------------------+
                                         |
                                         v
                  +----------------------------------------------+
                  |                  Domain                      |
                  |  - Entities (ContributionDay, Stats, Theme)  |
                  |  - Repository Protocols (Interfaces)         |
                  |  - Business Rules (StreakCalculationEngine)  |
                  +----------------------+-----------------------+
                                         ^
                                         |
                  +----------------------+-----------------------+
                  |               Infrastructure                 |
                  |  - GitHub HTML Scraper & API Fallback Client |
                  |  - FileConfigRepository (JSON Disk Storage)  |
                  |  - LaunchAgentManager (System Login Service) |
                  +----------------------------------------------+
```

---

### 2.1 Domain Layer (`src/Domain/`)
**Purpose**: Core business entities and rules. Independent of any UI framework, databases, or networking libraries.
- **Entities**:
  - `ContributionDay`: Date, contribution count (integer), level (`.level0` ... `.level4`).
  - `ContributionCalendar`: 52 weeks of contributions, year total.
  - `ContributionStats`: Current streak (consecutive days $\ge 1$), longest streak, today's count, total past year count.
  - `Theme`: Color palette entity (5 levels of color hexes) + built-in presets (Classic Green, Dark Mode, Dracula, Cyberpunk, Sunset, Ocean, Monochrome).
  - `AppConfig`: User settings entity (GitHub username, refresh interval, active theme ID, desktop widget enabled, launch at login enabled).
- **Domain Business Rules**:
  - `StreakCalculationEngine`: Pure business algorithm calculating current active streak, max historical streak, and date-range metrics relative to user's local timezone.
- **Repository Protocols (Abstractions)**:
  - `ContributionRepositoryProtocol`: Defines `fetchContributions(username: String) async throws -> ContributionCalendar`.
  - `ConfigRepositoryProtocol`: Defines `loadConfig() -> AppConfig`, `saveConfig(_ config: AppConfig)`, `loadCache() -> ContributionCalendar?`, and `saveCache(_ calendar: ContributionCalendar)`.

---

### 2.2 Application Layer (`src/Application/`)
**Purpose**: Orchestrates use cases and application-specific business flows. Coordinates domain entities and repository protocols.
- **Use Cases**:
  - `GetContributionsUseCase`: Fetches contribution calendar via `ContributionRepositoryProtocol`, computes `ContributionStats` using `StreakCalculationEngine`, saves cache via `ConfigRepositoryProtocol`, and returns combined DTO. Falls back to cached data if offline.
  - `UpdateConfigUseCase`: Updates user preferences (GitHub ID, theme, refresh interval, launch at login) and triggers system integrations.
  - `ToggleDesktopWidgetUseCase`: Coordinates showing/hiding the floating desktop overlay HUD window.
- **DTOs**:
  - `ContributionOverviewDTO`: Packaged data object passed to the interface layer containing calendar, stats, and metadata.

---

### 2.3 Interface / Presentation Layer (`src/Interface/`)
**Purpose**: Handles user interaction, macOS system menu bar, popover windows, and SwiftUI rendering.
- **Controllers & State Coordinators**:
  - `AppState`: Main `@MainActor ObservableObject` driving UI views. Dispatches use cases and holds reactive state (`isLoading`, `error`, `overview`, `config`).
  - `StatusItemController`: Manages native macOS menu bar status item (`NSStatusItem`), icon, streak title, and click handlers.
  - `PopoverController`: Manages the `NSPopover` hosting SwiftUI `PopoverView`.
  - `DesktopHUDWindowController`: Manages the translucent floating glass window pinned to desktop level (`kCGDesktopWindowLevelKey` or floating overlay).
- **SwiftUI Views**:
  - `PopoverView`: Main popup containing Header, 4 Stat Cards, Heatmap, Theme Picker, and Settings toggles.
  - `HeatmapGridView`: 52-week $\times$ 7-day grid with month labels, weekday headers (Mon, Wed, Fri), and hover tooltips showing date & commit count.
  - `StatCardsView`: 4 responsive metric summary cards (Total, Current Streak, Longest Streak, Today).
  - `DesktopHUDView`: Floating translucent glass HUD (`.ultraThinMaterial`) for continuous desktop monitoring.
  - `ThemeSelectorView`: Live color palette switcher.

---

### 2.4 Infrastructure Layer (`src/Infrastructure/`)
**Purpose**: Implements domain interfaces with external systems, APIs, file systems, and macOS OS services.
- **Repositories & External Integrations**:
  - `GitHubContributionRepository`: Implements `ContributionRepositoryProtocol`. Scrapes `https://github.com/users/<username>/contributions` via `URLSession` with regex/HTML parsing; includes fallback to `https://github-contributions-api.jogruber.de/v4/<username>`.
  - `FileConfigRepository`: Implements `ConfigRepositoryProtocol`. Reads and writes JSON files in `~/Library/Application Support/GitContributionWidget/` (`config.json` and `cache.json`).
  - `LaunchAgentManager`: Manages `~/Library/LaunchAgents/com.user.gitcontributionwidget.plist` to register/unregister start at login.

---

### 2.5 Composition Root (`src/AppDelegate.swift` & `src/main.swift`)
- Wires concrete Infrastructure implementations into Application UseCases.
- Injects UseCases into `AppState`.
- Initializes `NSApplication` in background agent mode (`LSUIElement = true`).

---

## 3. Directory Layout

```
git-contribution-widget-MacOS/
├── install.sh                  # One-line installer and uninstaller script
├── README.md                   # Documentation and usage guide
└── src/
    ├── main.swift              # App bootstrap & NSApplication setup
    ├── AppDelegate.swift       # Composition root, menu bar & window manager
    │
    ├── Domain/
    │   ├── Entities/
    │   │   ├── ContributionDay.swift
    │   │   ├── ContributionCalendar.swift
    │   │   ├── ContributionStats.swift
    │   │   ├── Theme.swift
    │   │   └── AppConfig.swift
    │   ├── Repositories/
    │   │   ├── ContributionRepositoryProtocol.swift
    │   │   └── ConfigRepositoryProtocol.swift
    │   └── Services/
    │       └── StreakCalculationEngine.swift
    │
    ├── Application/
    │   ├── UseCases/
    │   │   ├── GetContributionsUseCase.swift
    │   │   ├── UpdateConfigUseCase.swift
    │   │   └── ToggleDesktopWidgetUseCase.swift
    │   └── DTOs/
    │       └── ContributionOverviewDTO.swift
    │
    ├── Infrastructure/
    │   ├── Repositories/
    │   │   ├── GitHubContributionRepository.swift
    │   │   └── FileConfigRepository.swift
    │   ├── Network/
    │   │   └── HTTPClient.swift
    │   └── System/
    │       └── LaunchAgentManager.swift
    │
    └── Interface/
        ├── Controllers/
        │   ├── AppState.swift
        │   ├── StatusItemController.swift
        │   ├── PopoverController.swift
        │   └── DesktopHUDWindowController.swift
        └── Views/
            ├── PopoverView.swift
            ├── HeatmapGridView.swift
            ├── StatCardsView.swift
            ├── DesktopHUDView.swift
            └── ThemeSelectorView.swift
```

---

## 4. Installation & Lifecycle (`install.sh`)

- **Syntax**: `sh install.sh --id <github_id> [--login] [--uninstall]`
- **Build**: Compiles all Swift files across layers into `GitContributionWidget.app`:
  ```bash
  swiftc -O -target arm64-apple-macos12.0 \
    $(find src -name "*.swift") \
    -o GitContributionWidget.app/Contents/MacOS/GitContributionWidget
  ```
- **Deployment**:
  - Copies `.app` to `~/Applications/GitContributionWidget.app`.
  - Initializes `~/Library/Application Support/GitContributionWidget/config.json` with `--id <github_id>`.
  - Configures LaunchAgent if `--login` is passed.
  - Launches the app immediately in background menu bar mode.
