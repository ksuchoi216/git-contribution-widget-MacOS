# GitHub Contribution Widget for macOS - Clean Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS GitHub contribution menu bar & desktop widget following Clean Architecture with a one-command installer (`sh install.sh --id <github_id>`).

**Architecture:** Clean Architecture dividing responsibilities into Domain (entities, streak calculation engine, repository protocols), Application (use cases, DTOs), Infrastructure (GitHub HTML scraper/fallback API, JSON disk storage, LaunchAgent service), and Interface (SwiftUI Popover, Heatmap Grid, Floating HUD, Menu Bar AppKit status item, AppState).

**Tech Stack:** Swift 6, SwiftUI, AppKit, Combine, Foundation, macOS 12.0+ deployment target, `swiftc`.

## Global Constraints
- Target platform: macOS (arm64 / universal, macOS 12.0+).
- Clean Architecture layers: `Domain`, `Application`, `Infrastructure`, `Interface`.
- Code location: `src/` directory.
- Entry installer: `sh install.sh --id <github_id>` with optional flags `--login`, `--uninstall`, `--build-only`.
- Zero external runtime dependencies.

---

### Task 1: Domain Entities, Repositories, and Streak Engine

**Files:**
- Create: `src/Domain/Entities/ContributionDay.swift`
- Create: `src/Domain/Entities/ContributionCalendar.swift`
- Create: `src/Domain/Entities/ContributionStats.swift`
- Create: `src/Domain/Entities/Theme.swift`
- Create: `src/Domain/Entities/AppConfig.swift`
- Create: `src/Domain/Repositories/ContributionRepositoryProtocol.swift`
- Create: `src/Domain/Repositories/ConfigRepositoryProtocol.swift`
- Create: `src/Domain/Services/StreakCalculationEngine.swift`
- Create: `tests/DomainTests.swift`

**Interfaces:**
- Produces:
  - `struct ContributionDay: Codable, Identifiable, Equatable`
  - `struct ContributionCalendar: Codable, Equatable`
  - `struct ContributionStats: Codable, Equatable`
  - `struct Theme: Identifiable, Codable, Equatable`
  - `struct AppConfig: Codable, Equatable`
  - `protocol ContributionRepositoryProtocol: Sendable`
  - `protocol ConfigRepositoryProtocol: Sendable`
  - `struct StreakCalculationEngine`

- [ ] **Step 1: Write Domain Entities and Protocols**
Write the Swift domain model files in `src/Domain/Entities/` and `src/Domain/Repositories/`.

- [ ] **Step 2: Implement Streak Calculation Engine**
Implement pure business rules in `src/Domain/Services/StreakCalculationEngine.swift` to compute current streak, max streak, today's commits, and 52-week totals.

- [ ] **Step 3: Write and Run Domain Unit Tests**
Write `tests/DomainTests.swift` and compile/run with `swift tests/DomainTests.swift` to verify streak calculation accuracy.

- [ ] **Step 4: Commit Domain Layer**
```bash
git add src/Domain tests/DomainTests.swift
git commit -m "feat(domain): implement Clean Architecture domain models, protocols, and streak engine"
```

---

### Task 2: Infrastructure Layer (Network, HTML Scraper, JSON Storage, LaunchAgent)

**Files:**
- Create: `src/Infrastructure/Network/HTTPClient.swift`
- Create: `src/Infrastructure/Repositories/GitHubContributionRepository.swift`
- Create: `src/Infrastructure/Repositories/FileConfigRepository.swift`
- Create: `src/Infrastructure/System/LaunchAgentManager.swift`
- Create: `tests/InfrastructureTests.swift`

**Interfaces:**
- Consumes: `ContributionRepositoryProtocol`, `ConfigRepositoryProtocol`, `ContributionDay`, `ContributionCalendar`, `AppConfig`
- Produces:
  - `class GitHubContributionRepository: ContributionRepositoryProtocol`
  - `class FileConfigRepository: ConfigRepositoryProtocol`
  - `class LaunchAgentManager`

- [ ] **Step 1: Implement HTTPClient and Scraper / Fallback Parser**
Implement `GitHubContributionRepository` fetching `https://github.com/users/<username>/contributions` and parsing `ContributionCalendar-day` attributes (`data-date`, `data-level`, tooltip text) with JSON fallback.

- [ ] **Step 2: Implement FileConfigRepository and LaunchAgentManager**
Implement JSON persistence in `~/Library/Application Support/GitContributionWidget/` and launchd plist generation in `~/Library/LaunchAgents/`.

- [ ] **Step 3: Run Infrastructure Unit & Live Tests**
Compile and test `tests/InfrastructureTests.swift` using `ksuchoi216` to verify fetching and parsing works seamlessly.

- [ ] **Step 4: Commit Infrastructure Layer**
```bash
git add src/Infrastructure tests/InfrastructureTests.swift
git commit -m "feat(infra): implement GitHub scraper, file storage repository, and LaunchAgent manager"
```

---

### Task 3: Application Layer (Use Cases & DTOs)

**Files:**
- Create: `src/Application/DTOs/ContributionOverviewDTO.swift`
- Create: `src/Application/UseCases/GetContributionsUseCase.swift`
- Create: `src/Application/UseCases/UpdateConfigUseCase.swift`
- Create: `src/Application/UseCases/ToggleDesktopWidgetUseCase.swift`
- Create: `tests/ApplicationTests.swift`

**Interfaces:**
- Consumes: Domain Entities, Repositories, Services
- Produces:
  - `struct ContributionOverviewDTO: Codable`
  - `class GetContributionsUseCase`
  - `class UpdateConfigUseCase`
  - `class ToggleDesktopWidgetUseCase`

- [ ] **Step 1: Implement DTO and Use Cases**
Write `GetContributionsUseCase` to coordinate fetching, computing stats via `StreakCalculationEngine`, saving cache, and falling back gracefully on network errors.

- [ ] **Step 2: Write and Run Application Layer Tests**
Compile `tests/ApplicationTests.swift` with mock repositories and verify caching and error fallback logic.

- [ ] **Step 3: Commit Application Layer**
```bash
git add src/Application tests/ApplicationTests.swift
git commit -m "feat(application): implement Use Cases and DTOs"
```

---

### Task 4: Interface Layer (SwiftUI Views & AppState)

**Files:**
- Create: `src/Interface/Controllers/AppState.swift`
- Create: `src/Interface/Views/StatCardsView.swift`
- Create: `src/Interface/Views/HeatmapGridView.swift`
- Create: `src/Interface/Views/ThemeSelectorView.swift`
- Create: `src/Interface/Views/DesktopHUDView.swift`
- Create: `src/Interface/Views/PopoverView.swift`

**Interfaces:**
- Consumes: Application Use Cases & DTOs, Domain Entities
- Produces:
  - `class AppState: ObservableObject`
  - `struct PopoverView: View`
  - `struct HeatmapGridView: View`
  - `struct StatCardsView: View`
  - `struct DesktopHUDView: View`
  - `struct ThemeSelectorView: View`

- [ ] **Step 1: Implement AppState Coordinator**
Create `@MainActor class AppState: ObservableObject` to handle async state fetching, timers, theme switching, and desktop HUD visibility.

- [ ] **Step 2: Implement SwiftUI Heatmap, Metric Cards, Theme Picker, and Popover Views**
Create pixel-perfect macOS SwiftUI views with smooth hover states, tooltip popups, responsive 52-week heatmap grid, and translucent glass styles.

- [ ] **Step 3: Implement DesktopHUDView**
Create floating translucent HUD view with glassmorphism styling for continuous desktop monitoring.

- [ ] **Step 4: Commit Interface Layer Views & AppState**
```bash
git add src/Interface
git commit -m "feat(interface): implement SwiftUI Popover, Heatmap Grid, Floating HUD, and AppState"
```

---

### Task 5: AppKit Presentation Controllers & Composition Root

**Files:**
- Create: `src/Interface/Controllers/StatusItemController.swift`
- Create: `src/Interface/Controllers/PopoverController.swift`
- Create: `src/Interface/Controllers/DesktopHUDWindowController.swift`
- Create: `src/AppDelegate.swift`
- Create: `src/main.swift`

**Interfaces:**
- Connects AppKit lifecycle (`NSStatusItem`, `NSPopover`, `NSWindow`) to `AppState` and wires Clean Architecture dependency injection in `AppDelegate`.

- [ ] **Step 1: Implement StatusItemController, PopoverController, and DesktopHUDWindowController**
Create AppKit window and status item wrappers for macOS menu bar and floating window.

- [ ] **Step 2: Implement AppDelegate Composition Root and main.swift**
Assemble all dependencies (Repositories -> Use Cases -> AppState -> Controllers) and start `NSApplication`.

- [ ] **Step 3: Verify Whole Project Compilation**
Run `swiftc` across all `src/**/*.swift` files to verify clean compilation with 0 warnings.

- [ ] **Step 4: Commit AppKit Controllers and main entry point**
```bash
git add src/AppDelegate.swift src/main.swift src/Interface/Controllers
git commit -m "feat(composition): implement AppKit controllers, AppDelegate composition root, and main.swift"
```

---

### Task 6: Installation Script (`install.sh`) & Documentation (`README.md`)

**Files:**
- Create: `install.sh`
- Create: `README.md`

- [ ] **Step 1: Create install.sh**
Implement bash script handling argument parsing (`--id <id>`, `--login`, `--build-only`, `--uninstall`), compilation via `swiftc`, `.app` bundle packaging with `Info.plist`, config writing, LaunchAgent management, and instant launching.

- [ ] **Step 2: Create README.md**
Write comprehensive documentation with installation instructions, CLI flags, features, architecture breakdown, and screenshots/diagrams.

- [ ] **Step 3: Commit install.sh and README.md**
```bash
git add install.sh README.md
git commit -m "feat: add install.sh installer script and comprehensive README documentation"
```

---

### Task 7: End-to-End Verification

- [ ] **Step 1: Test install.sh with `--id ksuchoi216`**
Run `sh install.sh --id ksuchoi216 --build-only` and full install to verify `.app` bundle creation and execution.

- [ ] **Step 2: Verify Launch, Scraping, Caching, and UI**
Verify app launches, fetches `ksuchoi216` data, and populates cache and config.
