import SwiftUI

public struct HeatmapGridView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var calendar: ContributionCalendar {
        appState.overview.calendar
    }

    private var theme: Theme {
        appState.overview.theme
    }

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3
    private let cornerRadius: CGFloat = 2.5

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Heatmap Grid + Weekday Labels + Month Headers (Unified ScrollView)
            HStack(alignment: .top, spacing: 6) {
                // Weekday Labels (Mon, Wed, Fri)
                VStack(alignment: .trailing, spacing: cellSpacing) {
                    Color.clear.frame(height: 20) // Offset for month header height (14) + spacing (6)

                    Text("") // Sun
                        .frame(height: cellSize)
                    Text("Mon")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: "#8b949e"))
                        .frame(height: cellSize)
                    Text("") // Tue
                        .frame(height: cellSize)
                    Text("Wed")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: "#8b949e"))
                        .frame(height: cellSize)
                    Text("") // Thu
                        .frame(height: cellSize)
                    Text("Fri")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: "#8b949e"))
                        .frame(height: cellSize)
                    Text("") // Sat
                        .frame(height: cellSize)
                }
                .frame(width: 26, alignment: .trailing)

                // Scrollable Month Headers & 52-Week Columns
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 6) {
                            // Month Headers
                            ZStack(alignment: .leading) {
                                ForEach(calendar.monthHeaders) { header in
                                    let xOffset = CGFloat(header.weekIndex) * (cellSize + cellSpacing)
                                    Text(header.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color(hex: "#8b949e"))
                                        .offset(x: xOffset, y: 0)
                                }
                            }
                            .frame(height: 14, alignment: .leading)

                            // 52-Week Columns
                            HStack(spacing: cellSpacing) {
                                ForEach(Array(calendar.weeks.enumerated()), id: \.offset) { weekIdx, week in
                                    VStack(spacing: cellSpacing) {
                                        ForEach(week) { day in
                                            DaySquareView(
                                                day: day,
                                                theme: theme,
                                                isHovered: appState.hoveredDay?.id == day.id,
                                                cellSize: cellSize,
                                                cornerRadius: cornerRadius
                                            )
                                            .onHover { isHovered in
                                                if isHovered {
                                                    appState.hoveredDay = day
                                                } else if appState.hoveredDay?.id == day.id {
                                                    appState.hoveredDay = nil
                                                }
                                            }
                                        }
                                    }
                                }

                                // Trailing anchor for auto-scroll
                                Color.clear
                                    .frame(width: 1, height: 1)
                                    .id("heatmap_trailing_edge")
                            }
                        }
                    }
                    .onAppear {
                        scrollToLatest(proxy: proxy)
                    }
                    .onChange(of: appState.popoverOpenTrigger) { _ in
                        scrollToLatest(proxy: proxy)
                    }
                    .onChange(of: appState.overview.lastFetched) { _ in
                        scrollToLatest(proxy: proxy)
                    }
                }
            }

            // 3. Bottom Footer (Hover Details & Less..More Legend)
            HStack(alignment: .center) {
                // Live hover tooltip / help text
                if let hovered = appState.hoveredDay {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: theme.hex(for: hovered.level)))
                            .frame(width: 8, height: 8)
                        Text("\(hovered.count) contribution\(hovered.count == 1 ? "" : "s") on \(hovered.dateString)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#f0f6fc"))
                    }
                    .transition(.opacity)
                } else {
                    Text("Learn how we count contributions")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#8b949e"))
                }

                Spacer()

                // Less -> More Legend
                HStack(spacing: 4) {
                    Text("Less")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#8b949e"))

                    ForEach(0..<5, id: \.self) { lvl in
                        let level = ContributionLevel.from(raw: lvl)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: theme.hex(for: level)))
                            .frame(width: 10, height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    }

                    Text("More")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#8b949e"))
                }
            }
            .padding(.top, 4)
            .padding(.horizontal, 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#0d1117"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: "#30363d"), lineWidth: 1)
        )
    }

    private func scrollToLatest(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("heatmap_trailing_edge", anchor: .trailing)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo("heatmap_trailing_edge", anchor: .trailing)
        }
    }
}

private struct DaySquareView: View {
    let day: ContributionDay
    let theme: Theme
    let isHovered: Bool
    let cellSize: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(hex: theme.hex(for: day.level)))
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHovered ? Color.white : Color.white.opacity(0.08),
                        lineWidth: isHovered ? 1.5 : 0.5
                    )
            )
            .scaleEffect(isHovered ? 1.25 : 1.0)
            .zIndex(isHovered ? 10 : 0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .help("\(day.count) contributions on \(day.dateString)")
    }
}
