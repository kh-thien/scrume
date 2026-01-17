//
//  CreateSprintView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Form to create new Sprint
struct CreateSprintView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var name = ""
    @State private var goal = ""
    @State private var startNow = false
    @State private var showActiveSprintWarning = false

    // Check if there's an active sprint
    private var currentActiveSprint: Sprint? {
        project.sprints.first { $0.status == .active }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sprint Info") {
                    TextField("Sprint Name", text: $name)
                        .onAppear {
                            name = "Sprint \(project.sprints.count + 1)"
                        }

                    TextField("Sprint Goal", text: $goal, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("Start Now", isOn: $startNow)

                    if startNow {
                        // Warning if there's an active sprint
                        if let activeSprint = currentActiveSprint {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("\"\(activeSprint.name)\" will be completed")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }

                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(
                                "\(project.sprintDurationWeeks) week\(project.sprintDurationWeeks > 1 ? "s" : "")"
                            )
                            .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("End Date")
                            Spacer()
                            Text(endDate, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    if startNow {
                        if currentActiveSprint != nil {
                            Text(
                                "⚠️ Starting this sprint will automatically complete the current active sprint."
                            )
                        } else {
                            Text(
                                "Sprint will end after \(project.sprintDurationWeeks) week\(project.sprintDurationWeeks > 1 ? "s" : "")"
                            )
                        }
                    }
                }

                // Select stories from backlog
                if !project.backlog.isEmpty {
                    Section {
                        NavigationLink {
                            SelectStoriesView(project: $project, selectedStories: $selectedStories)
                        } label: {
                            HStack {
                                Text("Select User Stories")
                                Spacer()
                                Text("\(selectedStories.count) selected")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("User Stories")
                    } footer: {
                        Text("Select stories from backlog to add to this sprint")
                    }
                }
            }
            .navigationTitle("New Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if startNow && currentActiveSprint != nil {
                            showActiveSprintWarning = true
                        } else {
                            createSprint()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Complete Active Sprint?", isPresented: $showActiveSprintWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Complete & Start", role: .destructive) {
                    createSprint()
                }
            } message: {
                if let activeSprint = currentActiveSprint {
                    Text(
                        "\"\(activeSprint.name)\" is currently active with \(activeSprint.stories.count) stories (\(activeSprint.doneStories.count) done).\n\nStarting \"\(name)\" will mark it as Completed."
                    )
                }
            }
        }
    }

    // MARK: - State

    @State private var selectedStories: Set<UUID> = []

    // MARK: - Computed Properties

    private var endDate: Date {
        Calendar.current.date(
            byAdding: .weekOfYear,
            value: project.sprintDurationWeeks,
            to: Date()
        ) ?? Date()
    }

    // MARK: - Actions

    private func createSprint() {
        var sprint = Sprint(
            name: name.trimmingCharacters(in: .whitespaces),
            goal: goal,
            status: startNow ? .active : .planning
        )

        if startNow {
            sprint.startDate = Date()
            sprint.endDate = endDate

            // Deactivate any currently active sprint (Scrum: only 1 active sprint at a time)
            for index in project.sprints.indices {
                if project.sprints[index].status == .active {
                    project.sprints[index].status = .completed
                    project.sprints[index].endDate = Date()
                }
            }
        }

        // Move selected stories from backlog to sprint
        var storiesToAdd: [UserStory] = []
        for storyId in selectedStories {
            if let index = project.backlog.firstIndex(where: { $0.id == storyId }) {
                var story = project.backlog.remove(at: index)
                story.sprintId = sprint.id
                storiesToAdd.append(story)
            }
        }
        sprint.stories = storiesToAdd

        project.sprints.append(sprint)
        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Select Stories View

struct SelectStoriesView: View {
    @Binding var project: Project
    @Binding var selectedStories: Set<UUID>

    var body: some View {
        List {
            ForEach(project.backlog) { story in
                HStack {
                    UserStoryRowView(story: story)

                    Spacer()

                    Image(
                        systemName: selectedStories.contains(story.id)
                            ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundStyle(selectedStories.contains(story.id) ? .blue : .gray)
                    .font(.title2)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedStories.contains(story.id) {
                        selectedStories.remove(story.id)
                    } else {
                        selectedStories.insert(story.id)
                    }
                }
            }
        }
        .navigationTitle("Select Stories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Text("\(selectedPoints) points")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectedPoints: Int {
        project.backlog
            .filter { selectedStories.contains($0.id) }
            .reduce(0) { $0 + $1.storyPoints }
    }
}

// MARK: - Preview

#Preview {
    CreateSprintView(
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
