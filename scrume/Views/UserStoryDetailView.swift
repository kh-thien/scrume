//
//  UserStoryDetailView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Màn hình chi tiết User Story
struct UserStoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var story: UserStory
    @Binding var project: Project
    @ObservedObject var viewModel: ProjectViewModel

    @State private var showEditStory = false
    @State private var newCriterion = ""

    var body: some View {
        List {
            // MARK: - Header Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Priority & Status badges
                    HStack(spacing: 8) {
                        Label(story.priority.name, systemImage: story.priority.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(story.priority.color.opacity(0.2))
                            .foregroundStyle(story.priority.color)
                            .cornerRadius(6)

                        Label(story.status.rawValue, systemImage: story.status.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(story.status.color.opacity(0.2))
                            .foregroundStyle(story.status.color)
                            .cornerRadius(6)

                        Spacer()

                        // Story Points
                        Text("\(story.storyPoints) pts")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                    // Description
                    if !story.description.isEmpty {
                        Text(story.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    // Tags
                    if !story.tags.isEmpty {
                        TagsView(tags: story.tags)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Status Section
            Section("Status") {
                ForEach(StoryStatus.allCases) { status in
                    Button {
                        updateStatus(to: status)
                    } label: {
                        HStack {
                            Label(status.rawValue, systemImage: status.icon)
                                .foregroundStyle(status.color)

                            Spacer()

                            if story.status == status {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            // MARK: - Assignees Section
            Section("Assignees") {
                // Current assignees
                let assignees = project.members.filter { story.assigneeIds.contains($0.id) }
                ForEach(assignees) { member in
                    HStack {
                        TeamMemberRowView(member: member)

                        Spacer()

                        Button {
                            story.assigneeIds.removeAll { $0 == member.id }
                            saveStory()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Add more assignees
                let availableMembers = project.members.filter { !story.assigneeIds.contains($0.id) }
                if !availableMembers.isEmpty {
                    Menu {
                        ForEach(availableMembers) { member in
                            Button {
                                story.assigneeIds.append(member.id)
                                saveStory()
                            } label: {
                                Label(member.name, systemImage: member.role.icon)
                            }
                        }
                    } label: {
                        Label("Add Assignee...", systemImage: "person.badge.plus")
                    }
                }
            }

            // MARK: - Acceptance Criteria Section
            Section {
                ForEach($story.acceptanceCriteria) { $criterion in
                    AcceptanceCriterionRow(criterion: $criterion) {
                        saveStory()
                    }
                }
                .onDelete(perform: deleteCriterion)

                // Add new criterion
                HStack {
                    TextField("Add criterion...", text: $newCriterion)

                    Button {
                        addCriterion()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newCriterion.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                HStack {
                    Text("Acceptance Criteria")
                    Spacer()
                    if !story.acceptanceCriteria.isEmpty {
                        Text("\(story.completedCriteriaCount)/\(story.acceptanceCriteria.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                if !story.acceptanceCriteria.isEmpty {
                    ProgressView(value: story.criteriaProgress)
                        .tint(.green)
                }
            }

            // MARK: - Info Section
            Section("Info") {
                LabeledContent(
                    "Created",
                    value: story.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent(
                    "Updated",
                    value: story.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }

            // MARK: - Actions
            Section {
                Button("Delete Story", role: .destructive) {
                    deleteStory()
                }
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showEditStory = true
                }
            }
        }
        .sheet(isPresented: $showEditStory) {
            EditUserStoryView(story: $story, project: $project, viewModel: viewModel)
        }
    }

    // MARK: - Actions

    private func updateStatus(to status: StoryStatus) {
        story.status = status
        story.updatedAt = Date()
        saveStory()
    }

    private func addCriterion() {
        let criterion = AcceptanceCriterion(
            description: newCriterion.trimmingCharacters(in: .whitespaces))
        story.acceptanceCriteria.append(criterion)
        newCriterion = ""
        saveStory()
    }

    private func deleteCriterion(at offsets: IndexSet) {
        story.acceptanceCriteria.remove(atOffsets: offsets)
        saveStory()
    }

    private func saveStory() {
        story.updatedAt = Date()

        // Update in backlog or sprint
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
    }

    private func deleteStory() {
        // Remove from backlog
        if let index = project.backlog.firstIndex(where: { $0.id == story.id }) {
            project.backlog.remove(at: index)
        }

        // Remove from sprints
        for sprintIndex in project.sprints.indices {
            if let storyIndex = project.sprints[sprintIndex].stories.firstIndex(where: {
                $0.id == story.id
            }) {
                project.sprints[sprintIndex].stories.remove(at: storyIndex)
                break
            }
        }

        viewModel.updateProject(project)
        dismiss()
    }
}

// MARK: - Acceptance Criterion Row

struct AcceptanceCriterionRow: View {
    @Binding var criterion: AcceptanceCriterion
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                criterion.isCompleted.toggle()
                onToggle()
            } label: {
                Image(systemName: criterion.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(criterion.isCompleted ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            Text(criterion.description)
                .strikethrough(criterion.isCompleted)
                .foregroundStyle(criterion.isCompleted ? .secondary : .primary)
        }
    }
}

// MARK: - Tags View

struct TagsView: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y),
                proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (
        size: CGSize, positions: [CGPoint]
    ) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserStoryDetailView(
            story: .constant(UserStory.sprintSamples[0]),
            project: .constant(Project.sample),
            viewModel: ProjectViewModel()
        )
    }
}
