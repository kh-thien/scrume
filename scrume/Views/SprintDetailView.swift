//
//  SprintDetailView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Màn hình chi tiết Sprint
struct SprintDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showEditSprint = false
    @State private var showAddStories = false
    @State private var showConfirmStart = false
    @State private var showConfirmStartWithActive = false
    @State private var showConfirmComplete = false

    private var activeSprint: Sprint? {
        project.sprints.first(where: { $0.status == .active && $0.id != sprint.id })
    }

    var body: some View {
        List {
            // MARK: - Header Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Status badge
                    HStack {
                        Label(sprint.status.rawValue, systemImage: sprint.status.icon)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(sprint.status.color.opacity(0.2))
                            .foregroundStyle(sprint.status.color)
                            .cornerRadius(8)

                        Spacer()

                        if sprint.status == .active {
                            Text(remainingDaysText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Goal
                    if !sprint.goal.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sprint Goal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(sprint.goal)
                                .font(.subheadline)
                        }
                    }

                    // Dates
                    if let startDate = sprint.startDate {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Start")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(startDate, style: .date)
                                    .font(.caption)
                            }

                            if let endDate = sprint.endDate {
                                VStack(alignment: .leading) {
                                    Text("End")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(endDate, style: .date)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Progress Section
            if sprint.status == .active || sprint.status == .completed {
                Section("Progress") {
                    VStack(spacing: 12) {
                        // Progress bar
                        ProgressView(value: sprint.progressPercentage, total: 100)
                            .tint(progressColor)

                        // Stats
                        HStack {
                            ProgressStatView(
                                value: sprint.completedStoryPoints,
                                total: sprint.totalStoryPoints,
                                label: "Points",
                                color: .blue
                            )

                            Divider()

                            ProgressStatView(
                                value: sprint.doneStories.count,
                                total: sprint.stories.count,
                                label: "Stories",
                                color: .green
                            )

                            Divider()

                            VStack {
                                Text("\(Int(sprint.progressPercentage))%")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(progressColor)
                                Text("Complete")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 8)

                    // Scrum Board Button
                    if sprint.status == .active {
                        NavigationLink {
                            ScrumBoardView(sprint: $sprint, project: $project, viewModel: viewModel)
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.split.3x1")
                                    .foregroundStyle(.blue)
                                Text("Mở Scrum Board")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // MARK: - Stories by Status
            Section {
                // To Do
                DisclosureGroup {
                    if sprint.todoStories.isEmpty {
                        Text("No stories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sprint.todoStories) { story in
                            SprintStoryRowView(story: story, project: project)
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(StoryStatus.todo.color)
                            .frame(width: 10, height: 10)
                        Text("To Do")
                        Spacer()
                        Text("\(sprint.todoStories.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // In Progress
                DisclosureGroup {
                    if sprint.inProgressStories.isEmpty {
                        Text("No stories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sprint.inProgressStories) { story in
                            SprintStoryRowView(story: story, project: project)
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(StoryStatus.inProgress.color)
                            .frame(width: 10, height: 10)
                        Text("In Progress")
                        Spacer()
                        Text("\(sprint.inProgressStories.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // Done
                DisclosureGroup {
                    if sprint.doneStories.isEmpty {
                        Text("No stories")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(sprint.doneStories) { story in
                            SprintStoryRowView(story: story, project: project)
                        }
                    }
                } label: {
                    HStack {
                        Circle()
                            .fill(StoryStatus.done.color)
                            .frame(width: 10, height: 10)
                        Text("Done")
                        Spacer()
                        Text("\(sprint.doneStories.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                HStack {
                    Text("Stories (\(sprint.stories.count))")
                    Spacer()
                    Text("\(sprint.totalStoryPoints) points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Add Stories
            if sprint.status == .planning || sprint.status == .active {
                Section {
                    Button {
                        showAddStories = true
                    } label: {
                        Label("Add Stories from Backlog", systemImage: "plus.circle")
                    }
                }
            }

            // MARK: - Actions Section
            Section("Actions") {
                switch sprint.status {
                case .planning:
                    Button {
                        if activeSprint != nil {
                            showConfirmStartWithActive = true
                        } else {
                            showConfirmStart = true
                        }
                    } label: {
                        Label("Start Sprint", systemImage: "play.fill")
                    }
                    .disabled(sprint.stories.isEmpty)

                case .active:
                    Button {
                        showConfirmComplete = true
                    } label: {
                        Label("Complete Sprint", systemImage: "flag.checkered")
                    }

                case .completed:
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Sprint Completed")
                            .foregroundStyle(.secondary)
                    }

                case .cancelled:
                    HStack {
                        Image(systemName: "xmark.seal.fill")
                            .foregroundStyle(.red)
                        Text("Sprint Cancelled")
                            .foregroundStyle(.secondary)
                    }
                }

                if sprint.status == .planning || sprint.status == .active {
                    Button("Cancel Sprint", role: .destructive) {
                        cancelSprint()
                    }
                }
            }
        }
        .navigationTitle(sprint.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if sprint.status == .planning || sprint.status == .active {
                    Button("Edit") {
                        showEditSprint = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSprint) {
            EditSprintView(sprint: $sprint, project: $project, viewModel: viewModel)
        }
        .sheet(isPresented: $showAddStories) {
            AddStoriesToSprintView(sprint: $sprint, project: $project, viewModel: viewModel)
        }
        .alert("Start Sprint?", isPresented: $showConfirmStart) {
            Button("Cancel", role: .cancel) {}
            Button("Start") { startSprint() }
        } message: {
            Text(
                "Sprint will start with \(sprint.stories.count) stories (\(sprint.totalStoryPoints) points)"
            )
        }
        .alert("Start New Sprint?", isPresented: $showConfirmStartWithActive) {
            Button("Cancel", role: .cancel) {}
            Button("Complete & Start", role: .destructive) {
                completeActiveAndStartThis()
            }
        } message: {
            if let active = activeSprint {
                Text(
                    "\"\(active.name)\" is currently active.\n\nStarting \"\(sprint.name)\" will mark it as Completed.\n\nProgress: \(active.doneStories.count)/\(active.stories.count) stories done."
                )
            }
        }
        .alert("Complete Sprint?", isPresented: $showConfirmComplete) {
            Button("Cancel", role: .cancel) {}
            Button("Complete") { completeSprint() }
        } message: {
            Text(
                "Completed \(sprint.doneStories.count)/\(sprint.stories.count) stories. Incomplete stories will be moved to Backlog."
            )
        }
    }

    // MARK: - Computed Properties

    private var remainingDaysText: String {
        guard let endDate = sprint.endDate else { return "" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        if days < 0 {
            return "Overdue by \(-days) days"
        } else if days == 0 {
            return "Ends today"
        } else {
            return "\(days) days left"
        }
    }

    private var progressColor: Color {
        if sprint.progressPercentage >= 80 {
            return .green
        } else if sprint.progressPercentage >= 50 {
            return .blue
        } else {
            return .orange
        }
    }

    // MARK: - Actions

    private func startSprint() {
        // Deactivate any currently active sprint first (Scrum: only 1 active sprint)
        for index in project.sprints.indices {
            if project.sprints[index].status == .active && project.sprints[index].id != sprint.id {
                project.sprints[index].status = .completed
                project.sprints[index].endDate = Date()
            }
        }
        
        sprint.status = .active
        sprint.startDate = Date()
        sprint.endDate = Calendar.current.date(
            byAdding: .weekOfYear,
            value: project.sprintDurationWeeks,
            to: Date()
        )
        saveSprint()
    }

    private func completeActiveAndStartThis() {
        // Complete the currently active sprint
        if let activeIndex = project.sprints.firstIndex(where: {
            $0.status == .active && $0.id != sprint.id
        }) {
            project.sprints[activeIndex].status = .completed

            // Move incomplete stories back to backlog
            let incompleteStories = project.sprints[activeIndex].stories.filter {
                $0.status != .done
            }
            for var story in incompleteStories {
                story.sprintId = nil
                story.status = .todo
                project.backlog.append(story)
            }
            project.sprints[activeIndex].stories = project.sprints[activeIndex].stories.filter {
                $0.status == .done
            }
        }

        // Now start this sprint
        startSprint()
    }

    private func completeSprint() {
        sprint.status = .completed

        // Move incomplete stories back to backlog
        let incompleteStories = sprint.stories.filter { $0.status != .done }
        for var story in incompleteStories {
            story.sprintId = nil
            story.status = .todo
            project.backlog.append(story)
        }

        // Keep only completed stories in sprint
        sprint.stories = sprint.stories.filter { $0.status == .done }

        saveSprint()
    }

    private func cancelSprint() {
        sprint.status = .cancelled

        // Move all stories back to backlog
        for var story in sprint.stories {
            story.sprintId = nil
            story.status = .todo
            project.backlog.append(story)
        }
        sprint.stories = []

        saveSprint()
    }

    private func saveSprint() {
        if let index = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
            project.sprints[index] = sprint
        }
        viewModel.updateProject(project)
    }
}

// MARK: - Progress Stat View

struct ProgressStatView: View {
    let value: Int
    let total: Int
    let label: String
    let color: Color

    var body: some View {
        VStack {
            HStack(spacing: 2) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                Text("/\(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sprint Story Row

struct SprintStoryRowView: View {
    let story: UserStory
    let project: Project

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(story.priority.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(story.title)
                    .font(.subheadline)
                    .lineLimit(1)

                if !story.assigneeIds.isEmpty {
                    let assignees = project.members.filter { story.assigneeIds.contains($0.id) }
                    Text(
                        assignees.map { $0.name.components(separatedBy: " ").first ?? "" }.joined(
                            separator: ", ")
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }

            Spacer()

            Text("\(story.storyPoints)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SprintDetailView(
            sprint: .constant(Sprint.sample),
            project: .constant(Project.sample),
            viewModel: ProjectViewModel()
        )
    }
}
