//
//  SprintListView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Màn hình danh sách tất cả Sprints
struct SprintListView: View {
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showCreateSprint = false
    @State private var filterStatus: SprintStatus?

    var body: some View {
        List {
            // Active Sprint (highlighted)
            if let activeSprint = project.activeSprint,
                let index = project.sprints.firstIndex(where: { $0.id == activeSprint.id })
            {
                Section {
                    NavigationLink {
                        SprintDetailView(
                            sprint: bindingForSprint(at: index),
                            project: $project,
                            viewModel: viewModel
                        )
                    } label: {
                        ActiveSprintCardView(sprint: activeSprint)
                    }
                } header: {
                    Label("Active Sprint", systemImage: "play.circle.fill")
                        .foregroundStyle(.blue)
                }
            }

            // All Sprints
            Section {
                if filteredSprints.isEmpty {
                    ContentUnavailableView(
                        "No Sprints",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text("Create your first Sprint to get started")
                    )
                } else {
                    ForEach(filteredSprints.indices, id: \.self) { filteredIndex in
                        let sprint = filteredSprints[filteredIndex]
                        if let originalIndex = project.sprints.firstIndex(where: {
                            $0.id == sprint.id
                        }) {
                            NavigationLink {
                                SprintDetailView(
                                    sprint: bindingForSprint(at: originalIndex),
                                    project: $project,
                                    viewModel: viewModel
                                )
                            } label: {
                                SprintListRowView(sprint: sprint)
                            }
                        }
                    }
                    .onDelete(perform: deleteSprints)
                }
            } header: {
                HStack {
                    Text("All Sprints (\(filteredSprints.count))")
                    Spacer()
                    Text("\(totalPoints) points")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Sprints")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSprint = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button("All") { filterStatus = nil }
                    Divider()
                    ForEach(SprintStatus.allCases) { status in
                        Button {
                            filterStatus = status
                        } label: {
                            Label(status.rawValue, systemImage: status.icon)
                        }
                    }
                } label: {
                    Label(
                        "Filter",
                        systemImage: filterStatus == nil
                            ? "line.3.horizontal.decrease.circle"
                            : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showCreateSprint) {
            CreateSprintView(project: $project, viewModel: viewModel)
        }
    }

    // MARK: - Computed Properties

    private var filteredSprints: [Sprint] {
        if let status = filterStatus {
            return project.sprints.filter { $0.status == status }
        }
        return project.sprints.sorted { s1, s2 in
            // Active first, then planning, then completed, then cancelled
            let order: [SprintStatus: Int] = [
                .active: 0, .planning: 1, .completed: 2, .cancelled: 3,
            ]
            return (order[s1.status] ?? 4) < (order[s2.status] ?? 4)
        }
    }

    private var totalPoints: Int {
        filteredSprints.reduce(0) { $0 + $1.totalStoryPoints }
    }

    private func bindingForSprint(at index: Int) -> Binding<Sprint> {
        Binding(
            get: { project.sprints[index] },
            set: { project.sprints[index] = $0 }
        )
    }

    // MARK: - Actions

    private func deleteSprints(at offsets: IndexSet) {
        let sprintsToDelete = offsets.map { filteredSprints[$0] }

        for sprint in sprintsToDelete {
            // Only allow deleting planning sprints
            guard sprint.status == .planning else { continue }

            // Move stories back to backlog
            for var story in sprint.stories {
                story.sprintId = nil
                project.backlog.append(story)
            }

            project.sprints.removeAll { $0.id == sprint.id }
        }

        viewModel.updateProject(project)
    }
}

// MARK: - Active Sprint Card

struct ActiveSprintCardView: View {
    let sprint: Sprint

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(sprint.name)
                    .font(.headline)

                Spacer()

                if let endDate = sprint.endDate {
                    let days =
                        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                    Text(days >= 0 ? "\(days)d left" : "Overdue")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(days >= 0 ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                        .foregroundStyle(days >= 0 ? .blue : .red)
                        .cornerRadius(6)
                }
            }

            if !sprint.goal.isEmpty {
                Text(sprint.goal)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Progress
            VStack(spacing: 6) {
                ProgressView(value: sprint.progressPercentage, total: 100)
                    .tint(.blue)

                HStack {
                    Text("\(sprint.completedStoryPoints)/\(sprint.totalStoryPoints) points")
                    Spacer()
                    Text("\(Int(sprint.progressPercentage))%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Story counts
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(StoryStatus.todo.color).frame(width: 8, height: 8)
                    Text("\(sprint.todoStories.count)")
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Circle().fill(StoryStatus.inProgress.color).frame(width: 8, height: 8)
                    Text("\(sprint.inProgressStories.count)")
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Circle().fill(StoryStatus.done.color).frame(width: 8, height: 8)
                    Text("\(sprint.doneStories.count)")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sprint List Row

struct SprintListRowView: View {
    let sprint: Sprint

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sprint.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Label(sprint.status.rawValue, systemImage: sprint.status.icon)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(sprint.status.color.opacity(0.15))
                    .foregroundStyle(sprint.status.color)
                    .cornerRadius(4)
            }

            HStack(spacing: 12) {
                Label("\(sprint.stories.count) stories", systemImage: "doc.text")
                Label("\(sprint.totalStoryPoints) pts", systemImage: "number")

                if sprint.status == .completed {
                    Label("\(Int(sprint.progressPercentage))%", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SprintListView(
            project: .constant(Project.sample),
            viewModel: ProjectViewModel()
        )
    }
}
