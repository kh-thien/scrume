//
//  ReportsTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import Charts
import SwiftUI

/// Reports Tab - Statistics and Charts
struct ReportsTabView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var selectedReportType: ReportType = .burndown
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: isIPad ? 24 : 20) {
                    // Report Type Picker
                    Picker("Report Type", selection: $selectedReportType) {
                        ForEach(ReportType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, isIPad ? 24 : 16)

                    // Report Content
                    switch selectedReportType {
                    case .burndown:
                        BurndownChartView(project: project)
                    case .velocity:
                        VelocityChartView(project: project)
                    case .summary:
                        SprintSummaryView(project: project)
                    }
                }
                .padding(.vertical)
                .padding(.bottom, isIPad ? 20 : 80)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reports")
        }
    }
}

// MARK: - Report Type

enum ReportType: String, CaseIterable, Identifiable {
    case burndown
    case velocity
    case summary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .burndown: return "Burndown"
        case .velocity: return "Velocity"
        case .summary: return "Summary"
        }
    }

    var icon: String {
        switch self {
        case .burndown: return "chart.line.downtrend.xyaxis"
        case .velocity: return "chart.bar.fill"
        case .summary: return "doc.text.fill"
        }
    }
}

// MARK: - Burndown Chart

struct BurndownChartView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Sprint Burndown")
                    .font(.headline)
                Text("Remaining work over time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if let activeSprint = project.activeSprint {
                // Chart
                Chart {
                    // Ideal line
                    ForEach(idealBurndownData(for: activeSprint), id: \.day) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Points", point.points)
                        )
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }

                    // Actual line
                    ForEach(actualBurndownData(for: activeSprint), id: \.day) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Points", point.points)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))

                        PointMark(
                            x: .value("Day", point.day),
                            y: .value("Points", point.points)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxisLabel("Days")
                .chartYAxisLabel("Story Points")
                .frame(height: 250)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Legend
                HStack(spacing: 20) {
                    LegendItem(color: .gray.opacity(0.5), label: "Ideal", isDashed: true)
                    LegendItem(color: .blue, label: "Actual", isDashed: false)
                }
                .padding(.horizontal)

                // Stats
                BurndownStatsView(sprint: activeSprint)

            } else {
                NoActiveSprintPlaceholder()
            }
        }
    }

    private func idealBurndownData(for sprint: Sprint) -> [BurndownPoint] {
        let totalPoints = sprint.totalStoryPoints
        let days = max(sprint.durationDays, 1)

        return (0...days).map { day in
            let remaining = Double(totalPoints) * (1.0 - Double(day) / Double(days))
            return BurndownPoint(day: day, points: max(0, remaining))
        }
    }

    private func actualBurndownData(for sprint: Sprint) -> [BurndownPoint] {
        // Simplified: show current state
        // In real app, would track daily progress
        let totalPoints = sprint.totalStoryPoints
        let completedPoints = sprint.completedStoryPoints
        let remaining = totalPoints - completedPoints

        let daysPassed = sprint.daysPassed

        var points: [BurndownPoint] = []

        // Start point
        points.append(BurndownPoint(day: 0, points: Double(totalPoints)))

        // Current point
        if daysPassed > 0 {
            points.append(BurndownPoint(day: daysPassed, points: Double(remaining)))
        }

        return points
    }
}

struct BurndownPoint: Identifiable {
    let day: Int
    let points: Double
    var id: Int { day }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let isDashed: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isDashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    .frame(width: 24, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 24, height: 3)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct BurndownStatsView: View {
    let sprint: Sprint

    var body: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Total",
                value: "\(sprint.totalStoryPoints)",
                subtitle: "points",
                color: .blue
            )

            StatBox(
                title: "Completed",
                value: "\(sprint.completedStoryPoints)",
                subtitle: "points",
                color: .green
            )

            StatBox(
                title: "Remaining",
                value: "\(sprint.totalStoryPoints - sprint.completedStoryPoints)",
                subtitle: "points",
                color: .orange
            )

            StatBox(
                title: "Progress",
                value: "\(Int(sprint.progressPercentage))%",
                subtitle: "done",
                color: .purple
            )
        }
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(subtitle.isEmpty ? " " : subtitle)
                .font(.caption2)
                .foregroundStyle(subtitle.isEmpty ? .clear : .secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Velocity Chart

struct VelocityChartView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Team Velocity")
                    .font(.headline)
                Text("Story points completed per sprint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if completedSprints.isEmpty {
                NoDataPlaceholder(
                    icon: "chart.bar",
                    message: "Complete at least one sprint to see velocity data"
                )
            } else {
                // Chart
                Chart {
                    ForEach(velocityData, id: \.sprintName) { data in
                        BarMark(
                            x: .value("Sprint", data.sprintName),
                            y: .value("Points", data.completedPoints)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(6)
                    }

                    // Average line
                    if averageVelocity > 0 {
                        RuleMark(y: .value("Average", averageVelocity))
                            .foregroundStyle(.orange)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("Avg: \(Int(averageVelocity))")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 250)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)

                // Velocity Stats
                VelocityStatsView(
                    averageVelocity: averageVelocity,
                    lastVelocity: velocityData.last?.completedPoints ?? 0,
                    trend: velocityTrend
                )
            }
        }
    }

    private var completedSprints: [Sprint] {
        project.sprints.filter { $0.status == .completed }
    }

    private var velocityData: [VelocityPoint] {
        completedSprints.suffix(6).map { sprint in
            VelocityPoint(
                sprintName: String(sprint.name.prefix(10)),
                completedPoints: sprint.completedStoryPoints
            )
        }
    }

    private var averageVelocity: Double {
        guard !completedSprints.isEmpty else { return 0 }
        let total = completedSprints.reduce(0) { $0 + $1.completedStoryPoints }
        return Double(total) / Double(completedSprints.count)
    }

    private var velocityTrend: VelocityTrend {
        guard velocityData.count >= 2 else { return .stable }
        let last = velocityData.last?.completedPoints ?? 0
        let previous = velocityData[velocityData.count - 2].completedPoints

        if last > previous + 2 { return .up }
        if last < previous - 2 { return .down }
        return .stable
    }
}

struct VelocityPoint {
    let sprintName: String
    let completedPoints: Int
}

enum VelocityTrend {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }

    var label: String {
        switch self {
        case .up: return "Improving"
        case .down: return "Declining"
        case .stable: return "Stable"
        }
    }
}

struct VelocityStatsView: View {
    let averageVelocity: Double
    let lastVelocity: Int
    let trend: VelocityTrend

    var body: some View {
        HStack(spacing: 16) {
            StatBox(
                title: "Average",
                value: String(format: "%.1f", averageVelocity),
                subtitle: "pts/sprint",
                color: .orange
            )

            StatBox(
                title: "Last Sprint",
                value: "\(lastVelocity)",
                subtitle: "points",
                color: .blue
            )

            VStack(spacing: 4) {
                Text("Trend")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                    Text(trend.label)
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(trend.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Sprint Summary

struct SprintSummaryView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Sprint Summary")
                    .font(.headline)
                Text("Overview of all sprints")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if project.sprints.isEmpty {
                NoDataPlaceholder(
                    icon: "arrow.triangle.2.circlepath",
                    message: "No sprints created yet"
                )
            } else {
                // Overall Stats
                OverallStatsView(project: project)

                // Sprint Cards
                ForEach(
                    project.sprints.sorted(by: {
                        ($0.startDate ?? Date.distantPast) > ($1.startDate ?? Date.distantPast)
                    })
                ) { sprint in
                    SprintSummaryCard(sprint: sprint)
                }
            }
        }
    }
}

struct OverallStatsView: View {
    let project: Project

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                OverallStatItem(
                    icon: "arrow.triangle.2.circlepath",
                    value: "\(project.sprints.count)",
                    label: "Total Sprints",
                    color: .blue
                )

                OverallStatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(completedSprints)",
                    label: "Completed",
                    color: .green
                )

                OverallStatItem(
                    icon: "number",
                    value: "\(totalPointsCompleted)",
                    label: "Points Done",
                    color: .purple
                )
            }

            HStack(spacing: 16) {
                OverallStatItem(
                    icon: "doc.text.fill",
                    value: "\(totalStoriesCompleted)",
                    label: "Stories Done",
                    color: .orange
                )

                OverallStatItem(
                    icon: "person.2.fill",
                    value: "\(project.members.count)",
                    label: "Team Size",
                    color: .blue
                )

                OverallStatItem(
                    icon: "chart.line.uptrend.xyaxis",
                    value: String(format: "%.0f", avgVelocity),
                    label: "Avg Velocity",
                    color: .green
                )
            }
        }
        .padding(.horizontal)
    }

    private var completedSprints: Int {
        project.sprints.filter { $0.status == .completed }.count
    }

    private var totalPointsCompleted: Int {
        project.sprints.reduce(0) { $0 + $1.completedStoryPoints }
    }

    private var totalStoriesCompleted: Int {
        project.sprints.reduce(0) { $0 + $1.doneStories.count }
    }

    private var avgVelocity: Double {
        guard completedSprints > 0 else { return 0 }
        return Double(totalPointsCompleted) / Double(completedSprints)
    }
}

struct OverallStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SprintSummaryCard: View {
    let sprint: Sprint

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sprint.name)
                        .font(.headline)

                    if let start = sprint.startDate, let end = sprint.endDate {
                        Text(
                            "\(start.formatted(.dateTime.month().day())) - \(end.formatted(.dateTime.month().day()))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                StatusBadge(status: sprint.status)
            }

            // Progress
            VStack(spacing: 4) {
                ProgressView(value: sprint.progressPercentage, total: 100)
                    .tint(sprint.status == .completed ? .green : .blue)

                HStack {
                    Text("\(sprint.completedStoryPoints)/\(sprint.totalStoryPoints) points")
                    Spacer()
                    Text("\(Int(sprint.progressPercentage))%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Story breakdown
            HStack(spacing: 20) {
                SprintStatLabel(
                    count: sprint.doneStories.count,
                    label: "Done",
                    color: .green
                )

                SprintStatLabel(
                    count: sprint.inProgressStories.count,
                    label: "In Progress",
                    color: .blue
                )

                SprintStatLabel(
                    count: sprint.todoStories.count,
                    label: "To Do",
                    color: .gray
                )
            }

            // Goal
            if !sprint.goal.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "target")
                        .foregroundStyle(.orange)
                    Text(sprint.goal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let status: SprintStatus

    var body: some View {
        Label(status.rawValue, systemImage: status.icon)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .cornerRadius(8)
    }
}

struct SprintStatLabel: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Placeholders

struct NoActiveSprintPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text("No Active Sprint")
                .font(.headline)

            Text("Start a sprint to see burndown data")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct NoDataPlaceholder: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Sprint Extensions

extension Sprint {
    var durationDays: Int {
        guard let start = startDate, let end = endDate else { return 14 }
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 14
    }

    var daysPassed: Int {
        guard let start = startDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(0, min(days, durationDays))
    }
}

// MARK: - Preview

#Preview {
    ReportsTabView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
