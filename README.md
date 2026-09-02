# 🟩 GitHub Contribution Widget for macOS

A high-performance, lightweight native macOS menu bar and desktop widget designed with **Clean Architecture** in Swift & SwiftUI. It visualizes your GitHub contribution graph, annual counts, current & longest streaks, and today's commit count directly from your macOS menu bar or floating desktop overlay.

---

## 🌟 Features

- ⚡ **Native Performance & Lightweight**: Built with native Swift/SwiftUI and AppKit. Zero Electron, zero third-party dependencies, < 10MB memory usage.
- 🐙 **Pixel-Perfect GitHub Contribution Heatmap**:
  - 52-week calendar grid (Sun–Sat) with month headers (`Sep`, `Oct`, `Nov`, ...) and weekday labels (`Mon`, `Wed`, `Fri`).
  - Interactive hover states and tooltips displaying exact dates and commit counts.
  - Less $\to$ More color intensity legend.
- 📊 **Live Streak & Metric Cards**:
  - Total contributions in the last year.
  - Current active daily streak (🔥).
  - Longest historical daily streak (🏆).
  - Today's commit count (⚡).
- 🎛 **Customizable Menu Bar Display**: Toggle to show any combination of Current Streak, Longest Streak, or Today's Commits directly in your macOS menu bar.
- 🎨 **7 Built-in Color Themes**:
  - GitHub Dark Green (default)
  - GitHub Light Green
  - Dracula Purple
  - Cyberpunk Neon
  - Sunset Ember
  - Ocean Blue
  - Monochrome Slate
- 🖥 **Floating Desktop HUD Mode**: Sleek translucent glassmorphism widget (`.ultraThinMaterial`) pinned to your desktop wallpaper.
- 🔄 **Smart Caching & Background Refresh**: Offline disk cache + background timer (configurable refresh interval via settings, defaults to 30 mins) + instant manual refresh button.
- 🚀 **One-Line Installation**: Install and start instantly with `sh install.sh --id <github_id>`.

---

## 🚀 Quick Start & Installation

### 1. Install & Launch

You can install the widget via **NPM** (Recommended) or via the provided shell script.

**Method A: Install via NPM (Recommended)**
```bash
npm install -g git-contribution-widget-macos
git-contribution-widget
```

**Method B: Install via Bash Script**
```bash
sh install.sh
```

### 2. Set your GitHub ID
- Click the new **GitHub icon** in your macOS menu bar.
- Open **Settings (⚙️)**.
- Enter your **GitHub ID** and press Enter.

### 3. Done! 🎉
Your widget is now active and will refresh automatically in the background.

---

## 🛠 Command Line Options

```
Usage:
  # Via NPM:
  git-contribution-widget [OPTIONS]
  
  # Via Bash Script:
  sh install.sh [OPTIONS]

Options:
  --login             Automatically launch on macOS login (registers LaunchAgent)
  --build-only        Compile the .app bundle without installing to ~/Applications
  --uninstall         Remove the widget app, config, cache, and LaunchAgent
  --help, -h          Show help message
```

---

## 🏛 Clean Architecture Overview

The codebase in `src/` follows Clean Architecture principles:

```
src/
├── Domain/                         # Pure business logic & entities
│   ├── Entities/
│   │   ├── ContributionDay.swift       # Daily contribution record & level (0-4)
│   │   ├── ContributionCalendar.swift  # 52-week calendar, month labels, totals
│   │   ├── ContributionStats.swift     # Streaks, today's count, year totals
│   │   ├── Theme.swift                 # Color palettes & presets
│   │   └── AppConfig.swift             # Settings entity & display modes
│   ├── Repositories/
│   │   ├── ContributionRepository\Protocol.swift # Data fetching abstraction
│   │   └── ConfigRepositoryProtocol.swift       # Persistence abstraction
│   └── Services/
│       └── StreakCalculationEngine.swift        # Pure streak & metrics algorithm
│
├── Application/                    # Use Cases & DTOs
│   ├── UseCases/
│   │   ├── GetContributionsUseCase.swift        # Fetch, compute streaks, cache
│   │   ├── UpdateConfigUseCase.swift            # Update settings & login items
│   │   └── ToggleDesktopWidgetUseCase.swift     # Floating HUD controller
│   └── DTOs/
│       └── ContributionOverviewDTO.swift        # Transfer object between layers
│
├── Infrastructure/                 # External APIs, File Storage & OS Services
│   ├── Repositories/
│   │   ├── GitHubContributionRepository.swift   # HTML Scraper + JSON API fallback
│   │   └── FileConfigRepository.swift           # ~/Library/Application Support/ JSON store
│   ├── Network/
│   │   └── HTTPClient.swift                     # URLSession HTTP client
│   └── System/
│       └── LaunchAgentManager.swift             # ~/Library/LaunchAgents/ service
│
├── Interface/                      # Presentation Layer (SwiftUI & AppKit)
│   ├── Controllers/
│   │   ├── AppState.swift                       # Main @MainActor Observable coordinator
│   │   ├── StatusItemController.swift           # macOS Menu Bar NSStatusItem
│   │   ├── PopoverController.swift              # NSPopover hosting PopoverView
│   │   └── DesktopHUDWindowController.swift     # Translucent floating NSWindow
│   └── Views/
│       ├── PopoverView.swift                    # Main popover interface
│       ├── HeatmapGridView.swift                # 52-week interactive grid
│       ├── StatCardsView.swift                  # 4 metric summary cards
│       ├── DesktopHUDView.swift                 # Floating glass HUD view
│       └── ThemeSelectorView.swift              # Live color theme switcher
│
├── AppDelegate.swift               # Composition Root & dependency injection
└── main.swift                      # NSApplication bootstrap entry point
```

---

## ⚙️ Configuration & Storage

- **Configuration File**: `~/Library/Application Support/GitContributionWidget/config.json`
- **Offline Cache**: `~/Library/Application Support/GitContributionWidget/cache.json`
- **Application Bundle**: `~/Applications/GitContributionWidget.app`
- **LaunchAgent Plist**: `~/Library/LaunchAgents/com.user.gitcontributionwidget.plist`

---

## 📄 License
MIT License
