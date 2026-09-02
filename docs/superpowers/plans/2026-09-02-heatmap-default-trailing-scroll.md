# Contribution Heatmap Default Trailing Scroll & Cache Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the contribution heatmap default to showing the latest (rightmost) dates when the popover opens, synchronize month headers inside the horizontal scroll view, and ensure fresh data fetching without local cache blocking.

**Architecture:** 
- State/Event layer: `PopoverController` emits a popover open event to `AppState`.
- View layer: `HeatmapGridView` embeds month headers and 52-week columns inside a single `ScrollView` controlled by `ScrollViewReader`, auto-scrolling to the trailing edge on popover open, initial appearance, and data refreshes.
- Infrastructure layer: `HTTPClient` and `GitHubContributionRepository` bypass local HTTP caches to guarantee immediate updates on refresh.

**Tech Stack:** Swift, SwiftUI, AppKit (`NSPopover`, `NSStatusBarButton`), macOS 12.0+

## Global Constraints
- Target platform: macOS 12.0+ (`-target arm64-apple-macos12.0`)
- Clean Architecture boundaries: Domain -> Application -> Infrastructure / Interface
- Swift compiler: `swiftc -parse-as-library` (must compile cleanly via `install.sh`)

---

### Task 1: HTTP Cache-Busting and Fresh Data Fetching

**Files:**
- Modify: `src/Infrastructure/Network/HTTPClient.swift`
- Modify: `src/Infrastructure/Repositories/GitHubContributionRepository.swift`
- Modify: `src/Application/UseCases/GetContributionsUseCase.swift`
- Test: `tests/InfrastructureTests.swift`

**Interfaces:**
- Consumes: `HTTPClient.fetchString(from:cachePolicy:)`
- Produces: Guaranteed fresh GitHub contribution data when force-refreshed

- [ ] **Step 1: Update `HTTPClient` with cache policy support**

In `src/Infrastructure/Network/HTTPClient.swift`:
```swift
public func fetchString(from urlString: String, cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> String {
    guard let url = URL(string: urlString) else {
        throw NetworkError.invalidURL
    }

    var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 15.0)
    request.httpMethod = "GET"
    request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
    request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.noData
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
    }

    guard let text = String(data: data, encoding: .utf8) else {
        throw NetworkError.decodingError("Invalid UTF-8 encoding")
    }

    return text
}
```

- [ ] **Step 2: Update `GitHubContributionRepository` to append cache-busting timestamps**

In `src/Infrastructure/Repositories/GitHubContributionRepository.swift`:
```swift
public func fetchContributions(username: String) async throws -> ContributionCalendar {
    let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedUsername.isEmpty else {
        throw NetworkError.decodingError("Username is empty")
    }

    let timestamp = Int(Date().timeIntervalSince1970)
    // 1. Primary: Direct HTML Scraping from GitHub with cache-busting query parameter
    do {
        let htmlUrl = "https://github.com/users/\(trimmedUsername)/contributions?_=\(timestamp)"
        let html = try await httpClient.fetchString(from: htmlUrl, cachePolicy: .reloadIgnoringLocalCacheData)
        let calendar = try parseGitHubHTML(html: html, username: trimmedUsername)
        if !calendar.days.isEmpty {
            return calendar
        }
    } catch {
        // Fallback to JSON API if HTML fetch/parse fails
    }

    // 2. Secondary: Fallback to Public JSON API
    do {
        let jsonUrl = "https://github-contributions-api.jogruber.de/v4/\(trimmedUsername)?_=\(timestamp)"
        let data = try await httpClient.fetchData(from: jsonUrl)
        return try parseFallbackJSON(data: data, username: trimmedUsername)
    } catch {
        throw NetworkError.serverError("Unable to fetch contributions for '\(trimmedUsername)'. Please check network connection and username.")
    }
}
```

- [ ] **Step 3: Run infrastructure and application tests**

Run: `swiftc -parse-as-library $(find src/Domain src/Application src/Infrastructure -name "*.swift") tests/ApplicationTests.swift -o /tmp/app_tests && /tmp/app_tests`
Expected: `--- Running Application Layer Tests ---` `✅ Application Layer Tests Passed Successfully!`

- [ ] **Step 4: Commit Task 1 changes**

```bash
git add src/Infrastructure/Network/HTTPClient.swift src/Infrastructure/Repositories/GitHubContributionRepository.swift
git commit -m "fix(network): bypass local HTTP cache with reload policy and timestamp cache-buster"
```

---

### Task 2: State and Popover Open Event Wiring

**Files:**
- Modify: `src/Interface/Controllers/AppState.swift:6-14`
- Modify: `src/Interface/Controllers/PopoverController.swift:38-43`

**Interfaces:**
- Consumes: `PopoverController.showPopover(sender:)`
- Produces: `appState.popoverOpenTrigger` and `appState.notifyPopoverOpened()`

- [ ] **Step 1: Add `popoverOpenTrigger` to `AppState.swift`**

In `src/Interface/Controllers/AppState.swift`:
```swift
@Published public var popoverOpenTrigger: Int = 0

public func notifyPopoverOpened() {
    popoverOpenTrigger += 1
}
```

- [ ] **Step 2: Trigger `notifyPopoverOpened` in `PopoverController.swift`**

In `src/Interface/Controllers/PopoverController.swift`:
```swift
public func showPopover(sender: NSStatusBarButton) {
    appState.notifyPopoverOpened()
    popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    popover.contentViewController?.view.window?.makeKey()
    startMonitoringClicks()
}
```

- [ ] **Step 3: Verify compilation**

Run: `sh install.sh --build-only`
Expected: `Compilation succeeded -> .../GitContributionWidget`

- [ ] **Step 4: Commit Task 2 changes**

```bash
git add src/Interface/Controllers/AppState.swift src/Interface/Controllers/PopoverController.swift
git commit -m "feat(state): add popover open event notification to AppState"
```

---

### Task 3: Heatmap Grid Trailing Auto-Scroll and Month Label Sync

**Files:**
- Modify: `src/Interface/Views/HeatmapGridView.swift`

**Interfaces:**
- Consumes: `appState.popoverOpenTrigger`, `appState.overview`, `ScrollViewReader`
- Produces: Horizontally scrollable heatmap that always defaults to the latest weeks on open and syncs month headers with week columns

- [ ] **Step 1: Update `HeatmapGridView.swift`**

In `src/Interface/Views/HeatmapGridView.swift`:
1. Use `ScrollViewReader { proxy in ... }` around the horizontal scroll view.
2. Embed the month header `ZStack` above the week columns inside the `ScrollView`'s `VStack`.
3. Add a trailing anchor view with `.id("heatmap_trailing_edge")` at the end of the weeks `HStack`.
4. Add helper method `scrollToLatest(proxy: ScrollViewProxy)`:
```swift
private func scrollToLatest(proxy: ScrollViewProxy) {
    DispatchQueue.main.async {
        proxy.scrollTo("heatmap_trailing_edge", anchor: .trailing)
    }
}
```
5. Attach `.onAppear`, `.onChange(of: appState.popoverOpenTrigger)`, and `.onChange(of: appState.overview.lastFetched)` to call `scrollToLatest(proxy:)`.

- [ ] **Step 2: Verify compilation and build**

Run: `sh install.sh --build-only`
Expected: `Compilation succeeded -> .../GitContributionWidget`

- [ ] **Step 3: Commit Task 3 changes**

```bash
git add src/Interface/Views/HeatmapGridView.swift
git commit -m "feat(ui): default heatmap scroll to trailing latest date and sync month headers"
```

---

### Task 4: Full App Build, Install, and Verification

**Files:**
- Output: `~/Applications/GitContributionWidget.app`

- [ ] **Step 1: Run full installation script**

Run: `sh install.sh`
Expected: Clean compilation, installation to `~/Applications`, and launch of `GitContributionWidget`.

- [ ] **Step 2: Verify functionality**

1. Click menu bar icon: Verify popover opens with heatmap showing the latest rightmost dates (today & current week) by default.
2. Scroll to the left (past dates): Close popover and click menu bar icon again. Verify heatmap resets to showing the latest rightmost dates.
3. Verify month header labels scroll synchronously with the week columns.
4. Click refresh (🔄) button: Verify fresh fetch is performed without local cache lock.

- [ ] **Step 3: Final commit & cleanup**

```bash
git status
```
