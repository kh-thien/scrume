//
//  EditUserStoryView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Form chỉnh sửa User Story
struct EditUserStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var story: UserStory
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: Priority = .medium
    @State private var storyPoints: Int = 3
    @State private var tags: [String] = []
    @State private var newTag: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("User Story") {
                    TextField("Title", text: $title)

                    TextField(
                        "Description (As a..., I want..., so that...)", text: $description,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { p in
                            Label(p.name, systemImage: p.icon)
                                .foregroundStyle(p.color)
                                .tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Story Points") {
                    Picker("Points", selection: $storyPoints) {
                        ForEach(UserStory.validPoints, id: \.self) { point in
                            Text("\(point)").tag(point)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Tags") {
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                Button {
                                    removeTag(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .cornerRadius(4)
                        }
                    }

                    HStack {
                        TextField("New tag", text: $newTag)
                            .textInputAutocapitalization(.never)

                        Button {
                            addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = story.title
                description = story.description
                priority = story.priority
                storyPoints = story.storyPoints
                tags = story.tags
            }
        }
    }

    // MARK: - Actions

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
            newTag = ""
        }
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func saveChanges() {
        story.title = title.trimmingCharacters(in: .whitespaces)
        story.description = description
        story.priority = priority
        story.storyPoints = storyPoints
        story.tags = tags
        story.updatedAt = Date()

        // Update in project
        if let backlogIndex = project.backlog.firstIndex(where: { $0.id == story.id }) {
            project.backlog[backlogIndex] = story
        } else {
            for sprintIndex in project.sprints.indices {
                if let storyIndex = project.sprints[sprintIndex].stories.firstIndex(where: {
                    $0.id == story.id
                }) {
                    project.sprints[sprintIndex].stories[storyIndex] = story
                    break
                }
            }
        }

        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    EditUserStoryView(
        story: .constant(UserStory.sprintSamples[0]),
        project: .constant(Project.sample),
        viewModel: ProjectViewModel()
    )
}
