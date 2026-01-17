//
//  EditSprintView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Form chỉnh sửa Sprint
struct EditSprintView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sprint: Sprint
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var name = ""
    @State private var goal = ""
    @State private var startDate: Date = Date()
    @State private var hasCustomDates = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Sprint Info") {
                    TextField("Sprint Name", text: $name)

                    TextField("Sprint Goal", text: $goal, axis: .vertical)
                        .lineLimit(2...4)
                }

                if sprint.status == .planning {
                    Section("Schedule") {
                        Toggle("Custom Dates", isOn: $hasCustomDates)

                        if hasCustomDates {
                            DatePicker(
                                "Start Date", selection: $startDate, displayedComponents: .date)

                            HStack {
                                Text("End Date")
                                Spacer()
                                Text(endDate, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(project.sprintDurationWeeks) week\(project.sprintDurationWeeks > 1 ? "s" : "")")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Stories summary
                Section("Stories") {
                    HStack {
                        Text("Count")
                        Spacer()
                        Text("\(sprint.stories.count) stories")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Points")
                        Spacer()
                        Text("\(sprint.totalStoryPoints)")
                            .foregroundStyle(.blue)
                    }
                }

                // Delete section
                if sprint.status == .planning {
                    Section {
                        Button("Delete Sprint", role: .destructive) {
                            deleteSprint()
                        }
                    }
                }
            }
            .navigationTitle("Edit Sprint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = sprint.name
                goal = sprint.goal
                if let start = sprint.startDate {
                    startDate = start
                    hasCustomDates = true
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var endDate: Date {
        Calendar.current.date(
            byAdding: .weekOfYear,
            value: project.sprintDurationWeeks,
            to: startDate
        ) ?? startDate
    }

    // MARK: - Actions

    private func saveChanges() {
        sprint.name = name.trimmingCharacters(in: .whitespaces)
        sprint.goal = goal

        if hasCustomDates && sprint.status == .planning {
            sprint.startDate = startDate
            sprint.endDate = endDate
        }

        if let index = project.sprints.firstIndex(where: { $0.id == sprint.id }) {
            project.sprints[index] = sprint
        }

        viewModel.updateProject(project)
        dismiss()
    }

    private func deleteSprint() {
        // Move stories back to backlog
        for var story in sprint.stories {
            story.sprintId = nil
            project.backlog.append(story)
        }

        // Remove sprint
        project.sprints.removeAll { $0.id == sprint.id }

        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditSprintView(
        sprint: .constant(Sprint.sample),
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
