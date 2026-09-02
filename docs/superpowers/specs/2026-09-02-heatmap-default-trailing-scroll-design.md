# Contribution Heatmap Default Trailing (Latest Date) Scroll Design

## Problem Statement
When the user clicks the menu bar icon to open the popover widget, the contribution heatmap `ScrollView` starts at horizontal offset 0 (the leftmost position, representing dates from ~1 year ago). The user has to manually scroll to the right every time to see recent contributions (today, this week, and recent months). Additionally, the month header labels were placed outside the `ScrollView`, meaning that when scrolling the week columns, the month labels remained static and misaligned.

## Proposed Solution
1. **Synchronize Month Headers and Week Grid**:
   - Embed the month header labels inside the horizontal `ScrollView` directly above the 52-week columns in a unified `VStack`.
   - Keep the weekday labels ("Mon", "Wed", "Fri") stationary on the left side of the `ScrollView`.
2. **Default Focus to Rightmost (Latest) Position**:
   - Introduce `ScrollViewReader` around the horizontal `ScrollView`.
   - Place an invisible anchor view (`id("heatmap_trailing_edge")`) at the trailing end of the 52-week grid.
   - Automatically scroll to `"heatmap_trailing_edge"` with `anchor: .trailing` on:
     - View initial appearance (`onAppear`).
     - Popover open events (`appState.popoverOpenTrigger`).
     - Data refresh completion (`appState.overview`).
3. **Event Notification**:
   - Add `popoverOpenTrigger: Int` and `notifyPopoverOpened()` to `AppState`.
   - Call `appState.notifyPopoverOpened()` in `PopoverController.showPopover(sender:)`.

## Component Changes

### 1. `AppState.swift` (`src/Interface/Controllers/AppState.swift`)
- Add `@Published public var popoverOpenTrigger: Int = 0`.
- Add `public func notifyPopoverOpened()` which increments `popoverOpenTrigger += 1`.

### 2. `PopoverController.swift` (`src/Interface/Controllers/PopoverController.swift`)
- Call `appState.notifyPopoverOpened()` before showing the popover in `showPopover(sender:)`.

### 3. `HeatmapGridView.swift` (`src/Interface/Views/HeatmapGridView.swift`)
- Wrap the horizontal scroll area in `ScrollViewReader { proxy in ... }`.
- Place Month Headers and Week Columns in a `VStack` inside the `ScrollView`.
- Add a trailing spacer/view with `.id("heatmap_trailing_edge")`.
- Helper function `scrollToLatest(proxy: ScrollViewProxy)` using `DispatchQueue.main.async` to ensure layout calculations are settled.
- Attach `.onAppear`, `.onChange(of: appState.popoverOpenTrigger)`, and `.onChange(of: appState.overview.lastFetched)` listeners to call `scrollToLatest(proxy:)`.

## Verification Plan

### Automated Verification
- Run existing test suites: `swift run` or swift tests via `tests/` directory scripts.
- Build verification: `sh install.sh --build-only` to ensure zero compilation errors.

### Manual Verification
1. Launch the app and click the menu bar item.
2. Confirm the heatmap immediately displays the rightmost (most recent) weeks, including today's date square and recent month labels (e.g. Jul, Aug, Sep).
3. Scroll horizontally to the left (past dates), close the popover by clicking outside, and click the menu bar item again.
4. Confirm the popover re-opens with the heatmap reset to the rightmost (latest) view.
5. Confirm month headers scroll cleanly and stay aligned with their respective week columns when scrolled.
