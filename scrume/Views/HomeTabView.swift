//
//  HomeTabView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Home Tab - Dashboard với overview
struct HomeTabView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var selectedTab: Int

    @State private var showCreateSprint = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: isIPad ? 24 : 20) {
                    // MARK: - Active Sprint Card
                    if let activeSprint = project.activeSprint,
                        project.sprints.contains(where: { $0.id == activeSprint.id })
                    {
                        ActiveSprintCard(
                            sprint: activeSprint,
                            onBoardTap: { selectedTab = 1 }
                        )
                    } else {
                        NoActiveSprintCard(project: $project, viewModel: viewModel)
                    }

                    // MARK: - Quick Stats
                    QuickStatsView(project: project)

                    // MARK: - Sprints (Compact)
                    SprintsCompactView(
                        project: $project, viewModel: viewModel, selectedTab: $selectedTab)
                }
                .padding(isIPad ? 24 : 16)
                .padding(.bottom, isIPad ? 20 : 80)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSprint = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreateSprint) {
                CreateSprintView(project: $project, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Active Sprint Card

struct ActiveSprintCard: View {
    let sprint: Sprint
    let onBoardTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Sprint")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(sprint.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if let endDate = sprint.endDate {
                    let days =
                        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                    VStack(alignment: .trailing) {
                        Text("\(max(0, days))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(days > 3 ? .blue : (days > 0 ? .orange : .red))
                        Text("days left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Goal
            if !sprint.goal.isEmpty {
                Text(sprint.goal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Progress
            VStack(spacing: 8) {
                ProgressView(value: sprint.progressPercentage, total: 100)
                    .tint(progressColor)

                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(StoryStatus.done.color).frame(width: 8, height: 8)
                        Text("\(sprint.doneStories.count) Done")
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle().fill(StoryStatus.inProgress.color).frame(width: 8, height: 8)
                        Text("\(sprint.inProgressStories.count) In Progress")
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle().fill(StoryStatus.todo.color).frame(width: 8, height: 8)
                        Text("\(sprint.todoStories.count) To Do")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            // Open Board Button
            Button(action: onBoardTap) {
                HStack {
                    Image(systemName: "rectangle.split.3x1")
                    Text("Open Scrum Board")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    private var progressColor: Color {
        if sprint.progressPercentage >= 80 { return .green }
        if sprint.progressPercentage >= 50 { return .blue }
        return .orange
    }
}

// MARK: - No Active Sprint Card

struct NoActiveSprintCard: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("No Active Sprint")
                .font(.headline)

            Text("Start a sprint from the list below or create a new one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Quick Stats

struct QuickStatsView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)

            HStack(spacing: 12) {
                StatCard(
                    icon: "doc.text.fill",
                    value: "\(project.backlog.count)",
                    label: "Backlog",
                    color: .blue
                )

                StatCard(
                    icon: "arrow.triangle.2.circlepath",
                    value: "\(project.sprints.count)",
                    label: "Sprints",
                    color: .orange
                )

                StatCard(
                    icon: "person.2.fill",
                    value: "\(project.members.count)",
                    label: "Team",
                    color: .green
                )

                StatCard(
                    icon: "number",
                    value: "\(project.totalBacklogPoints)",
                    label: "Points",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Recent Stories

struct RecentStoriesView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Stories")
                    .font(.headline)
                Spacer()
            }

            if recentStories.isEmpty {
                Text("No stories yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentStories.prefix(3)) { story in
                        RecentStoryRow(story: story, project: project)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    private var recentStories: [UserStory] {
        let allStories = project.backlog + project.sprints.flatMap { $0.stories }
        return allStories.sorted { $0.updatedAt > $1.updatedAt }
    }
}

struct RecentStoryRow: View {
    let story: UserStory
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(story.priority.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(story.title)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(story.status.rawValue, systemImage: story.status.icon)
                        .font(.caption2)
                        .foregroundStyle(story.status.color)

                    if !story.assigneeIds.isEmpty {
                        let assignees = project.members.filter { story.assigneeIds.contains($0.id) }
                        Text(
                            assignees.map { $0.name.components(separatedBy: " ").first ?? "" }
                                .joined(separator: ", ")
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
            }

            Spacer()

            Text("\(story.storyPoints)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Team Overview

struct TeamOverviewView: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Team")
                .font(.headline)

            if project.members.isEmpty {
                Text("No team members")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(project.members) { member in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: member.avatarColor))
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        Text(member.initials)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                    }

                                Text(member.name.components(separatedBy: " ").first ?? "")
                                    .font(.caption)
                                    .lineLimit(1)

                                Image(systemName: member.role.icon)
                                    .font(.caption2)
                                    .foregroundStyle(member.role.color)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Sprints Overview

struct SprintsOverviewView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var selectedTab: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sprints")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    SprintListView(project: $project, viewModel: viewModel)
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            if project.sprints.isEmpty {
                Text("No sprints yet. Create your first sprint!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(project.sprints.prefix(3)) { sprint in
                        SprintRowCard(
                            sprint: sprint,
                            project: $project,
                            viewModel: viewModel,
                            onBoardTap: { selectedTab = 1 }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct SprintRowCard: View {
    let sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    let onBoardTap: () -> Void

    @State private var showAddStories = false
    @State private var showStartConfirmation = false

    private var activeSprint: Sprint? {
        project.sprints.first(where: { $0.status == .active })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sprint.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let start = sprint.startDate, let end = sprint.endDate {
                        Text(
                            "\(start.formatted(.dateTime.month(.abbreviated).day())) - \(end.formatted(.dateTime.month(.abbreviated).day()))"
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Status badge
                Label(sprint.status.rawValue, systemImage: sprint.status.icon)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sprint.status.color.opacity(0.15))
                    .foregroundStyle(sprint.status.color)
                    .cornerRadius(6)
            }

            // Progress bar
            VStack(spacing: 4) {
                ProgressView(value: sprint.progressPercentage, total: 100)
                    .tint(sprint.status == .completed ? .green : .blue)

                HStack {
                    Text("\(sprint.doneStories.count)/\(sprint.stories.count) stories")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(sprint.completedStoryPoints)/\(sprint.totalStoryPoints) pts")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Action buttons for active/planning sprints
            if sprint.status == .active {
                HStack(spacing: 8) {
                    Button {
                        showAddStories = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Stories")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }

                    Button {
                        onBoardTap()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.split.3x1")
                            Text("Board")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                }
            } else if sprint.status == .planning {
                HStack(spacing: 8) {
                    Button {
                        showAddStories = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Stories")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }

                    Button {
                        if activeSprint != nil {
                            showStartConfirmation = true
                        } else {
                            startSprint()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showAddStories) {
            if let sprintIndex = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
                AddStoriesToSprintView(
                    sprint: $project.sprints[sprintIndex],
                    project: $project,
                    viewModel: viewModel
                )
            }
        }
        .alert("Start New Sprint?", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Complete & Start", role: .destructive) {
                startSprint()
            }
        } message: {
            if let active = activeSprint {
                Text(
                    "\"\(active.name)\" is currently active.\n\nStarting \"\(sprint.name)\" will mark it as Completed.\n\nProgress: \(active.doneStories.count)/\(active.stories.count) stories done."
                )
            }
        }
    }

    private func startSprint() {
        guard let index = project.sprints.firstIndex(where: { $0.id == sprint.id }) else { return }

        // Deactivate any currently active sprint
        for i in project.sprints.indices {
            if project.sprints[i].status == .active {
                project.sprints[i].status = .completed
            }
        }

        // Activate this sprint
        project.sprints[index].status = .active
        if project.sprints[index].startDate == nil {
            project.sprints[index].startDate = Date()
        }
        if project.sprints[index].endDate == nil {
            let weeks = project.sprintDurationWeeks
            project.sprints[index].endDate = Calendar.current.date(
                byAdding: .weekOfYear, value: weeks, to: Date())
        }

        viewModel.updateProject(project)
    }
}

// MARK: - Sprints Compact View

struct SprintsCompactView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var selectedTab: Int

    // Lọc ra các sprint không phải active (vì đã hiển thị ở trên)
    private var otherSprints: [Sprint] {
        project.sprints.filter { $0.status != .active }
            .sorted { s1, s2 in
                // Planning sprints trước, rồi đến Completed
                if s1.status == .planning && s2.status != .planning { return true }
                if s1.status != .planning && s2.status == .planning { return false }
                // Trong cùng status, sort theo startDate
                return (s1.startDate ?? Date.distantFuture) > (s2.startDate ?? Date.distantFuture)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sprints")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    SprintListView(project: $project, viewModel: viewModel)
                } label: {
                    Text("See All (\(project.sprints.count))")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            if otherSprints.isEmpty {
                if project.sprints.isEmpty {
                    Text("No sprints yet. Tap + to create one!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    Text("All sprints are active or shown above")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(otherSprints.prefix(2)) { sprint in
                        SprintCompactRow(
                            sprint: sprint,
                            project: $project,
                            viewModel: viewModel,
                            onBoardTap: { selectedTab = 1 }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct SprintCompactRow: View {
    let sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    let onBoardTap: () -> Void

    @State private var showStartConfirmation = false

    private var activeSprint: Sprint? {
        project.sprints.first(where: { $0.status == .active })
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: sprint.status.icon)
                .foregroundStyle(sprint.status.color)
                .frame(width: 24)

            // Sprint info
            VStack(alignment: .leading, spacing: 2) {
                Text(sprint.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(sprint.stories.count) stories • \(sprint.totalStoryPoints) pts")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
            if sprint.status == .planning {
                Button {
                    if activeSprint != nil {
                        showStartConfirmation = true
                    } else {
                        startSprint()
                    }
                } label: {
                    Text("Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(6)
                }
            } else {
                // Status badge for completed
                Text(sprint.status.rawValue)
                    .font(.caption2)
                    .foregroundStyle(sprint.status.color)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .alert("Start New Sprint?", isPresented: $showStartConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Complete & Start", role: .destructive) {
                startSprint()
            }
        } message: {
            if let active = activeSprint {
                Text(
                    "\"\(active.name)\" is currently active.\n\nStarting \"\(sprint.name)\" will mark \"\(active.name)\" as Completed.\n\nProgress: \(active.doneStories.count)/\(active.stories.count) stories done."
                )
            }
        }
    }

    private func startSprint() {
        guard let index = project.sprints.firstIndex(where: { $0.id == sprint.id }) else { return }

        // Deactivate any currently active sprint
        for i in project.sprints.indices {
            if project.sprints[i].status == .active {
                project.sprints[i].status = .completed
            }
        }

        // Activate this sprint
        project.sprints[index].status = .active
        if project.sprints[index].startDate == nil {
            project.sprints[index].startDate = Date()
        }
        if project.sprints[index].endDate == nil {
            let weeks = project.sprintDurationWeeks
            project.sprints[index].endDate = Calendar.current.date(
                byAdding: .weekOfYear, value: weeks, to: Date())
        }

        viewModel.updateProject(project)
    }
}

// MARK: - Preview

#Preview {
    HomeTabView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel(),
        selectedTab: .constant(0)
    )
}
