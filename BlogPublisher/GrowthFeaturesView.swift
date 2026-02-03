import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("성장 대시보드")
                    .font(.title2.bold())
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Streak Section
                    StreakCard()

                    // Heatmap Section
                    HeatmapCard()

                    // Stats Summary
                    StatsSummaryCard()

                    // Weekly Progress
                    WeeklyProgressCard()

                    // Platform Performance (Placeholder)
                    PlatformStatsCard()
                }
                .padding()
            }
        }
        .frame(width: 700, height: 600)
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.title)
                Text("글쓰기 스트릭")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 40) {
                // Current Streak
                VStack(spacing: 8) {
                    Text("\(appState.writingStats.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("현재 스트릭")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 60)

                // Longest Streak
                VStack(spacing: 8) {
                    Text("\(appState.writingStats.longestStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("최장 스트릭")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 60)

                // Total Published
                VStack(spacing: 8) {
                    Text("\(appState.writingStats.totalPostsPublished)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("총 발행")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Streak message
            if appState.writingStats.currentStreak > 0 {
                Text(streakMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    var streakMessage: String {
        let streak = appState.writingStats.currentStreak
        if streak >= 30 {
            return "한 달 연속 글쓰기 달성! 대단합니다!"
        } else if streak >= 7 {
            return "일주일 연속 글쓰기! 습관이 되어가고 있어요!"
        } else if streak >= 3 {
            return "3일 연속 글쓰기! 계속 이어가세요!"
        } else {
            return "오늘도 글을 쓰셨군요! 내일도 화이팅!"
        }
    }
}

// MARK: - Heatmap Card
struct HeatmapCard: View {
    @EnvironmentObject var appState: AppState

    let columns = 53 // weeks
    let rows = 7 // days

    var publishCounts: [Date: Int] {
        appState.writingStats.publishCountByDate()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.green)
                Text("발행 히트맵")
                    .font(.headline)
                Spacer()
                Text("최근 1년")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Day labels
            HStack(spacing: 2) {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .frame(height: 10)
                    }
                }
                .frame(width: 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(0..<columns, id: \.self) { week in
                            VStack(spacing: 2) {
                                ForEach(0..<rows, id: \.self) { day in
                                    let date = dateFor(week: week, day: day)
                                    let count = publishCounts[date] ?? 0
                                    Rectangle()
                                        .fill(colorForCount(count))
                                        .frame(width: 10, height: 10)
                                        .cornerRadius(2)
                                        .help(tooltipFor(date: date, count: count))
                                }
                            }
                        }
                    }
                }
            }

            // Legend
            HStack {
                Text("적음")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach([0, 1, 2, 3, 4], id: \.self) { level in
                    Rectangle()
                        .fill(colorForLevel(level))
                        .frame(width: 10, height: 10)
                        .cornerRadius(2)
                }

                Text("많음")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    func dateFor(week: Int, day: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)

        // 시작 날짜 계산 (1년 전)
        let weeksAgo = columns - 1 - week
        let daysAgo = weeksAgo * 7 + (todayWeekday - 1 - day)
        return calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
    }

    func colorForCount(_ count: Int) -> Color {
        if count == 0 {
            return Color(nsColor: .separatorColor).opacity(0.3)
        } else if count == 1 {
            return .green.opacity(0.4)
        } else if count == 2 {
            return .green.opacity(0.6)
        } else if count <= 4 {
            return .green.opacity(0.8)
        } else {
            return .green
        }
    }

    func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color(nsColor: .separatorColor).opacity(0.3)
        case 1: return .green.opacity(0.4)
        case 2: return .green.opacity(0.6)
        case 3: return .green.opacity(0.8)
        default: return .green
        }
    }

    func tooltipFor(date: Date, count: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: date)
        return "\(dateStr): \(count)개 발행"
    }
}

// MARK: - Stats Summary Card
struct StatsSummaryCard: View {
    @EnvironmentObject var appState: AppState

    var thisWeekCount: Int {
        appState.writingStats.postsThisWeek()
    }

    var thisMonthCount: Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        return appState.writingStats.publishHistory.filter { $0.publishedAt >= startOfMonth }.count
    }

    var body: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "이번 주",
                value: "\(thisWeekCount)",
                goal: appState.writingStats.weeklyGoal,
                icon: "calendar.badge.clock",
                color: .blue
            )

            StatBox(
                title: "이번 달",
                value: "\(thisMonthCount)",
                goal: nil,
                icon: "calendar",
                color: .purple
            )

            StatBox(
                title: "마지막 발행",
                value: lastPublishText,
                goal: nil,
                icon: "clock",
                color: .orange
            )
        }
    }

    var lastPublishText: String {
        guard let lastDate = appState.writingStats.lastPublishDate else {
            return "없음"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastDate, relativeTo: Date())
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let goal: Int?
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.title2.bold())

            if let goal = goal {
                ProgressView(value: Double(Int(value) ?? 0), total: Double(goal))
                    .tint(color)
                Text("\(goal)개 목표")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Weekly Progress Card
struct WeeklyProgressCard: View {
    @EnvironmentObject var appState: AppState

    var weeklyData: [(String, Int)] {
        let calendar = Calendar.current
        let today = Date()
        var data: [(String, Int)] = []

        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let count = appState.writingStats.publishCountByDate()[calendar.startOfDay(for: date)] ?? 0
            data.append((dayName, count))
        }

        return data
    }

    var maxCount: Int {
        max(weeklyData.map { $0.1 }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("주간 발행 현황")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData, id: \.0) { day, count in
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(count > 0 ? Color.blue : Color.blue.opacity(0.2))
                            .frame(width: 30, height: max(CGFloat(count) / CGFloat(maxCount) * 80, 4))

                        Text(day)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Platform Stats Card
struct PlatformStatsCard: View {
    @EnvironmentObject var appState: AppState

    var platformCounts: [(PlatformType, Int)] {
        var counts: [String: Int] = [:]

        for record in appState.writingStats.publishHistory {
            counts[record.platform, default: 0] += 1
        }

        return counts.compactMap { key, value in
            guard let type = PlatformType(rawValue: key) else { return nil }
            return (type, value)
        }.sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(.purple)
                Text("플랫폼별 발행")
                    .font(.headline)
                Spacer()
            }

            if platformCounts.isEmpty {
                Text("아직 발행 기록이 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(platformCounts, id: \.0) { platform, count in
                    HStack {
                        Image(systemName: platform.icon)
                            .foregroundStyle(platform.color)
                            .frame(width: 20)

                        Text(platform.defaultName)
                            .font(.subheadline)

                        Spacer()

                        Text("\(count)개")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Progress bar
                        let total = appState.writingStats.totalPostsPublished
                        let percentage = total > 0 ? Double(count) / Double(total) : 0
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(platform.color.opacity(0.3))
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(platform.color)
                                        .frame(width: geo.size.width * percentage)
                                }
                        }
                        .frame(width: 100, height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Mini Streak View (For Sidebar)
struct MiniStreakView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Flame icon with streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(appState.writingStats.currentStreak > 0 ? .orange : .gray)
                Text("\(appState.writingStats.currentStreak)")
                    .font(.system(.body, design: .rounded).bold())
            }

            Divider()
                .frame(height: 16)

            // This week progress
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.blue)
                Text("\(appState.writingStats.postsThisWeek())/\(appState.writingStats.weeklyGoal)")
                    .font(.system(.body, design: .rounded))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
