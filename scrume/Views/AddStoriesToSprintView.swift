//
//  AddStoriesToSprintView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Screen to select stories from backlog to add to Sprint
struct AddStoriesToSprintView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var selectedStories: Set<UUID> = []
    @State private var sortBy: SortOption = .priority

    enum SortOption: String, CaseIterable {
        case priority = "Priority"
        case points = "Points"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(selectedStories.count) stories")
                                .font(.headline)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Total Points")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(selectedPoints)")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                    }

                    // Current sprint capacity
                    HStack {
                        Text("Current sprint:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(sprint.totalStoryPoints) points")
                            .font(.caption)
                            .fontWeight(.medium)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("\(sprint.totalStoryPoints + selectedPoints) points")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // Stories list
                if project.backlog.isEmpty {
                    ContentUnavailableView(
                        "Empty Backlog",
                        systemImage: "doc.text.below.ecg",
                        description: Text("Add stories to backlog first")
                    )
                } else {
                    List {
                        Section {
                            Picker("Sort", selection: $sortBy) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Section("Backlog (\(project.backlog.count) stories)") {
                            ForEach(sortedBacklog) { story in
                                SelectableStoryRow(
                                    story: story,
                                    isSelected: selectedStories.contains(story.id)
                                ) {
                                    toggleSelection(story.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedStories.count))") {
                        addSelectedStories()
                    }
                    .disabled(selectedStories.isEmpty)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedBacklog: [UserStory] {
        switch sortBy {
        case .priority:
            return project.backlog.sorted { $0.priority > $1.priority }
        case .points:
            return project.backlog.sorted { $0.storyPoints > $1.storyPoints }
        }
    }

    private var selectedPoints: Int {
        project.backlog
            .filter { selectedStories.contains($0.id) }
            .reduce(0) { $0 + $1.storyPoints }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedStories.contains(id) {
            selectedStories.remove(id)
        } else {
            selectedStories.insert(id)
        }
    }

    private func addSelectedStories() {
        // Move selected stories from backlog to sprint
        for storyId in selectedStories {
            if let index = project.backlog.firstIndex(where: { $0.id == storyId }) {
                var story = project.backlog.remove(at: index)
                story.sprintId = sprint.id
                sprint.stories.append(story)
            }
        }

        // Update sprint in project
        if let sprintIndex = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
            project.sprints[sprintIndex] = sprint
        }

        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Selectable Story Row

struct SelectableStoryRow: View {
    let story: UserStory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .font(.title2)

                // Priority indicator
                Circle()
                    .fill(story.priority.color)
                    .frame(width: 8, height: 8)

                // Story info
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Label(story.priority.name, systemImage: story.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(story.priority.color)

                        if !story.tags.isEmpty {
                            Text(story.tags.prefix(2).joined(separator: ", "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Points
                Text("\(story.storyPoints)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .frame(width: 30, height: 30)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    AddStoriesToSprintView(
        sprint: .constant(Sprint.sample),
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
