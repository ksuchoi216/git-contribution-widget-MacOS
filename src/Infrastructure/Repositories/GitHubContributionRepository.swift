import Foundation

public final class GitHubContributionRepository: ContributionRepositoryProtocol, Sendable {
    private let httpClient: HTTPClient

    public init(httpClient: HTTPClient = .shared) {
        self.httpClient = httpClient
    }

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
            let data = try await httpClient.fetchData(from: jsonUrl, cachePolicy: .reloadIgnoringLocalCacheData)
            return try parseFallbackJSON(data: data, username: trimmedUsername)
        } catch {
            throw NetworkError.serverError("Unable to fetch contributions for '\(trimmedUsername)'. Please check network connection and username.")
        }
    }

    // MARK: - HTML Parsing Logic

    private func parseGitHubHTML(html: String, username: String) throws -> ContributionCalendar {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        // 1. Parse Tooltips for exact contribution counts: map tooltip "for" ID -> count
        var countForDayId: [String: Int] = [:]
        let tooltipPattern = #"<tool-tip[^>]*for="([^"]+)"[^>]*>([^<]+)</tool-tip>"#
        if let tooltipRegex = try? NSRegularExpression(pattern: tooltipPattern, options: []) {
            let nsString = html as NSString
            let matches = tooltipRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                guard match.numberOfRanges >= 3 else { continue }
                let forId = nsString.substring(with: match.range(at: 1))
                let tooltipText = nsString.substring(with: match.range(at: 2))

                // Parse "X contribution(s) on ..." or "No contributions on ..."
                if tooltipText.lowercased().starts(with: "no contribution") {
                    countForDayId[forId] = 0
                } else if let numberMatch = tooltipText.range(of: #"^\d+"#, options: .regularExpression),
                          let count = Int(tooltipText[numberMatch]) {
                    countForDayId[forId] = count
                }
            }
        }

        // 2. Parse <td> cells for days: data-date, data-level, id
        // Note: attributes can appear in any order in the <td> tag
        var days: [ContributionDay] = []
        let tdPattern = #"<td\b([^>]*class="[^"]*ContributionCalendar-day[^"]*"[^>]*)>"#
        let attrRegex = try? NSRegularExpression(pattern: tdPattern, options: [])
        let dateRegex = try? NSRegularExpression(pattern: #"data-date="(\d{4}-\d{2}-\d{2})""#, options: [])
        let levelRegex = try? NSRegularExpression(pattern: #"data-level="(\d+)""#, options: [])
        let idRegex = try? NSRegularExpression(pattern: #"id="([^"]+)""#, options: [])

        let cal = Calendar.current
        let nsHtml = html as NSString

        if let attrRegex = attrRegex {
            let tdMatches = attrRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsHtml.length))
            for tdMatch in tdMatches {
                let tagAttrs = nsHtml.substring(with: tdMatch.range(at: 1))
                let tagNs = tagAttrs as NSString

                guard let dMatch = dateRegex?.firstMatch(in: tagAttrs, options: [], range: NSRange(location: 0, length: tagNs.length)),
                      dMatch.numberOfRanges >= 2 else { continue }
                let dateStr = tagNs.substring(with: dMatch.range(at: 1))

                var levelInt = 0
                if let lMatch = levelRegex?.firstMatch(in: tagAttrs, options: [], range: NSRange(location: 0, length: tagNs.length)),
                   lMatch.numberOfRanges >= 2 {
                    levelInt = Int(tagNs.substring(with: lMatch.range(at: 1))) ?? 0
                }

                var count = levelInt > 0 ? 1 : 0
                if let iMatch = idRegex?.firstMatch(in: tagAttrs, options: [], range: NSRange(location: 0, length: tagNs.length)),
                   iMatch.numberOfRanges >= 2 {
                    let dayId = tagNs.substring(with: iMatch.range(at: 1))
                    if let exactCount = countForDayId[dayId] {
                        count = exactCount
                    }
                }

                let date = dateFormatter.date(from: dateStr) ?? Date()
                let weekday = cal.component(.weekday, from: date)
                let level = ContributionLevel.from(raw: levelInt)

                days.append(ContributionDay(
                    dateString: dateStr,
                    date: date,
                    count: count,
                    level: level,
                    weekday: weekday
                ))
            }
        }

        // Sort days chronologically
        days.sort { $0.dateString < $1.dateString }

        // 3. Parse total contributions from header if available
        var totalContributions = days.reduce(0) { $0 + $1.count }
        let totalPattern = #"([\d,]+)\s+contributions\s+in the last year"#
        if let totalRegex = try? NSRegularExpression(pattern: totalPattern, options: []),
           let match = totalRegex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsHtml.length)),
           match.numberOfRanges >= 2 {
            let totalStr = nsHtml.substring(with: match.range(at: 1)).replacingOccurrences(of: ",", with: "")
            if let parsedTotal = Int(totalStr) {
                totalContributions = parsedTotal
            }
        }

        // 4. Organize into 52+ columns of weeks (Sunday = row 0, Saturday = row 6)
        var weeks: [[ContributionDay]] = []
        var currentWeek: [ContributionDay] = []
        for day in days {
            currentWeek.append(day)
            if day.weekday == 7 { // Saturday ends week
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        // 5. Parse Month Headers
        var monthHeaders: [MonthHeader] = []
        let monthPattern = #"<td class="ContributionCalendar-label"[^>]*>.*?<span aria-hidden="true"[^>]*>([A-Za-z]+)</span>"#
        if let monthRegex = try? NSRegularExpression(pattern: monthPattern, options: [.dotMatchesLineSeparators]) {
            let matches = monthRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsHtml.length))
            for (idx, m) in matches.enumerated() {
                if m.numberOfRanges >= 2 {
                    let monthName = nsHtml.substring(with: m.range(at: 1))
                    // Spread months proportionally across ~52 weeks
                    let estimatedWeek = Int(Double(idx) * 4.3)
                    monthHeaders.append(MonthHeader(name: monthName, weekIndex: min(estimatedWeek, 52)))
                }
            }
        }

        // Fallback default month headers if regex couldn't extract
        if monthHeaders.isEmpty {
            monthHeaders = generateDefaultMonthHeaders(for: days)
        }

        return ContributionCalendar(
            username: username,
            days: days,
            weeks: weeks,
            monthHeaders: monthHeaders,
            totalContributions: totalContributions,
            updatedAt: Date()
        )
    }

    // MARK: - JSON Fallback Parsing Logic

    private struct APIResponse: Codable {
        struct ContributionEntry: Codable {
            let date: String
            let count: Int
            let level: Int
        }
        let total: [String: Int]?
        let contributions: [ContributionEntry]
    }

    private func parseFallbackJSON(data: Data, username: String) throws -> ContributionCalendar {
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let cal = Calendar.current

        var days: [ContributionDay] = []
        for entry in decoded.contributions {
            let date = dateFormatter.date(from: entry.date) ?? Date()
            let weekday = cal.component(.weekday, from: date)
            days.append(ContributionDay(
                dateString: entry.date,
                date: date,
                count: entry.count,
                level: ContributionLevel.from(raw: entry.level),
                weekday: weekday
            ))
        }

        days.sort { $0.dateString < $1.dateString }

        var weeks: [[ContributionDay]] = []
        var currentWeek: [ContributionDay] = []
        for day in days {
            currentWeek.append(day)
            if day.weekday == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            weeks.append(currentWeek)
        }

        let total = days.reduce(0) { $0 + $1.count }
        let monthHeaders = generateDefaultMonthHeaders(for: days)

        return ContributionCalendar(
            username: username,
            days: days,
            weeks: weeks,
            monthHeaders: monthHeaders,
            totalContributions: total,
            updatedAt: Date()
        )
    }

    private func generateDefaultMonthHeaders(for days: [ContributionDay]) -> [MonthHeader] {
        var headers: [MonthHeader] = []
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        var lastMonth = -1
        for (index, day) in days.enumerated() {
            let month = cal.component(.month, from: day.date)
            if month != lastMonth {
                lastMonth = month
                let name = formatter.string(from: day.date)
                let weekIdx = index / 7
                headers.append(MonthHeader(name: name, weekIndex: weekIdx))
            }
        }
        return headers
    }
}
