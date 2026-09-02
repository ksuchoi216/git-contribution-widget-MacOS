import SwiftUI

public struct StatCardsView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    private var stats: ContributionStats {
        appState.overview.stats
    }

    private var theme: Theme {
        appState.overview.theme
    }

    public var body: some View {
        HStack(spacing: 8) {
            // 1. Total Past Year
            StatCard(
                title: "Last Year",
                value: "\(appState.overview.calendar.totalContributions > 0 ? appState.overview.calendar.totalContributions : stats.totalContributions)",
                unit: "contributions",
                accentColor: Color(hex: theme.hex(for: .level3)),
                icon: "chart.bar.fill"
            )

            // 2. Current Streak
            StatCard(
                title: "Current Streak",
                value: "\(stats.currentStreak)",
                unit: stats.currentStreak == 1 ? "day" : "days",
                accentColor: Color.orange,
                icon: "flame.fill"
            )

            // 3. Longest Streak
            StatCard(
                title: "Longest Streak",
                value: "\(stats.longestStreak)",
                unit: stats.longestStreak == 1 ? "day" : "days",
                accentColor: Color.yellow,
                icon: "trophy.fill"
            )

            // 4. Today's Count
            StatCard(
                title: "Today",
                value: "\(stats.todayCount)",
                unit: stats.todayCount == 1 ? "commit" : "commits",
                accentColor: Color(hex: theme.hex(for: .level4)),
                icon: "bolt.fill"
            )
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let accentColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "#161b22").opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "#30363d").opacity(0.7), lineWidth: 0.8)
        )
    }
}
